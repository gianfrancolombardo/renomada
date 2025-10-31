-- Migration: Add condition and exchange_type fields to items table
-- Description: Adds physical condition of item and exchange intent (gift or trade)
-- Date: 2025-10-11

-- Add condition field (physical state of the item)
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS condition text NOT NULL DEFAULT 'used' 
CHECK (condition IN ('like_new', 'used', 'needs_repair'));

-- Add exchange_type field (intent: gift or trade)
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS exchange_type text NOT NULL DEFAULT 'exchange' 
CHECK (exchange_type IN ('gift', 'exchange'));

-- Add helpful comments
COMMENT ON COLUMN public.items.condition IS 'Physical condition: like_new (como nuevo), used (usado), needs_repair (para reparar)';
COMMENT ON COLUMN public.items.exchange_type IS 'Exchange intent: gift (regalar), exchange (intercambiar)';

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS items_condition_idx ON public.items(condition);
CREATE INDEX IF NOT EXISTS items_exchange_type_idx ON public.items(exchange_type);

-- Update the feed_items_by_radius function to include new fields
DROP FUNCTION IF EXISTS public.feed_items_by_radius(uuid, float, integer, integer);

CREATE OR REPLACE FUNCTION public.feed_items_by_radius(
  p_user_id uuid,
  p_radius_km float default 10.0,
  p_page_offset integer default 0,
  p_page_limit integer default 20
)
RETURNS TABLE(
  -- Item fields
  item_id uuid,
  item_title text,
  item_description text,
  item_status text,
  item_condition text,
  item_exchange_type text,
  item_created_at timestamptz,
  item_updated_at timestamptz,
  
  -- Owner fields
  owner_id uuid,
  owner_username text,
  owner_avatar_url text,
  owner_last_seen_at timestamptz,
  
  -- Distance and photo
  distance_km float,
  first_photo_path text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_lat float;
  user_lng float;
  user_location geometry;
BEGIN
  -- Get current user coordinates
  SELECT st_y(last_location::geometry), st_x(last_location::geometry), last_location::geometry
  INTO user_lat, user_lng, user_location
  FROM profiles
  WHERE user_id = p_user_id;
  
  -- If no location, return empty
  IF user_lat IS NULL OR user_lng IS NULL OR user_location IS NULL THEN
    RAISE NOTICE 'User % has no location data', p_user_id;
    RETURN;
  END IF;
  
  -- Return items from nearby users
  RETURN QUERY
  WITH nearby_users AS (
    SELECT 
      p.user_id,
      p.username,
      p.avatar_url,
      p.last_seen_at,
      st_distance(
        p.last_location::geography,
        user_location::geography
      ) / 1000.0 AS distance_km
    FROM profiles p
    WHERE p.last_location IS NOT NULL
      AND p.user_id != p_user_id
      AND st_dwithin(
        p.last_location::geography,
        user_location::geography,
        p_radius_km * 1000
      )
      AND p.last_seen_at > now() - interval '7 days'
    ORDER BY distance_km ASC
    LIMIT 50
  ),
  user_items AS (
    SELECT 
      i.id AS item_id,
      i.title AS item_title,
      i.description AS item_description,
      i.status::text AS item_status,
      i.condition AS item_condition,
      i.exchange_type AS item_exchange_type,
      i.created_at AS item_created_at,
      i.updated_at AS item_updated_at,
      i.owner_id AS owner_id,
      nu.username AS owner_username,
      nu.avatar_url AS owner_avatar_url,
      nu.last_seen_at AS owner_last_seen_at,
      nu.distance_km,
      (
        SELECT ip.path 
        FROM item_photos ip 
        WHERE ip.item_id = i.id 
        ORDER BY ip.created_at ASC 
        LIMIT 1
      ) AS first_photo_path
    FROM items i
    JOIN nearby_users nu ON i.owner_id = nu.user_id
    WHERE i.status = 'available'
      AND i.id NOT IN (
        SELECT interactions.item_id 
        FROM interactions 
        WHERE interactions.user_id = p_user_id 
          AND interactions.action = 'pass'
      )
    ORDER BY nu.distance_km ASC, i.created_at DESC
    LIMIT p_page_limit OFFSET p_page_offset
  )
  SELECT 
    ui.item_id,
    ui.item_title,
    ui.item_description,
    ui.item_status,
    ui.item_condition,
    ui.item_exchange_type,
    ui.item_created_at,
    ui.item_updated_at,
    ui.owner_id,
    ui.owner_username,
    ui.owner_avatar_url,
    ui.owner_last_seen_at,
    ui.distance_km,
    ui.first_photo_path
  FROM user_items ui;
END;
$$;

-- Grant execute permissions
REVOKE ALL ON FUNCTION public.feed_items_by_radius(uuid, float, integer, integer) FROM public;
GRANT EXECUTE ON FUNCTION public.feed_items_by_radius(uuid, float, integer, integer) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.feed_items_by_radius IS 'Obtiene items del feed filtrados por radio de distancia desde la ubicación del usuario (incluye condition y exchange_type)';


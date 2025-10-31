-- Migration: Optimize feed loading - Remove last_seen_at filter and improve pagination
-- This allows items to be shown even if user location is stale

-- Drop and recreate the function without last_seen_at filter
DROP FUNCTION IF EXISTS public.feed_items_by_radius(uuid, float, integer, integer);

-- Create optimized version
CREATE OR REPLACE FUNCTION public.feed_items_by_radius(
  p_user_id uuid,
  p_radius_km float default 10.0,
  p_page_offset integer default 0,
  p_page_limit integer default 10  -- ✨ Changed: Default 10 instead of 20
)
RETURNS TABLE(
  -- Item fields
  item_id uuid,
  item_title text,
  item_description text,
  item_status text,
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
      ) / 1000.0 as distance_km
    FROM profiles p
    WHERE p.last_location is not null
      and p.user_id != p_user_id
      and st_dwithin(
        p.last_location::geography,
        user_location::geography,
        p_radius_km * 1000
      )
      -- ✨ REMOVED: and p.last_seen_at > now() - interval '7 days'
      -- This allows items to show even if user location is stale
    order by distance_km asc
    limit 50  -- Keep limit on users to prevent too many items
  ),
  user_items as (
    select 
      i.id as item_id,
      i.title as item_title,
      i.description as item_description,
      i.status::text as item_status,
      i.created_at as item_created_at,
      i.updated_at as item_updated_at,
      i.owner_id as owner_id,
      nu.username as owner_username,
      nu.avatar_url as owner_avatar_url,
      nu.last_seen_at as owner_last_seen_at,
      nu.distance_km,
      (
        select ip.path 
        from item_photos ip 
        where ip.item_id = i.id 
        order by ip.created_at asc 
        limit 1
      ) as first_photo_path
    from items i
    join nearby_users nu on i.owner_id = nu.user_id
    where i.status = 'available'
      and i.id not in (
        select interactions.item_id 
        from interactions 
        where interactions.user_id = p_user_id 
          and interactions.action = 'pass'
      )
    order by nu.distance_km asc, i.created_at desc
    limit p_page_limit offset p_page_offset
  )
  select 
    ui.item_id,
    ui.item_title,
    ui.item_description,
    ui.item_status,
    ui.item_created_at,
    ui.item_updated_at,
    ui.owner_id,
    ui.owner_username,
    ui.owner_avatar_url,
    ui.owner_last_seen_at,
    ui.distance_km,
    ui.first_photo_path
  from user_items ui;
END;
$$;

-- Grant execute permissions
REVOKE ALL ON FUNCTION public.feed_items_by_radius(uuid, float, integer, integer) FROM public;
GRANT EXECUTE ON FUNCTION public.feed_items_by_radius(uuid, float, integer, integer) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.feed_items_by_radius IS 
'Obtiene items del feed filtrados por radio de distancia. Removed last_seen_at filter to show items even with stale location. Default limit 10 items.';


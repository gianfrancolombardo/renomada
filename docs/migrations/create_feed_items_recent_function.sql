-- Create function to get recent items without location filter
-- This allows users without location to see recent items (max 10, no pagination)
-- Structure matches feed_items_by_radius for compatibility
CREATE OR REPLACE FUNCTION feed_items_recent(
  p_user_id UUID
)
RETURNS TABLE (
  -- Item fields (matching feed_items_by_radius structure)
  item_id UUID,
  item_title TEXT,
  item_description TEXT,
  item_status TEXT,
  item_condition TEXT,
  item_exchange_type TEXT,
  item_created_at TIMESTAMPTZ,
  item_updated_at TIMESTAMPTZ,
  
  -- Owner fields
  owner_id UUID,
  owner_username TEXT,
  owner_avatar_url TEXT,
  owner_last_seen_at TIMESTAMPTZ,
  
  -- Distance and photo (distance_km is 0.0 for recent items)
  distance_km FLOAT,
  first_photo_path TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id as item_id,
    i.title as item_title,
    i.description as item_description,
    i.status::TEXT as item_status,
    i.condition::TEXT as item_condition,
    i.exchange_type::TEXT as item_exchange_type,
    i.created_at as item_created_at,
    i.updated_at as item_updated_at,
    p.user_id as owner_id,
    p.username as owner_username,
    p.avatar_url as owner_avatar_url,
    p.last_seen_at as owner_last_seen_at,
    NULL::FLOAT as distance_km, -- NULL indicates no distance (recent items without location)
    (SELECT ip.path 
     FROM item_photos ip 
     WHERE ip.item_id = i.id 
     ORDER BY ip.created_at ASC 
     LIMIT 1) as first_photo_path
  FROM items i
  JOIN profiles p ON i.owner_id = p.user_id
  WHERE i.status = 'available'
    AND p.is_location_opt_out = false
    AND i.owner_id != p_user_id -- Exclude own items
    -- Exclude items with interactions (pass or like)
    AND i.id NOT IN (
      SELECT interactions.item_id 
      FROM interactions 
      WHERE interactions.user_id = p_user_id 
        AND interactions.action IN ('pass', 'like')
    )
  ORDER BY i.created_at DESC
  LIMIT 10; -- Fixed limit: maximum 10 items, no pagination
END;
$$;

-- Grant execute permissions
REVOKE ALL ON FUNCTION public.feed_items_recent(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.feed_items_recent(uuid) TO authenticated;

-- Add comment
COMMENT ON FUNCTION feed_items_recent IS 'Returns recent items without location filter. Used when user has not granted location permission. Maximum 10 items (no pagination). Structure matches feed_items_by_radius for compatibility.';


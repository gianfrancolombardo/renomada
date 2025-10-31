-- Migration: Optimize user items loading by adding first_photo_path
-- This eliminates N+1 queries for item photos

-- Create or replace function to get user items with first photo path
CREATE OR REPLACE FUNCTION get_user_items_with_photos(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  owner_id uuid,
  title text,
  description text,
  status text,
  condition text,
  exchange_type text,
  is_active boolean,
  created_at timestamptz,
  updated_at timestamptz,
  first_photo_path text  -- ✨ NEW: Photo path included to avoid N+1 queries
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.owner_id,
    i.title,
    i.description,
    i.status::text,
    i.condition::text,
    i.exchange_type::text,
    i.is_active,
    i.created_at,
    i.updated_at,
    ip.path as first_photo_path  -- ✨ Get first photo path in same query
  FROM items i
  -- ✨ First photo path (eliminates N+1 query)
  LEFT JOIN LATERAL (
    SELECT path
    FROM item_photos
    WHERE item_photos.item_id = i.id
    ORDER BY item_photos.created_at ASC  -- ✨ Fixed: specify table explicitly
    LIMIT 1
  ) ip ON true
  WHERE i.owner_id = p_user_id
    AND i.status IN ('available', 'exchanged')
  ORDER BY 
    CASE WHEN i.status = 'available' THEN 0 ELSE 1 END,  -- Available items first
    i.created_at DESC;  -- Then by creation date
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_items_with_photos(uuid) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_user_items_with_photos(uuid) IS 
'Get user items with first photo path. Optimized to eliminate N+1 queries.';

-- Ensure index exists for performance (already created in chat optimization)
-- CREATE INDEX IF NOT EXISTS idx_item_photos_item_created 
-- ON item_photos (item_id, created_at ASC);


-- Migration Step 2: Add deleted status and remove is_active field (continued)
-- This is Step 2 of the migration. 
-- If using ENUM type, you must run "add_deleted_status_and_remove_is_active_step1.sql" first and commit.
-- If using text column with CHECK constraint, you can skip step 1.

-- Step 2: Update CHECK constraint if status column is text (not ENUM)
-- This only runs if the column is text type, not if it uses the ENUM type
DO $$
DECLARE
  status_type text;
  uses_enum boolean;
BEGIN
  -- Check if ENUM type exists
  SELECT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'item_status') INTO uses_enum;
  
  -- Only update CHECK constraint if NOT using ENUM type
  IF NOT uses_enum THEN
    -- Check the actual data type of the status column
    SELECT data_type INTO status_type
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'items'
      AND column_name = 'status';
    
    -- Only update CHECK constraint if column is text type
    IF status_type = 'text' OR status_type = 'character varying' THEN
      -- Drop old constraint if it exists
      IF EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'items_status_check'
      ) THEN
        ALTER TABLE items DROP CONSTRAINT items_status_check;
      END IF;
      
      -- Add new constraint that includes 'deleted'
      ALTER TABLE items 
      ADD CONSTRAINT items_status_check 
      CHECK (status IN ('available', 'exchanged', 'paused', 'deleted'));
    END IF;
  END IF;
END $$;

-- 3. Update get_user_items_with_photos function to exclude deleted items
DROP FUNCTION IF EXISTS get_user_items_with_photos(uuid);

CREATE OR REPLACE FUNCTION get_user_items_with_photos(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  owner_id uuid,
  title text,
  description text,
  status text,
  condition text,
  exchange_type text,
  created_at timestamptz,
  updated_at timestamptz,
  first_photo_path text
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
    i.created_at,
    i.updated_at,
    ip.path as first_photo_path
  FROM items i
  LEFT JOIN LATERAL (
    SELECT path
    FROM item_photos
    WHERE item_photos.item_id = i.id
    ORDER BY item_photos.created_at ASC
    LIMIT 1
  ) ip ON true
  WHERE i.owner_id = p_user_id
    AND i.status IN ('available', 'exchanged', 'paused')  -- Exclude deleted
  ORDER BY 
    CASE WHEN i.status = 'available' THEN 0 ELSE 1 END,
    i.created_at DESC;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_items_with_photos(uuid) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_user_items_with_photos(uuid) IS 
'Get user items with first photo path. Excludes deleted items. Removed is_active field.';

-- 4. Remove is_active column from items table
ALTER TABLE items DROP COLUMN IF EXISTS is_active;

-- Note: The feed_items_by_radius function already filters by status = 'available', so deleted items won't appear
-- The count query also filters by status = 'available', so deleted items won't be counted


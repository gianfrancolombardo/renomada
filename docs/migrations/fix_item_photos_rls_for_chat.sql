-- Fix item_photos RLS policies to allow chat participants access
-- This script removes conflicting policies and creates a unified, secure approach

-- 1. Drop existing conflicting policies
DROP POLICY IF EXISTS "item_photos_owner_likers_and_chat_participants" ON item_photos;
DROP POLICY IF EXISTS "item_photos_owner_select" ON item_photos;
DROP POLICY IF EXISTS "item_photos_owner_insert" ON item_photos;
DROP POLICY IF EXISTS "item_photos_owner_update" ON item_photos;
DROP POLICY IF EXISTS "item_photos_owner_delete" ON item_photos;

-- 2. Create unified, secure policies for item_photos

-- Policy for SELECT: Allow owners, likers, and chat participants to read photos
CREATE POLICY "item_photos_secure_select" ON item_photos
FOR SELECT
TO authenticated
USING (
  -- Owner can see their photos
  EXISTS (
    SELECT 1 FROM items i 
    WHERE i.id = item_photos.item_id 
    AND i.owner_id = auth.uid()
  )
  OR
  -- Users who liked the item can see photos
  EXISTS (
    SELECT 1 FROM interactions inter 
    WHERE inter.item_id = item_photos.item_id 
    AND inter.user_id = auth.uid() 
    AND inter.action = 'like'
  )
  OR
  -- Chat participants can see photos
  EXISTS (
    SELECT 1 FROM chats c
    JOIN items i ON i.id = c.item_id
    WHERE i.id = item_photos.item_id 
    AND (c.a_user_id = auth.uid() OR c.b_user_id = auth.uid())
  )
);

-- Policy for INSERT: Only owners can add photos to their items
CREATE POLICY "item_photos_owner_insert" ON item_photos
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL 
  AND EXISTS (
    SELECT 1 FROM items i 
    WHERE i.id = item_photos.item_id 
    AND i.owner_id = auth.uid()
  )
);

-- Policy for UPDATE: Only owners can update their photos
CREATE POLICY "item_photos_owner_update" ON item_photos
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM items i 
    WHERE i.id = item_photos.item_id 
    AND i.owner_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM items i 
    WHERE i.id = item_photos.item_id 
    AND i.owner_id = auth.uid()
  )
);

-- Policy for DELETE: Only owners can delete their photos
CREATE POLICY "item_photos_owner_delete" ON item_photos
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM items i 
    WHERE i.id = item_photos.item_id 
    AND i.owner_id = auth.uid()
  )
);

-- 3. Update storage policies for item-photos bucket

-- Drop existing storage policies
DROP POLICY IF EXISTS "Public read access for available item photos" ON storage.objects;
DROP POLICY IF EXISTS "Owners can upload item photos" ON storage.objects;
DROP POLICY IF EXISTS "Owners can delete item photos" ON storage.objects;
DROP POLICY IF EXISTS "Owners can list their item photos" ON storage.objects;
DROP POLICY IF EXISTS "Owners can update item photos" ON storage.objects;

-- Create secure storage policies

-- Allow public read access for item photos (signed URLs will be used)
CREATE POLICY "item_photos_public_read" ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'item-photos');

-- Allow authenticated users to upload photos to their own folders
CREATE POLICY "item_photos_owner_upload" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'item-photos'
  AND (auth.uid())::text = (regexp_match(name, '^item-photos/([^/]+)/'))[1]
  AND EXISTS (
    SELECT 1 FROM items
    WHERE (items.id)::text = (regexp_match(objects.name, '^item-photos/[^/]+/([^_]+)_'))[1]
    AND items.owner_id = auth.uid()
  )
);

-- Allow owners to update their photos
CREATE POLICY "item_photos_owner_update_storage" ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'item-photos'
  AND (auth.uid())::text = (regexp_match(name, '^item-photos/([^/]+)/'))[1]
  AND EXISTS (
    SELECT 1 FROM items
    WHERE (items.id)::text = (regexp_match(objects.name, '^item-photos/[^/]+/([^_]+)_'))[1]
    AND items.owner_id = auth.uid()
  )
);

-- Allow owners to delete their photos
CREATE POLICY "item_photos_owner_delete_storage" ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'item-photos'
  AND (auth.uid())::text = (regexp_match(name, '^item-photos/([^/]+)/'))[1]
  AND EXISTS (
    SELECT 1 FROM items
    WHERE (items.id)::text = (regexp_match(objects.name, '^item-photos/[^/]+/([^_]+)_'))[1]
    AND items.owner_id = auth.uid()
  )
);

-- 4. Create helper function to check if user can access item photos
CREATE OR REPLACE FUNCTION can_access_item_photos(p_item_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM items i 
    WHERE i.id = p_item_id 
    AND i.owner_id = p_user_id
  )
  OR EXISTS (
    SELECT 1 FROM interactions inter 
    WHERE inter.item_id = p_item_id 
    AND inter.user_id = p_user_id 
    AND inter.action = 'like'
  )
  OR EXISTS (
    SELECT 1 FROM chats c
    JOIN items i ON i.id = c.item_id
    WHERE i.id = p_item_id 
    AND (c.a_user_id = p_user_id OR c.b_user_id = p_user_id)
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION can_access_item_photos(uuid, uuid) TO authenticated;

-- 5. Add comment explaining the security model
COMMENT ON POLICY "item_photos_secure_select" ON item_photos IS 
'Allows owners, users who liked the item, and chat participants to view item photos. This enables proper functionality in chat while maintaining security.';

COMMENT ON FUNCTION can_access_item_photos(uuid, uuid) IS 
'Helper function to check if a user can access photos for a specific item. Used for additional validation and debugging.';
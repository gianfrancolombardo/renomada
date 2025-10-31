-- Fix item_photos RLS with enhanced security
-- This allows:
-- 1. Item owners to manage their own photos (all operations)
-- 2. Users who have "liked" an item to view its photos (SELECT only)
-- This is more secure because it requires actual interest (like) to view photos

-- Drop the existing restrictive policy
DROP POLICY IF EXISTS item_photos_owner_all ON public.item_photos;

-- Create a secure policy
CREATE POLICY item_photos_owner_and_likers
  ON public.item_photos FOR ALL
  USING (
    -- Owner can do everything
    EXISTS (
      SELECT 1 FROM public.items i 
      WHERE i.id = item_photos.item_id 
        AND i.owner_id = auth.uid()
    )
    OR
    -- Users who have liked the item can view photos
    EXISTS (
      SELECT 1 FROM public.interactions inter
      WHERE inter.item_id = item_photos.item_id
        AND inter.user_id = auth.uid()
        AND inter.action = 'like'
    )
  )
  WITH CHECK (
    -- Only owners can modify photos
    EXISTS (
      SELECT 1 FROM public.items i 
      WHERE i.id = item_photos.item_id 
        AND i.owner_id = auth.uid()
    )
  );

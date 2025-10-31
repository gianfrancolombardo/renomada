-- Hybrid RLS policy for item_photos
-- This allows:
-- 1. Item owners to manage their own photos (all operations)
-- 2. Users who have "liked" an item to view its photos
-- 3. Chat participants to view photos as fallback (for existing chats without likes)

-- Drop the existing policy
DROP POLICY IF EXISTS item_photos_owner_and_likers ON public.item_photos;

-- Create a hybrid policy
CREATE POLICY item_photos_owner_likers_and_chat_participants
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
    OR
    -- Chat participants can view photos (fallback for existing chats)
    EXISTS (
      SELECT 1 FROM public.items i
      JOIN public.chats c ON c.item_id = i.id
      WHERE i.id = item_photos.item_id
        AND (c.a_user_id = auth.uid() OR c.b_user_id = auth.uid())
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

-- Cleanup script to remove unnecessary or conflicting RLS policies
-- This script removes policies that don't add value or cause conflicts

-- 1. Remove redundant profiles policies that might conflict
-- Keep only the essential ones

-- Check if profiles_chat_participants_select exists and is redundant
-- (This policy might allow too broad access to profiles)
DROP POLICY IF EXISTS "profiles_chat_participants_select" ON profiles;

-- The profiles_self_select policy should be sufficient for most cases
-- We'll keep profiles_self_update and profiles_self_insert

-- 2. Clean up items policies - remove redundant ones
-- Keep items_owner_insert_update_delete and items_chat_participants_select

-- 3. Clean up interactions policies
-- Keep interactions_self_all (it's clean and secure)

-- 4. Clean up chats policies  
-- Keep chats_participants_select, chats_participants_insert, chats_participants_update

-- 5. Clean up messages policies
-- Keep messages_participants_select, messages_participants_insert, messages_participants_update

-- 6. Clean up push_tokens policies
-- Keep push_tokens_self_all

-- 7. Remove any duplicate storage policies that might exist
-- (These are handled in the main fix script)

-- 8. Add comments to clarify the security model
COMMENT ON TABLE item_photos IS 
'Photos for items. Accessible by: 1) Item owners (full CRUD), 2) Users who liked the item (read only), 3) Chat participants for that item (read only).';

COMMENT ON TABLE items IS 
'Items for exchange. Accessible by: 1) Item owners (full CRUD), 2) Chat participants (read only for items they are discussing).';

COMMENT ON TABLE chats IS 
'Chats between users about items. Accessible only by participants (a_user_id and b_user_id).';

COMMENT ON TABLE messages IS 
'Messages in chats. Accessible only by participants of the related chat.';

-- 9. Create a view to help debug RLS issues (optional, for development)
CREATE OR REPLACE VIEW item_photos_access_debug AS
SELECT 
  ip.id as photo_id,
  ip.item_id,
  i.title as item_title,
  i.owner_id as item_owner_id,
  auth.uid() as current_user_id,
  CASE 
    WHEN i.owner_id = auth.uid() THEN 'owner'
    WHEN EXISTS (
      SELECT 1 FROM interactions inter 
      WHERE inter.item_id = ip.item_id 
      AND inter.user_id = auth.uid() 
      AND inter.action = 'like'
    ) THEN 'liker'
    WHEN EXISTS (
      SELECT 1 FROM chats c
      WHERE c.item_id = ip.item_id 
      AND (c.a_user_id = auth.uid() OR c.b_user_id = auth.uid())
    ) THEN 'chat_participant'
    ELSE 'no_access'
  END as access_type
FROM item_photos ip
JOIN items i ON i.id = ip.item_id;

-- Grant access to authenticated users for debugging
GRANT SELECT ON item_photos_access_debug TO authenticated;

COMMENT ON VIEW item_photos_access_debug IS 
'Debug view to help understand RLS access patterns for item photos. Shows what type of access the current user has to each photo.';

-- 10. Create a function to test RLS policies (for development/debugging)
CREATE OR REPLACE FUNCTION test_item_photos_rls(p_item_id uuid)
RETURNS TABLE (
  photo_id uuid,
  photo_path text,
  can_access boolean,
  access_reason text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ip.id,
    ip.path,
    can_access_item_photos(ip.item_id, auth.uid()) as can_access,
    CASE 
      WHEN i.owner_id = auth.uid() THEN 'owner'
      WHEN EXISTS (
        SELECT 1 FROM interactions inter 
        WHERE inter.item_id = ip.item_id 
        AND inter.user_id = auth.uid() 
        AND inter.action = 'like'
      ) THEN 'liker'
      WHEN EXISTS (
        SELECT 1 FROM chats c
        WHERE c.item_id = ip.item_id 
        AND (c.a_user_id = auth.uid() OR c.b_user_id = auth.uid())
      ) THEN 'chat_participant'
      ELSE 'no_access'
    END as access_reason
  FROM item_photos ip
  JOIN items i ON i.id = ip.item_id
  WHERE ip.item_id = p_item_id;
END;
$$;

GRANT EXECUTE ON FUNCTION test_item_photos_rls(uuid) TO authenticated;

COMMENT ON FUNCTION test_item_photos_rls(uuid) IS 
'Test function to debug RLS access to item photos. Returns access status for all photos of a specific item.';

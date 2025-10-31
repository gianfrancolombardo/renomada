-- Verification script to test RLS fixes for item photos in chat
-- Run this after applying the main fix to verify everything works

-- 1. Check that all required policies exist
SELECT 
  'item_photos' as table_name,
  policyname,
  cmd as operation,
  roles,
  CASE WHEN qual IS NOT NULL THEN 'Has USING clause' ELSE 'No USING clause' END as using_clause,
  CASE WHEN with_check IS NOT NULL THEN 'Has WITH CHECK' ELSE 'No WITH CHECK' END as with_check
FROM pg_policies 
WHERE tablename = 'item_photos'
ORDER BY policyname;

-- 2. Verify RLS is enabled on all tables
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled,
  CASE WHEN rowsecurity THEN '✅ RLS Enabled' ELSE '❌ RLS Disabled' END as status
FROM pg_tables 
WHERE tablename IN ('profiles', 'items', 'item_photos', 'interactions', 'chats', 'messages', 'push_tokens')
ORDER BY tablename;

-- 3. Test the helper function exists and works
SELECT 
  'can_access_item_photos function' as test_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_proc p 
      JOIN pg_namespace n ON n.oid = p.pronamespace 
      WHERE n.nspname = 'public' 
      AND p.proname = 'can_access_item_photos'
    ) THEN '✅ Function exists'
    ELSE '❌ Function missing'
  END as status;

-- 4. Test access patterns (this will only work if you have test data)
-- Replace the UUIDs with actual IDs from your database

-- Test 1: Check if current user can access photos for items they own
SELECT 
  'Own items access' as test_type,
  COUNT(*) as accessible_photos
FROM item_photos ip
JOIN items i ON i.id = ip.item_id
WHERE i.owner_id = auth.uid();

-- Test 2: Check if current user can access photos for items they liked
SELECT 
  'Liked items access' as test_type,
  COUNT(*) as accessible_photos
FROM item_photos ip
JOIN items i ON i.id = ip.item_id
JOIN interactions inter ON inter.item_id = i.id
WHERE inter.user_id = auth.uid() 
AND inter.action = 'like';

-- Test 3: Check if current user can access photos for items in their chats
SELECT 
  'Chat items access' as test_type,
  COUNT(*) as accessible_photos
FROM item_photos ip
JOIN items i ON i.id = ip.item_id
JOIN chats c ON c.item_id = i.id
WHERE (c.a_user_id = auth.uid() OR c.b_user_id = auth.uid());

-- 5. Test storage policies
SELECT 
  'item-photos storage policies' as test_type,
  policyname,
  cmd as operation,
  CASE WHEN qual IS NOT NULL THEN 'Has USING clause' ELSE 'No USING clause' END as using_clause
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%item%photos%'
ORDER BY policyname;

-- 6. Test the debug view (if it exists)
SELECT 
  'Debug view access' as test_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_views 
      WHERE viewname = 'item_photos_access_debug'
    ) THEN '✅ Debug view exists'
    ELSE '❌ Debug view missing'
  END as status;

-- 7. Sample query to test actual photo access in a chat context
-- This simulates what ChatService.getChatWithDetails() does
WITH user_chats AS (
  SELECT DISTINCT c.item_id
  FROM chats c
  WHERE (c.a_user_id = auth.uid() OR c.b_user_id = auth.uid())
)
SELECT 
  'Chat photo access test' as test_type,
  COUNT(ip.id) as total_photos_accessible,
  COUNT(DISTINCT ip.item_id) as items_with_accessible_photos
FROM user_chats uc
JOIN item_photos ip ON ip.item_id = uc.item_id;

-- 8. Test signed URL generation capability
-- This checks if the storage bucket is properly configured
SELECT 
  'Storage bucket config' as test_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM storage.buckets 
      WHERE name = 'item-photos'
    ) THEN '✅ item-photos bucket exists'
    ELSE '❌ item-photos bucket missing'
  END as status;

-- 9. Summary of all tests
SELECT 
  'RLS Fix Verification Summary' as summary,
  'Run the individual test queries above to verify each component' as instructions,
  'If all tests pass, the RLS fix should resolve the chat image issue' as expected_result;

-- 10. Optional: Test with specific item ID (replace with actual ID)
-- Uncomment and modify this section to test with real data
/*
SELECT 
  'Specific item test' as test_type,
  ip.id as photo_id,
  ip.path as photo_path,
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
WHERE ip.item_id = 'REPLACE_WITH_ACTUAL_ITEM_ID'
LIMIT 5;
*/

-- Optimized RPC function for getting user chats with all related data
-- This eliminates N+1 queries by fetching everything in a single query

CREATE OR REPLACE FUNCTION get_user_chats_optimized(p_user_id uuid)
RETURNS TABLE (
  -- Chat data
  chat_id uuid,
  chat_item_id uuid,
  chat_a_user_id uuid,
  chat_b_user_id uuid,
  chat_created_at timestamptz,
  chat_status text,
  
  -- Item data
  item_title text,
  item_description text,
  item_status text,
  item_created_at timestamptz,
  
  -- Other user data
  other_user_id uuid,
  other_username text,
  other_avatar_url text,
  
  -- Last message data
  last_message_id uuid,
  last_message_content text,
  last_message_created_at timestamptz,
  last_message_sender_id uuid,
  
  -- First photo path
  first_photo_path text,
  
  -- Unread count
  unread_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as chat_id,
    c.item_id as chat_item_id,
    c.a_user_id as chat_a_user_id,
    c.b_user_id as chat_b_user_id,
    c.created_at as chat_created_at,
    c.status::text as chat_status,
    
    i.title as item_title,
    i.description as item_description,
    i.status::text as item_status,
    i.created_at as item_created_at,
    
    -- Determine other user (the one who is not p_user_id)
    CASE 
      WHEN c.a_user_id = p_user_id THEN c.b_user_id
      ELSE c.a_user_id
    END as other_user_id,
    
    -- Get username of other user
    CASE 
      WHEN c.a_user_id = p_user_id THEN p_b.username
      ELSE p_a.username
    END as other_username,
    
    -- Get avatar URL of other user
    CASE 
      WHEN c.a_user_id = p_user_id THEN p_b.avatar_url
      ELSE p_a.avatar_url
    END as other_avatar_url,
    
    -- Last message data (if exists)
    lm.id as last_message_id,
    lm.content as last_message_content,
    lm.created_at as last_message_created_at,
    lm.sender_id as last_message_sender_id,
    
    -- First photo path (if exists)
    fp.path as first_photo_path,
    
    -- Unread message count
    uc.count as unread_count
    
  FROM chats c
  
  -- Join with items table
  JOIN items i ON i.id = c.item_id
  
  -- Join with profiles for both users
  JOIN profiles p_a ON p_a.user_id = c.a_user_id
  JOIN profiles p_b ON p_b.user_id = c.b_user_id
  
  -- Get last message for each chat
  LEFT JOIN LATERAL (
    SELECT id, content, created_at, sender_id
    FROM messages 
    WHERE chat_id = c.id 
    ORDER BY created_at DESC 
    LIMIT 1
  ) lm ON true
  
  -- Get first photo for each item
  LEFT JOIN LATERAL (
    SELECT path
    FROM item_photos 
    WHERE item_id = i.id 
    ORDER BY created_at ASC 
    LIMIT 1
  ) fp ON true
  
  -- Get unread message count
  LEFT JOIN LATERAL (
    SELECT COUNT(*) as count
    FROM messages 
    WHERE chat_id = c.id 
    AND sender_id != p_user_id 
    AND status = 'sent'
  ) uc ON true
  
  -- Filter for chats where p_user_id is a participant
  WHERE (c.a_user_id = p_user_id OR c.b_user_id = p_user_id)
  
  -- Order by most recent activity (last message or chat creation)
  ORDER BY COALESCE(lm.created_at, c.created_at) DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_chats_optimized(uuid) TO authenticated;

-- Add comment explaining the function
COMMENT ON FUNCTION get_user_chats_optimized(uuid) IS 
'Optimized function to get all chat data in a single query. Returns chats with items, users, last messages, photos, and unread counts. Eliminates N+1 queries for better performance.';

-- Create index to optimize the query performance
CREATE INDEX IF NOT EXISTS idx_chats_user_participants 
ON chats (a_user_id, b_user_id);

CREATE INDEX IF NOT EXISTS idx_messages_chat_created_sender 
ON messages (chat_id, created_at DESC, sender_id);

CREATE INDEX IF NOT EXISTS idx_item_photos_item_created 
ON item_photos (item_id, created_at ASC);

-- Test function to verify it works correctly
-- SELECT * FROM get_user_chats_optimized('user-uuid-here') LIMIT 5;

-- Performance monitoring query
-- EXPLAIN ANALYZE SELECT * FROM get_user_chats_optimized('user-uuid-here');

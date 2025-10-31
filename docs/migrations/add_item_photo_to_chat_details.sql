-- Add first photo path to chat details function
-- This migration updates the get_user_chats_with_details function to include the first photo of each item

-- Drop the existing function
DROP FUNCTION IF EXISTS get_user_chats_with_details(uuid);

-- Create the updated function with first photo path
CREATE OR REPLACE FUNCTION get_user_chats_with_details(p_user_id uuid)
RETURNS TABLE (
  chat_id uuid,
  item_id uuid,
  a_user_id uuid,
  b_user_id uuid,
  chat_status text,
  chat_created_at timestamptz,
  item_title text,
  item_description text,
  item_status text,
  item_owner_id uuid,
  other_user_id uuid,
  other_username text,
  other_avatar_url text,
  last_message_id uuid,
  last_message_content text,
  last_message_created_at timestamptz,
  last_message_sender_id uuid,
  unread_count bigint,
  first_photo_path text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as chat_id,
    c.item_id,
    c.a_user_id,
    c.b_user_id,
    c.status as chat_status,
    c.created_at as chat_created_at,
    i.title as item_title,
    i.description as item_description,
    i.status::text as item_status,
    i.owner_id as item_owner_id,
    CASE 
      WHEN c.a_user_id = p_user_id THEN c.b_user_id
      ELSE c.a_user_id
    END as other_user_id,
    p.username as other_username,
    p.avatar_url as other_avatar_url,
    m.id as last_message_id,
    m.content as last_message_content,
    m.created_at as last_message_created_at,
    m.sender_id as last_message_sender_id,
    COALESCE(unread.count, 0) as unread_count,
    ip.path as first_photo_path
  FROM chats c
  INNER JOIN items i ON c.item_id = i.id
  LEFT JOIN profiles p ON (
    CASE 
      WHEN c.a_user_id = p_user_id THEN c.b_user_id
      ELSE c.a_user_id
    END = p.user_id
  )
  LEFT JOIN lateral (
    SELECT id, content, created_at, sender_id
    FROM messages
    WHERE messages.chat_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) m ON true
  LEFT JOIN lateral (
    SELECT COUNT(*) as count
    FROM messages
    WHERE messages.chat_id = c.id
      AND sender_id != p_user_id
      AND status != 'read'
  ) unread ON true
  LEFT JOIN lateral (
    SELECT path
    FROM item_photos
    WHERE item_photos.item_id = i.id
    ORDER BY created_at ASC
    LIMIT 1
  ) ip ON true
  WHERE c.a_user_id = p_user_id OR c.b_user_id = p_user_id
  ORDER BY c.created_at DESC;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_chats_with_details(uuid) TO authenticated;

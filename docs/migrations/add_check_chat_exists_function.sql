-- Migration: Add check_chat_exists function for debugging RLS issues
-- Created: 2025-10-09
-- Purpose: Helper function to detect if chat exists bypassing RLS for debugging

-- Function to check if a chat exists (bypasses RLS for debugging)
create or replace function check_chat_exists(p_chat_id uuid)
returns boolean
language plpgsql
security definer
as $$
begin
  return exists (
    select 1
    from public.chats
    where id = p_chat_id
  );
end;
$$;

-- Grant execute to authenticated users
grant execute on function check_chat_exists(uuid) to authenticated;

-- Add comment
comment on function check_chat_exists(uuid) is 'Helper function to check if a chat exists, bypassing RLS. Used for debugging RLS configuration issues.';


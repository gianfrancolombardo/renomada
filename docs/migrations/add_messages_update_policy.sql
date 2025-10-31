-- Add UPDATE policy for messages table
-- This allows participants to update message status (e.g., mark as read)

-- Add UPDATE policy for messages
DROP POLICY IF EXISTS messages_participants_update ON public.messages;
CREATE POLICY messages_participants_update
  ON public.messages FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.chats c
    WHERE c.id = messages.chat_id
      AND (auth.uid() = c.a_user_id OR auth.uid() = c.b_user_id)
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.chats c
    WHERE c.id = messages.chat_id
      AND (auth.uid() = c.a_user_id OR auth.uid() = c.b_user_id)
  ));

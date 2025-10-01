import '../../core/config/supabase_config.dart';
import '../models/message.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  // Send a message
  Future<Message> sendMessage({
    required String chatId,
    required String content,
  }) async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      final messageData = {
        'chat_id': chatId,
        'sender_id': currentUserId,
        'content': content.trim(),
        'status': 'sent',
      };

      final response = await SupabaseConfig.client
          .from('messages')
          .insert(messageData)
          .select()
          .single();

      return Message.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a chat
  Future<List<Message>> getChatMessages({
    required String chatId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map((json) => Message.fromJson(json))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  // Get latest messages for a chat
  Future<List<Message>> getLatestMessages({
    required String chatId,
    int limit = 20,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response
          .map((json) => Message.fromJson(json))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      throw Exception('Failed to fetch latest messages: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      await SupabaseConfig.client
          .from('messages')
          .update({'status': 'read'})
          .eq('chat_id', chatId)
          .neq('sender_id', userId) // Don't mark own messages as read
          .eq('status', 'sent');
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Update message status
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      await SupabaseConfig.client
          .from('messages')
          .update({'status': status.name})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await SupabaseConfig.client
          .from('messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Stream of messages for realtime updates
  Stream<List<Message>> getChatMessagesStream(String chatId) {
    return SupabaseConfig.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) {
      return data.map((json) => Message.fromJson(json)).toList();
    });
  }

  // Get unread message count for a chat
  Future<int> getUnreadCount(String chatId) async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      final response = await SupabaseConfig.client
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .neq('sender_id', currentUserId)
          .eq('status', 'sent');

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Get total unread count for user
  Future<int> getTotalUnreadCount() async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      final response = await SupabaseConfig.client
          .from('messages')
          .select('id')
          .eq('status', 'sent')
          .neq('sender_id', currentUserId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }
}

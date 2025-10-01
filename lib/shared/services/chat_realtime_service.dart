import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../shared/models/message.dart';

class ChatRealtimeService extends ChangeNotifier {
  static final ChatRealtimeService _instance = ChatRealtimeService._internal();
  factory ChatRealtimeService() => _instance;
  ChatRealtimeService._internal();

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _chatsChannel;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Initialize realtime connections
  Future<void> initialize() async {
    if (_isConnected) return;

    try {
      // Ensure Supabase is initialized
      if (SupabaseConfig.client.auth.currentUser == null) {
        debugPrint('Cannot initialize realtime: user not authenticated');
        return;
      }

      await _setupMessagesChannel();
      await _setupChatsChannel();
      _isConnected = true;
      notifyListeners();
      debugPrint('✅ Chat realtime initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize chat realtime: $e');
    }
  }

  // Setup messages channel for realtime message updates
  Future<void> _setupMessagesChannel() async {
    _messagesChannel = SupabaseConfig.client
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: _handleNewMessage,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: _handleMessageUpdate,
        );

    await _messagesChannel!.subscribe();
  }

  // Setup chats channel for realtime chat updates
  Future<void> _setupChatsChannel() async {
    _chatsChannel = SupabaseConfig.client
        .channel('chats')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chats',
          callback: _handleNewChat,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chats',
          callback: _handleChatUpdate,
        );

    await _chatsChannel!.subscribe();
  }

  // Handle new message
  void _handleNewMessage(PostgresChangePayload payload) {
    try {
      final messageData = payload.newRecord;
      final message = Message.fromJson(messageData);
      
      // Notify listeners about new message
      notifyListeners();
      
      // You can add more specific callbacks here if needed
      debugPrint('New message received: ${message.id}');
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  // Handle message update
  void _handleMessageUpdate(PostgresChangePayload payload) {
    try {
      final messageData = payload.newRecord;
      final message = Message.fromJson(messageData);
      
      // Notify listeners about message update
      notifyListeners();
      
      debugPrint('Message updated: ${message.id}');
    } catch (e) {
      debugPrint('Error handling message update: $e');
    }
  }

  // Handle new chat
  void _handleNewChat(PostgresChangePayload payload) {
    try {
      final chatData = payload.newRecord;
      
      // Notify listeners about new chat
      notifyListeners();
      
      debugPrint('New chat created: ${chatData['id']}');
    } catch (e) {
      debugPrint('Error handling new chat: $e');
    }
  }

  // Handle chat update
  void _handleChatUpdate(PostgresChangePayload payload) {
    try {
      final chatData = payload.newRecord;
      
      // Notify listeners about chat update
      notifyListeners();
      
      debugPrint('Chat updated: ${chatData['id']}');
    } catch (e) {
      debugPrint('Error handling chat update: $e');
    }
  }

  // Subscribe to specific chat messages
  Future<void> subscribeToChat(String chatId) async {
    try {
      final channel = SupabaseConfig.client
          .channel('chat_$chatId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chat_id',
              value: chatId,
            ),
            callback: _handleNewMessage,
          );

      await channel.subscribe();
    } catch (e) {
      debugPrint('Failed to subscribe to chat $chatId: $e');
    }
  }

  // Unsubscribe from specific chat
  Future<void> unsubscribeFromChat(String chatId) async {
    try {
      final channelName = 'chat_$chatId';
      final channel = SupabaseConfig.client.channel(channelName);
      await channel.unsubscribe();
    } catch (e) {
      debugPrint('Failed to unsubscribe from chat $chatId: $e');
    }
  }

  // Disconnect all channels
  Future<void> disconnect() async {
    try {
      await _messagesChannel?.unsubscribe();
      await _chatsChannel?.unsubscribe();
      _isConnected = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to disconnect realtime: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

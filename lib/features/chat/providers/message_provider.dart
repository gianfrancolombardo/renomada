import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/message.dart';
import '../../../shared/services/message_service.dart';
import '../../../core/config/supabase_config.dart';
import 'chat_providers.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _messageService;
  final Ref _ref;
  
  MessageProvider(this._messageService, this._ref);
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  String? _currentChatId;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasError => _error != null;
  String? get currentChatId => _currentChatId;

  // Load messages for a chat
  Future<void> loadMessages(String chatId) async {
    _currentChatId = chatId;
    _setLoading(true);
    _clearError();

    try {
      _messages = await _messageService.getChatMessages(chatId: chatId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load latest messages for a chat
  Future<void> loadLatestMessages(String chatId) async {
    _currentChatId = chatId;
    _setLoading(true);
    _clearError();

    try {
      _messages = await _messageService.getLatestMessages(chatId: chatId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load latest messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send a message
  Future<Message?> sendMessage(String content) async {
    if (_currentChatId == null || content.trim().isEmpty) return null;

    _setSending(true);
    _clearError();

    try {
      final message = await _messageService.sendMessage(
        chatId: _currentChatId!,
        content: content,
      );
      
      // Add message to local list
      _messages.add(message);
      notifyListeners();
      
      return message;
    } catch (e) {
      _setError('Failed to send message: $e');
      return null;
    } finally {
      _setSending(false);
    }
  }

  // Add message to local list (for realtime updates)
  void addMessage(Message message) {
    if (message.chatId == _currentChatId) {
      _messages.add(message);
      notifyListeners();
    }
  }

  // Update message in local list
  void updateMessage(Message message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead() async {
    if (_currentChatId == null) return;

    try {
      await _messageService.markMessagesAsRead(
        chatId: _currentChatId!,
        userId: SupabaseConfig.currentUser?.id ?? '',
      );
      
      // Refresh chat list to update unread count
      // This will trigger a rebuild of the chat list with updated unread counts
      _ref.read(chatProvider.notifier).refreshChats();
    } catch (e) {
      // Don't show error for read status updates
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageService.deleteMessage(messageId);
      _messages.removeWhere((message) => message.id == messageId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete message: $e');
    }
  }

  // Clear messages
  void clearMessages() {
    _messages.clear();
    _currentChatId = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSending(bool sending) {
    _isSending = sending;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

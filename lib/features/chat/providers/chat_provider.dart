import 'package:flutter/foundation.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../shared/models/chat.dart';
import '../../../shared/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  
  ChatProvider(this._chatService);
  
  List<ChatWithDetails> _chats = [];
  bool _isLoading = false;
  String? _error;

  List<ChatWithDetails> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Load user chats
  Future<void> loadChats() async {
    _setLoading(true);
    _clearError();

    try {
      _chats = await _chatService.getUserChats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh chats
  Future<void> refreshChats() async {
    await loadChats();
  }

  // Get or create chat for item
  Future<ChatWithDetails?> getOrCreateChat({
    required String itemId,
    required String otherUserId,
  }) async {
    try {
      final chat = await _chatService.getOrCreateChat(
        itemId: itemId,
        otherUserId: otherUserId,
      );
      
      // Reload chats to get updated list
      await loadChats();
      
      return await _chatService.getChatWithDetails(chat.id);
    } catch (e) {
      _setError('Failed to create chat: $e');
      return null;
    }
  }

  // Update chat status
  Future<void> updateChatStatus({
    required String chatId,
    required String status,
  }) async {
    try {
      await _chatService.updateChatStatus(
        chatId: chatId,
        status: ChatStatus.values.firstWhere(
          (s) => s.name == status,
          orElse: () => ChatStatus.coordinating,
        ),
      );
      
      // Reload chats to get updated status
      await loadChats();
    } catch (e) {
      _setError('Failed to update chat status: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await _chatService.deleteChat(chatId);
      await loadChats();
    } catch (e) {
      _setError('Failed to delete chat: $e');
    }
  }

  // Get chat by ID
  ChatWithDetails? getChatById(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.chat.id == chatId);
    } catch (e) {
      return null;
    }
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

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

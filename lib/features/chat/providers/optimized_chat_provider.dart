import 'package:flutter/foundation.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../shared/models/chat.dart';
import '../../../shared/models/item.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/optimized_chat_service.dart';

/// Optimized ChatProvider with performance improvements
class OptimizedChatProvider extends ChangeNotifier {
  final OptimizedChatService _chatService;
  
  OptimizedChatProvider(this._chatService);
  
  List<ChatWithDetails> _chats = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastLoadTime;

  List<ChatWithDetails> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  DateTime? get lastLoadTime => _lastLoadTime;

  /// Load user chats with optimized performance
  Future<void> loadChats() async {
    _setLoading(true);
    _clearError();

    try {
      print('🚀 [OptimizedChatProvider] Loading chats...');
      _chats = await _chatService.getUserChatsOptimized();
      _lastLoadTime = DateTime.now();
      notifyListeners();
      print('✅ [OptimizedChatProvider] Loaded ${_chats.length} chats');
    } catch (e) {
      print('❌ [OptimizedChatProvider] Error loading chats: $e');
      _setError('Failed to load chats: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh chats (with cache consideration)
  Future<void> refreshChats({bool forceRefresh = false}) async {
    // If we have recent data and not forcing refresh, skip
    if (!forceRefresh && _lastLoadTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad.inMinutes < 1) {
        print('⏭️ [OptimizedChatProvider] Skipping refresh - data is fresh');
        return;
      }
    }
    
    await loadChats();
  }

  /// Get or create chat with optimistic updates
  Future<ChatWithDetails?> getOrCreateChatOptimistic({
    required String itemId,
    required String otherUserId,
  }) async {
    try {
      print('🚀 [OptimizedChatProvider] Creating chat optimistically...');
      
      // Create temporary chat for immediate UI feedback
      final tempChatId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final currentUserId = 'current_user_id'; // This should be injected
      
      final tempChat = ChatWithDetails(
        chat: Chat(
          id: tempChatId,
          itemId: itemId,
          aUserId: currentUserId,
          bUserId: otherUserId,
          createdAt: DateTime.now(),
          status: ChatStatus.coordinating,
        ),
        item: Item(
          id: itemId,
          ownerId: otherUserId,
          title: 'Cargando...',
          createdAt: DateTime.now(),
        ),
        otherUser: UserProfile(
          userId: otherUserId,
          username: 'Usuario',
        ),
        lastMessage: null,
        unreadCount: 0,
        firstPhotoUrl: null,
      );
      
      // Add to top of list immediately
      _chats.insert(0, tempChat);
      notifyListeners();
      
      // Create real chat in background
      try {
        final realChat = await _chatService.getOrCreateChat(
          itemId: itemId,
          otherUserId: otherUserId,
        );
        
        final realChatDetails = await _chatService.getChatWithDetails(realChat.id);
        
        // Replace temporary chat with real one
        if (realChatDetails != null) {
          final tempIndex = _chats.indexWhere((c) => c.chat.id == tempChatId);
          if (tempIndex != -1) {
            _chats[tempIndex] = realChatDetails;
            notifyListeners();
          }
        }
        
        print('✅ [OptimizedChatProvider] Chat created successfully');
        return realChatDetails;
        
      } catch (e) {
        // Remove temporary chat on error
        _chats.removeWhere((c) => c.chat.id == tempChatId);
        notifyListeners();
        throw e;
      }
      
    } catch (e) {
      print('❌ [OptimizedChatProvider] Error creating chat: $e');
      _setError('Failed to create chat: $e');
      return null;
    }
  }

  /// Update chat status with optimistic update
  Future<void> updateChatStatusOptimistic({
    required String chatId,
    required ChatStatus status,
  }) async {
    try {
      // Find chat and update optimistically
      final chatIndex = _chats.indexWhere((c) => c.chat.id == chatId);
      if (chatIndex != -1) {
        final oldChat = _chats[chatIndex];
        final updatedChat = oldChat.copyWith(
          chat: oldChat.chat.copyWith(status: status),
        );
        _chats[chatIndex] = updatedChat;
        notifyListeners();
      }
      
      // Update in background
      await _chatService.updateChatStatus(
        chatId: chatId,
        status: status,
      );
      
      print('✅ [OptimizedChatProvider] Chat status updated to ${status.name}');
      
    } catch (e) {
      // Revert optimistic update on error
      await refreshChats(forceRefresh: true);
      print('❌ [OptimizedChatProvider] Error updating chat status: $e');
      _setError('Failed to update chat status: $e');
    }
  }

  /// Update chat in place (for realtime updates)
  void updateChatInPlace(ChatWithDetails updatedChat) {
    final index = _chats.indexWhere((c) => c.chat.id == updatedChat.chat.id);
    if (index != -1) {
      _chats[index] = updatedChat;
      notifyListeners();
    }
  }

  /// Add new chat (for realtime updates)
  void addNewChat(ChatWithDetails newChat) {
    // Check if chat already exists
    final exists = _chats.any((c) => c.chat.id == newChat.chat.id);
    if (!exists) {
      _chats.insert(0, newChat);
      notifyListeners();
    }
  }

  /// Update unread count for a specific chat
  void updateUnreadCount(String chatId, int unreadCount) {
    final index = _chats.indexWhere((c) => c.chat.id == chatId);
    if (index != -1) {
      final chat = _chats[index];
      final updatedChat = chat.copyWith(unreadCount: unreadCount);
      _chats[index] = updatedChat;
      notifyListeners();
    }
  }

  /// Delete chat with optimistic update
  Future<void> deleteChatOptimistic(String chatId) async {
    try {
      // Remove from list immediately
      final chatIndex = _chats.indexWhere((c) => c.chat.id == chatId);
      
      if (chatIndex != -1) {
        _chats.removeAt(chatIndex);
        notifyListeners();
      }
      
      // Delete in background
      await _chatService.deleteChat(chatId);
      
      print('✅ [OptimizedChatProvider] Chat deleted successfully');
      
    } catch (e) {
      // Revert on error by refreshing
      await refreshChats(forceRefresh: true);
      print('❌ [OptimizedChatProvider] Error deleting chat: $e');
      _setError('Failed to delete chat: $e');
    }
  }

  /// Get chat by ID (check cache first)
  ChatWithDetails? getChatById(String chatId) {
    // Check cache first
    final cachedChat = _chatService.getCachedChatDetails(chatId);
    if (cachedChat != null) {
      return cachedChat;
    }
    
    // Fallback to local list
    try {
      return _chats.firstWhere((chat) => chat.chat.id == chatId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all data
  void clearAll() {
    _chats.clear();
    _lastLoadTime = null;
    _clearError();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  /// Get performance stats
  Map<String, dynamic> getPerformanceStats() {
    return {
      'chats_count': _chats.length,
      'last_load_time': _lastLoadTime?.toIso8601String(),
      'is_loading': _isLoading,
      'has_error': hasError,
      'cache_stats': OptimizedChatService.getCacheStats(),
    };
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

/// Extension to add copyWith method to Chat
extension ChatCopyWith on Chat {
  Chat copyWith({
    String? id,
    String? itemId,
    String? aUserId,
    String? bUserId,
    DateTime? createdAt,
    ChatStatus? status,
  }) {
    return Chat(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      aUserId: aUserId ?? this.aUserId,
      bUserId: bUserId ?? this.bUserId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

import '../../core/config/supabase_config.dart';
import '../models/chat.dart';
import '../models/chat_with_details.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/message.dart';
import 'chat_service.dart';

/// Optimized ChatService with performance improvements
class OptimizedChatService {
  static final OptimizedChatService _instance = OptimizedChatService._internal();
  factory OptimizedChatService() => _instance;
  OptimizedChatService._internal();

  // Cache for signed URLs to avoid repeated calls
  static final Map<String, _CachedUrl> _urlCache = {};
  
  // Cache for chat details to avoid repeated queries
  static final Map<String, ChatWithDetails> _chatCache = {};
  static DateTime? _lastCacheUpdate;

  /// Get all chats for current user with optimized queries
  Future<List<ChatWithDetails>> getUserChatsOptimized() async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      print('🚀 [OptimizedChatService] Loading chats with optimized query...');
      
      // Use optimized RPC function if available, fallback to current method
      try {
        final chatsResponse = await SupabaseConfig.client.rpc(
          'get_user_chats_optimized',
          params: {'p_user_id': currentUserId},
        );
        
        return await _processOptimizedChatResponse(chatsResponse);
      } catch (e) {
        print('⚠️ [OptimizedChatService] Optimized RPC not available, using fallback: $e');
        return await _getUserChatsFallback();
      }
    } catch (e) {
      print('❌ [OptimizedChatService] Error loading chats: $e');
      throw Exception('Failed to fetch user chats: $e');
    }
  }

  /// Process optimized RPC response with batch signed URLs
  Future<List<ChatWithDetails>> _processOptimizedChatResponse(List<dynamic> chatsResponse) async {
    final List<ChatWithDetails> chatsWithDetails = [];
    
    // Collect all photo paths for batch processing
    final List<String> photoPaths = [];
    final List<String> avatarPaths = [];
    
    for (final chatData in chatsResponse) {
      if (chatData['first_photo_path'] != null) {
        photoPaths.add(chatData['first_photo_path'] as String);
      }
      if (chatData['other_avatar_url'] != null && !(chatData['other_avatar_url'] as String).startsWith('http')) {
        avatarPaths.add(chatData['other_avatar_url'] as String);
      }
    }
    
    // Batch process signed URLs
    final Map<String, String> photoUrls = await _getBatchSignedUrls(photoPaths, 'item-photos');
    final Map<String, String> avatarUrls = await _getBatchSignedUrls(avatarPaths, 'avatars');
    
    // Process each chat
    for (final chatData in chatsResponse) {
      try {
        // Build Chat object
        final chat = Chat(
          id: chatData['chat_id'] as String,
          itemId: chatData['chat_item_id'] as String,
          aUserId: chatData['chat_a_user_id'] as String,
          bUserId: chatData['chat_b_user_id'] as String,
          createdAt: DateTime.parse(chatData['chat_created_at'] as String),
          status: ChatStatus.values.firstWhere(
            (e) => e.name == chatData['chat_status'],
            orElse: () => ChatStatus.coordinating,
          ),
        );

        // Build Item object
        final item = Item(
          id: chatData['chat_item_id'] as String,
          ownerId: chatData['other_user_id'] as String, // This needs to be corrected in RPC
          title: chatData['item_title'] as String,
          description: chatData['item_description'] as String?,
          status: ItemStatus.values.firstWhere(
            (e) => e.name == chatData['item_status'],
            orElse: () => ItemStatus.available,
          ),
          createdAt: DateTime.parse(chatData['item_created_at'] as String),
        );

        // Get cached signed URLs
        String? avatarUrl = chatData['other_avatar_url'] as String?;
        if (avatarUrl != null && !avatarUrl.startsWith('http')) {
          avatarUrl = avatarUrls[avatarUrl];
        }

        // Build UserProfile object
        final otherUser = UserProfile(
          userId: chatData['other_user_id'] as String,
          username: chatData['other_username'] as String? ?? 'Usuario',
          avatarUrl: avatarUrl,
        );

        // Build Message object (if exists)
        Message? lastMessage;
        if (chatData['last_message_id'] != null) {
          lastMessage = Message(
            id: chatData['last_message_id'] as String,
            chatId: chatData['chat_id'] as String,
            senderId: chatData['last_message_sender_id'] as String,
            content: chatData['last_message_content'] as String,
            createdAt: DateTime.parse(chatData['last_message_created_at'] as String),
            status: MessageStatus.sent,
          );
        }

        final unreadCount = chatData['unread_count'] as int;
        
        // Get cached photo URL
        String? firstPhotoUrl;
        final photoPath = chatData['first_photo_path'] as String?;
        if (photoPath != null) {
          firstPhotoUrl = photoUrls[photoPath];
        }

        chatsWithDetails.add(ChatWithDetails(
          chat: chat,
          item: item,
          otherUser: otherUser,
          lastMessage: lastMessage,
          unreadCount: unreadCount,
          firstPhotoUrl: firstPhotoUrl,
        ));
      } catch (e) {
        print('❌ [OptimizedChatService] Error processing chat: $e');
        continue;
      }
    }

    // Update cache
    _updateChatCache(chatsWithDetails);
    
    print('✅ [OptimizedChatService] Loaded ${chatsWithDetails.length} chats with optimized queries');
    return chatsWithDetails;
  }

  /// Fallback method using current implementation
  Future<List<ChatWithDetails>> _getUserChatsFallback() async {
    // Import and use current ChatService implementation
    final currentService = ChatService();
    return await currentService.getUserChats();
  }

  /// Get or create chat (delegate to original service)
  Future<Chat> getOrCreateChat({
    required String itemId,
    required String otherUserId,
  }) async {
    final currentService = ChatService();
    return await currentService.getOrCreateChat(
      itemId: itemId,
      otherUserId: otherUserId,
    );
  }

  /// Get chat with details (delegate to original service)
  Future<ChatWithDetails?> getChatWithDetails(String chatId) async {
    final currentService = ChatService();
    return await currentService.getChatWithDetails(chatId);
  }

  /// Update chat status (delegate to original service)
  Future<void> updateChatStatus({
    required String chatId,
    required ChatStatus status,
  }) async {
    final currentService = ChatService();
    return await currentService.updateChatStatus(
      chatId: chatId,
      status: status,
    );
  }

  /// Delete chat (delegate to original service)
  Future<void> deleteChat(String chatId) async {
    final currentService = ChatService();
    return await currentService.deleteChat(chatId);
  }

  /// Batch process signed URLs to reduce API calls
  Future<Map<String, String>> _getBatchSignedUrls(List<String> paths, String bucket) async {
    final Map<String, String> urlMap = {};
    
    if (paths.isEmpty) return urlMap;
    
    print('🔄 [OptimizedChatService] Processing ${paths.length} signed URLs for $bucket');
    
    // Process in batches of 5 to avoid rate limits
    for (int i = 0; i < paths.length; i += 5) {
      final batch = paths.skip(i).take(5).toList();
      
      final futures = batch.map((path) async {
        // Check cache first
        final cachedUrl = _getCachedUrl(path);
        if (cachedUrl != null) {
          return MapEntry(path, cachedUrl);
        }
        
        try {
          final url = await SupabaseConfig.storage
              .from(bucket)
              .createSignedUrl(path, 3600);
          
          // Cache the URL
          _cacheUrl(path, url);
          return MapEntry(path, url);
        } catch (e) {
          print('⚠️ [OptimizedChatService] Failed to get signed URL for $path: $e');
          return MapEntry(path, '');
        }
      });
      
      final results = await Future.wait(futures);
      urlMap.addAll(Map.fromEntries(results));
    }
    
    print('✅ [OptimizedChatService] Generated ${urlMap.length} signed URLs');
    return urlMap;
  }

  /// Get cached signed URL
  String? _getCachedUrl(String path) {
    final cached = _urlCache[path];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }
    return null;
  }

  /// Cache signed URL
  void _cacheUrl(String path, String url) {
    _urlCache[path] = _CachedUrl(
      url, 
      DateTime.now().add(const Duration(seconds: 3540)) // 60s buffer before expiry
    );
  }

  /// Update chat cache
  void _updateChatCache(List<ChatWithDetails> chats) {
    for (final chat in chats) {
      _chatCache[chat.chat.id] = chat;
    }
    _lastCacheUpdate = DateTime.now();
    
    // Clean old cache entries (keep only last 50 chats)
    if (_chatCache.length > 50) {
      final keys = _chatCache.keys.toList();
      keys.sort((a, b) => _chatCache[b]!.chat.createdAt.compareTo(_chatCache[a]!.chat.createdAt));
      
      for (int i = 50; i < keys.length; i++) {
        _chatCache.remove(keys[i]);
      }
    }
  }

  /// Get cached chat details
  ChatWithDetails? getCachedChatDetails(String chatId) {
    final cached = _chatCache[chatId];
    if (cached != null) {
      print('🎯 [OptimizedChatService] Cache hit for chat $chatId');
      return cached;
    }
    return null;
  }

  /// Clear all caches
  static void clearCache() {
    _urlCache.clear();
    _chatCache.clear();
    _lastCacheUpdate = null;
    print('🧹 [OptimizedChatService] All caches cleared');
  }

  /// Clear expired cache entries
  static void clearExpiredCache() {
    final now = DateTime.now();
    _urlCache.removeWhere((key, value) => value.expiresAt.isBefore(now));
    
    // Clear chat cache if it's older than 5 minutes
    if (_lastCacheUpdate != null && now.difference(_lastCacheUpdate!).inMinutes > 5) {
      _chatCache.clear();
      _lastCacheUpdate = null;
      print('🧹 [OptimizedChatService] Expired cache entries cleared');
    }
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'url_cache_size': _urlCache.length,
      'chat_cache_size': _chatCache.length,
      'last_cache_update': _lastCacheUpdate?.toIso8601String(),
      'expired_urls': _urlCache.values.where((v) => v.isExpired).length,
    };
  }
}

/// Cached URL with expiration
class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  
  _CachedUrl(this.url, this.expiresAt);
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

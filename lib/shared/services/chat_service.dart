import '../../core/config/supabase_config.dart';
import '../models/chat.dart';
import '../models/chat_with_details.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/message.dart';
import 'signed_url_cache.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Use getter to ensure proper initialization (fixes Flutter Web issues)
  SignedUrlCache get _urlCache => SignedUrlCache();

  // Get all chats for current user with details
  Future<List<ChatWithDetails>> getUserChats() async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      // Use RPC function to get chats with details (bypasses RLS)
      final response = await SupabaseConfig.client.rpc(
        'get_user_chats_with_details',
        params: {'p_user_id': currentUserId},
      );

      // Handle response - ensure it's a List
      final chatsResponse = response is List ? response : (response != null ? [response] : []);
      
      if (chatsResponse.isEmpty) {
        print('ℹ️ [ChatService] No chats found');
        return [];
      }

      final List<ChatWithDetails> chatsWithDetails = [];

      // ✨ OPTIMIZATION: Collect all paths for batch processing
      final List<String> photoPaths = [];
      final List<String> avatarPaths = [];
      
      for (final chatData in chatsResponse) {
        if (chatData is! Map) {
          print('⚠️ [ChatService] Invalid chat data format: $chatData');
          continue;
        }
        
        // Collect photo paths (if first_photo_path is available from RPC)
        final photoPath = chatData['first_photo_path'];
        if (photoPath != null && photoPath is String && photoPath.isNotEmpty) {
          photoPaths.add(photoPath);
        }
        
        // Collect avatar paths (only for storage paths, not external URLs)
        final avatarPath = chatData['other_avatar_url'];
        if (avatarPath != null && avatarPath is String && _isStoragePath(avatarPath)) {
          avatarPaths.add(avatarPath);
        }
      }

      // ✨ OPTIMIZATION: Batch process signed URLs
      final Map<String, String> photoUrls = await _getBatchSignedUrls(photoPaths, 'item-photos');
      final Map<String, String> avatarUrls = await _getBatchSignedUrls(avatarPaths, 'avatars');

      // Process each chat
      for (final chatData in chatsResponse) {
        try {
          if (chatData is! Map) {
            print('⚠️ [ChatService] Skipping invalid chat data: $chatData');
            continue;
          }

          // Validate required fields
          if (chatData['chat_id'] == null || 
              chatData['item_id'] == null || 
              chatData['item_owner_id'] == null ||
              chatData['item_title'] == null) {
            print('⚠️ [ChatService] Missing required fields in chat data: $chatData');
            continue;
          }

          // Build Chat object
          final chat = Chat(
            id: chatData['chat_id'] as String,
            itemId: chatData['item_id'] as String,
            aUserId: chatData['a_user_id'] as String,
            bUserId: chatData['b_user_id'] as String,
            createdAt: DateTime.parse(chatData['chat_created_at'].toString()),
            status: ChatStatus.values.firstWhere(
              (e) => e.name == (chatData['chat_status'] as String? ?? 'coordinating'),
              orElse: () => ChatStatus.coordinating,
            ),
          );

          // Build Item object
          final item = Item(
            id: chatData['item_id'] as String,
            ownerId: chatData['item_owner_id'] as String,
            title: chatData['item_title'] as String,
            description: chatData['item_description'] as String?,
            status: ItemStatus.values.firstWhere(
              (e) => e.name == (chatData['item_status'] as String? ?? 'available'),
              orElse: () => ItemStatus.available,
            ),
            createdAt: DateTime.parse(chatData['chat_created_at'].toString()),
          );

          // ✨ OPTIMIZATION: Get avatar URL from batch processing or use external URL directly
          String? avatarUrl = chatData['other_avatar_url'] as String?;
          if (avatarUrl != null) {
            if (_isStoragePath(avatarUrl)) {
              // It's a storage path, get signed URL from batch
              avatarUrl = avatarUrls[avatarUrl];
            }
            // If it's an external URL (dicebear.com, etc.), use it directly
          }

          // Build UserProfile object
          final otherUser = UserProfile(
            userId: chatData['other_user_id'] as String,
            username: chatData['other_username'] as String? ?? 'Usuario',
            avatarUrl: avatarUrl,
          );

          // Build Message object (if exists)
          Message? lastMessage;
          final lastMessageId = chatData['last_message_id'];
          if (lastMessageId != null) {
            final lastMessageCreatedAt = chatData['last_message_created_at'];
            if (lastMessageCreatedAt != null) {
              try {
                lastMessage = Message(
                  id: lastMessageId.toString(),
                  chatId: chatData['chat_id'] as String,
                  senderId: chatData['last_message_sender_id'] as String,
                  content: chatData['last_message_content'] as String? ?? '',
                  createdAt: DateTime.parse(lastMessageCreatedAt.toString()),
                  status: MessageStatus.sent,
                );
              } catch (e) {
                print('⚠️ [ChatService] Error parsing last message: $e');
              }
            }
          }

          // Handle unread_count which might be bigint from DB
          final unreadCountValue = chatData['unread_count'];
          final unreadCount = unreadCountValue is int 
              ? unreadCountValue 
              : (unreadCountValue is num 
                  ? unreadCountValue.toInt() 
                  : 0);

          // ✨ OPTIMIZATION: Get photo URL from batch processing (or fallback to query if RPC doesn't include it)
          String? firstPhotoUrl;
          final photoPath = chatData['first_photo_path'];
          
          if (photoPath != null && photoPath is String && photoPath.isNotEmpty) {
            // Try to get from batch result first
            firstPhotoUrl = photoUrls[photoPath];
          } else {
            // ✨ FALLBACK: If RPC doesn't include first_photo_path, query it (shouldn't happen after migration)
            try {
              final photoResponse = await SupabaseConfig.client
                  .from('item_photos')
                  .select('path')
                  .eq('item_id', item.id)
                  .order('created_at', ascending: true)
                  .limit(1);
              
              if (photoResponse.isNotEmpty) {
                final fallbackPhotoPath = photoResponse.first['path'] as String;
                firstPhotoUrl = await _getSignedUrlWithCache(fallbackPhotoPath, 'item-photos');
              }
            } catch (e) {
              print('⚠️ [ChatService] Could not get photo for item ${item.id}: $e');
              firstPhotoUrl = null;
            }
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
          print('❌ [ChatService] Error processing chat: $e');
          print('🔍 [ChatService] Chat data: $chatData');
          continue; // Skip this chat and continue with others
        }
      }

      print('✅ [ChatService] Loaded ${chatsWithDetails.length} chats');
      return chatsWithDetails;
    } catch (e, stackTrace) {
      print('❌ [ChatService] Error fetching user chats: $e');
      print('🔍 [ChatService] Stack trace: $stackTrace');
      
      // Provide more specific error messages
      if (e.toString().contains('function') || e.toString().contains('does not exist')) {
        throw Exception('Error: La función RPC get_user_chats_with_details no existe o no está disponible. Verifica que la migración SQL fue aplicada correctamente.');
      } else if (e.toString().contains('permission') || e.toString().contains('denied')) {
        throw Exception('Error: No tienes permisos para acceder a los chats. Verifica la autenticación.');
      } else {
        throw Exception('Error al cargar los chats: $e');
      }
    }
  }

  /// ✨ OPTIMIZATION: Batch process signed URLs to reduce API calls
  Future<Map<String, String>> _getBatchSignedUrls(List<String> paths, String bucket) async {
    final Map<String, String> urlMap = {};
    
    if (paths.isEmpty) return urlMap;
    
    print('🔄 [ChatService] Processing ${paths.length} signed URLs for $bucket');
    
    // Process in batches of 5 to avoid rate limits
    for (int i = 0; i < paths.length; i += 5) {
      final batch = paths.skip(i).take(5).toList();
      
      final futures = batch.map((path) async {
        // Check cache first
        final cachedUrl = _urlCache.getCachedUrl(path);
        if (cachedUrl != null) {
          return MapEntry(path, cachedUrl);
        }
        
        try {
          final url = await SupabaseConfig.storage
              .from(bucket)
              .createSignedUrl(path, 3600);
          
          // Cache the URL
          _urlCache.cacheUrl(path, url, 3600);
          return MapEntry(path, url);
        } catch (e) {
          print('⚠️ [ChatService] Failed to get signed URL for $path: $e');
          return MapEntry(path, '');
        }
      });
      
      final results = await Future.wait(futures);
      urlMap.addAll(Map.fromEntries(results));
    }
    
    print('✅ [ChatService] Generated ${urlMap.length} signed URLs');
    return urlMap;
  }

  /// Get signed URL with cache check
  Future<String?> _getSignedUrlWithCache(String path, String bucket) async {
    // Check cache first
    final cachedUrl = _urlCache.getCachedUrl(path);
    if (cachedUrl != null) {
      return cachedUrl;
    }
    
    try {
      final url = await SupabaseConfig.storage
          .from(bucket)
          .createSignedUrl(path, 3600);
      
      // Cache the URL
      _urlCache.cacheUrl(path, url, 3600);
      return url;
    } catch (e) {
      print('⚠️ [ChatService] Failed to get signed URL for $path: $e');
      return null;
    }
  }

  // Get or create chat for item
  Future<Chat> getOrCreateChat({
    required String itemId,
    required String otherUserId,
  }) async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      // First try to find existing chat
      final existingChats = await SupabaseConfig.client
          .from('chats')
          .select()
          .eq('item_id', itemId)
          .or('a_user_id.eq.$currentUserId,b_user_id.eq.$currentUserId')
          .or('a_user_id.eq.$otherUserId,b_user_id.eq.$otherUserId');

      if (existingChats.isNotEmpty) {
        return Chat.fromJson(existingChats.first);
      }

      // Create new chat
      final chatData = {
        'item_id': itemId,
        'a_user_id': currentUserId,
        'b_user_id': otherUserId,
        'status': 'coordinating',
      };

      final response = await SupabaseConfig.client
          .from('chats')
          .insert(chatData)
          .select()
          .single();

      return Chat.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get or create chat: $e');
    }
  }

  // Update chat status
  Future<void> updateChatStatus({
    required String chatId,
    required ChatStatus status,
  }) async {
    try {
      await SupabaseConfig.client
          .from('chats')
          .update({'status': status.name})
          .eq('id', chatId);
    } catch (e) {
      throw Exception('Failed to update chat status: $e');
    }
  }

  // Get chat by ID
  Future<Chat?> getChatById(String chatId) async {
    try {
      final response = await SupabaseConfig.client
          .from('chats')
          .select()
          .eq('id', chatId)
          .maybeSingle();

      if (response == null) return null;
      return Chat.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  // Check if user can access chat
  Future<bool> canAccessChat(String chatId) async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      final chat = await getChatById(chatId);
      
      if (chat == null) return false;
      return chat.isParticipant(currentUserId);
    } catch (e) {
      return false;
    }
  }

  // Get chat with full details
  Future<ChatWithDetails?> getChatWithDetails(String chatId) async {
    try {
      print('🔍 [ChatService] Loading chat details for chatId: $chatId');
      final currentUserId = SupabaseConfig.currentUser!.id;
      print('👤 [ChatService] Current user ID: $currentUserId');
      
      // Get chat with item details
      print('📡 [ChatService] Fetching chat data...');
      final chatResponse = await SupabaseConfig.client
          .from('chats')
          .select('''
            id,
            item_id,
            a_user_id,
            b_user_id,
            created_at,
            status,
            items!inner(
              id,
              owner_id,
              title,
              description,
              status,
              created_at,
              updated_at
            )
          ''')
          .eq('id', chatId)
          .maybeSingle();

      if (chatResponse == null) {
        print('❌ [ChatService] Chat not found for chatId: $chatId');
        
        // Check if chat exists in database (to detect RLS issues)
        try {
          final rlsCheck = await SupabaseConfig.client.rpc(
            'check_chat_exists',
            params: {'p_chat_id': chatId}
          );
          
          if (rlsCheck == true) {
            print('⚠️ [ChatService] POSIBLE PROBLEMA DE RLS: El chat existe en la BD pero no es accesible');
            print('⚠️ [ChatService] Chat ID: $chatId, User ID: $currentUserId');
          } else {
            print('ℹ️ [ChatService] El chat no existe en la base de datos');
          }
        } catch (rpcError) {
          print('⚠️ [ChatService] No se pudo verificar RLS (función RPC no existe o error): $rpcError');
          print('ℹ️ [ChatService] Considera crear la función check_chat_exists en Supabase');
        }
        
        return null;
      }

      print('✅ [ChatService] Chat data received: ${chatResponse['id']}');
      
      final chat = Chat.fromJson(chatResponse);
      final item = Item.fromJson(chatResponse['items']);
      print('📦 [ChatService] Item: ${item.title}');
      
      // Get other user profile
      final otherUserId = chat.getOtherUserId(currentUserId);
      print('👤 [ChatService] Getting profile for other user: $otherUserId');
      
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('user_id, username, avatar_url')
          .eq('user_id', otherUserId)
          .maybeSingle();
      
      UserProfile otherUser;
      if (profileResponse != null) {
        // ✨ OPTIMIZATION: Get signed URL for avatar with cache (only for storage paths)
        String? avatarUrl = profileResponse['avatar_url'] as String?;
        if (avatarUrl != null && _isStoragePath(avatarUrl)) {
          avatarUrl = await _getSignedUrlWithCache(avatarUrl, 'avatars');
          print('✅ [ChatService] Avatar URL: ${avatarUrl != null ? "created" : "not found"}');
        } else if (avatarUrl != null && avatarUrl.startsWith('http')) {
          // External URL (dicebear, etc.), use directly
          print('✅ [ChatService] Avatar URL: External URL, using directly');
        }
        
        // Update response with signed URL
        final updatedResponse = Map<String, dynamic>.from(profileResponse);
        updatedResponse['avatar_url'] = avatarUrl;
        
        otherUser = UserProfile.fromJson(updatedResponse);
      } else {
        otherUser = UserProfile(userId: otherUserId);
      }
      
      print('👤 [ChatService] Other user: ${otherUser.username ?? 'No username'}');

      // Get last message
      print('💬 [ChatService] Fetching last message...');
      final lastMessageResponse = await SupabaseConfig.client
          .from('messages')
          .select('id, content, created_at, sender_id, chat_id, status')
          .eq('chat_id', chat.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      print('💬 [ChatService] Last message response: $lastMessageResponse');
      
      Message? lastMessage;
      if (lastMessageResponse != null) {
        try {
          lastMessage = Message.fromJson(lastMessageResponse);
          print('✅ [ChatService] Last message parsed successfully');
        } catch (e) {
          print('❌ [ChatService] Error parsing last message: $e');
          print('🔍 [ChatService] Message data keys: ${lastMessageResponse.keys}');
          print('🔍 [ChatService] Message data values: ${lastMessageResponse.values}');
          lastMessage = null;
        }
      } else {
        print('ℹ️ [ChatService] No messages found in chat');
      }

      // Get unread count
      print('📊 [ChatService] Counting unread messages...');
      final unreadResponse = await SupabaseConfig.client
          .from('messages')
          .select('id')
          .eq('chat_id', chat.id)
          .neq('sender_id', currentUserId)
          .eq('status', 'sent');

      final unreadCount = unreadResponse.length;
      print('📊 [ChatService] Unread count: $unreadCount');

      // Get first photo for the item
      print('📸 [ChatService] Getting first photo for item...');
      String? firstPhotoUrl;
      try {
        final photoResponse = await SupabaseConfig.client
            .from('item_photos')
            .select('path')
            .eq('item_id', item.id)
            .order('created_at', ascending: true)
            .limit(1);
        
        print('📸 [ChatService] Photo response: $photoResponse');
        
        if (photoResponse.isNotEmpty) {
          final photoPath = photoResponse.first['path'] as String;
          print('📸 [ChatService] Getting signed URL for photo: $photoPath');
          
          // ✨ OPTIMIZATION: Use cache
          firstPhotoUrl = await _getSignedUrlWithCache(photoPath, 'item-photos');
          
          print('✅ [ChatService] Photo URL: ${firstPhotoUrl != null ? "created" : "not found"}');
        } else {
          print('⚠️ [ChatService] No photos found for item ${item.id}');
        }
      } catch (e) {
        print('❌ [ChatService] Error getting photo: $e');
        firstPhotoUrl = null;
      }

      print('✅ [ChatService] Creating ChatWithDetails object...');
      final chatWithDetails = ChatWithDetails(
        chat: chat,
        item: item,
        otherUser: otherUser,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        firstPhotoUrl: firstPhotoUrl,
      );
      
      print('✅ [ChatService] ChatWithDetails created successfully');
      return chatWithDetails;
    } catch (e) {
      throw Exception('Failed to get chat details: $e');
    }
  }

  // Delete chat (soft delete by updating status)
  Future<void> deleteChat(String chatId) async {
    try {
      await updateChatStatus(
        chatId: chatId,
        status: ChatStatus.deliveryCompleted,
      );
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Stream of chats for realtime updates
  Stream<List<ChatWithDetails>> getUserChatsStream() {
    final currentUserId = SupabaseConfig.currentUser!.id;
    
    return SupabaseConfig.client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('a_user_id', currentUserId)
        .map((data) {
      // This is a simplified version - in a real app you'd want to
      // fetch the full details for each chat
      return data.map((chat) => ChatWithDetails.fromJson(chat)).toList();
    });
  }

  /// Check if avatar URL is a storage path (not external URL)
  bool _isStoragePath(String avatarUrl) {
    // External URLs start with http/https and are not from Supabase storage
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      // Check if it's a Supabase storage URL
      if (avatarUrl.contains('supabase.co') || avatarUrl.contains('supabase.storage')) {
        // It's a Supabase storage URL, extract path
        return false; // Will be handled separately if needed
      }
      // It's an external URL (dicebear, ui-avatars, etc.)
      return false;
    }
    // It's a storage path (e.g., "avatars/userId/file.png")
    return true;
  }
}

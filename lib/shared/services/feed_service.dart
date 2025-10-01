import '../../../core/config/supabase_config.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../../features/feed/providers/feed_provider.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  // Feed item with owner information
  static FeedItem _createFeedItem(Map<String, dynamic> row) {
    // Create item from individual fields
    final item = Item(
      id: row['item_id'] as String,
      ownerId: row['owner_id'] as String,
      title: row['item_title'] as String,
      description: row['item_description'] as String?,
      status: ItemStatus.values.firstWhere(
        (v) => v.name == row['item_status'],
        orElse: () => ItemStatus.available,
      ),
      createdAt: DateTime.parse(row['item_created_at'] as String),
      updatedAt: row['item_updated_at'] != null 
          ? DateTime.parse(row['item_updated_at'] as String)
          : null,
    );

    // Create owner profile from individual fields
    final owner = UserProfile(
      userId: row['owner_id'] as String,
      username: row['owner_username'] as String?,
      avatarUrl: row['owner_avatar_url'] as String?,
      lastSeenAt: row['owner_last_seen_at'] != null 
          ? DateTime.parse(row['owner_last_seen_at'] as String)
          : null,
    );

    return FeedItem(
      item: item,
      owner: owner,
      distanceKm: (row['distance_km'] as num).toDouble(),
      firstPhotoUrl: null, // Will be set later
    );
  }

  // Get feed items within radius
  Future<List<FeedItem>> getFeedItems({
    required double radiusKm,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      print('🔍 [FeedService] Starting feed items fetch with radius: ${radiusKm}km, page: $page');
      
      // Get current user's location from profile
      final user = SupabaseConfig.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      print('👤 [FeedService] User authenticated: ${user.id}');

      // Call the RPC function with user_id (more efficient)
      print('🚀 [FeedService] Calling RPC function: feed_items_by_radius');
      
      final response = await SupabaseConfig.rpc('feed_items_by_radius', {
        'p_user_id': user.id,
        'p_radius_km': radiusKm,
        'p_page_offset': page * limit,
        'p_page_limit': limit,
      });
      
      print('📦 [FeedService] RPC response received: ${response?.length ?? 0} items');

      if (response == null || response.isEmpty) {
        print('📭 [FeedService] No items found in response');
        return [];
      }

      final feedItems = <FeedItem>[];

      for (final row in response as List) {
        try {
          print('🔄 [FeedService] Processing item: ${row['item_title'] ?? 'Unknown'}');
          
          // Get signed URL for first photo if exists
          String? firstPhotoUrl;
          if (row['first_photo_path'] != null) {
            print('📸 [FeedService] Getting signed URL for photo: ${row['first_photo_path']}');
            try {
              firstPhotoUrl = await SupabaseConfig.storage
                  .from('item-photos')
                  .createSignedUrl(row['first_photo_path'], 3600);
              print('✅ [FeedService] Photo URL created successfully');
            } catch (e) {
              print('⚠️ [FeedService] Photo not found in storage: ${row['first_photo_path']}');
              firstPhotoUrl = null; // Continue without photo
            }
          }

          final feedItem = _createFeedItem(row);
          feedItem.firstPhotoUrl = firstPhotoUrl;

          feedItems.add(feedItem);
          print('✅ [FeedService] Successfully added item: ${feedItem.item.title}');
        } catch (e) {
          print('❌ [FeedService] Error parsing feed item: $e');
          print('🔍 [FeedService] Problematic row: $row');
          continue;
        }
      }

      print('🎉 [FeedService] Successfully processed ${feedItems.length} feed items');
      return feedItems;
    } catch (e) {
      print('💥 [FeedService] Error fetching feed items: $e');
      print('🔍 [FeedService] Error type: ${e.runtimeType}');
      throw Exception('Error al cargar el feed: $e');
    }
  }



  // Record interaction (like/pass)
  Future<String?> recordInteraction({
    required String itemId,
    required String action, // 'like' or 'pass'
  }) async {
    try {
      print('🎯 [FeedService] Recording interaction: $action for item: $itemId');
      
      final user = SupabaseConfig.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Insert or update interaction
      await SupabaseConfig.from('interactions').upsert({
        'user_id': user.id,
        'item_id': itemId,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ [FeedService] Interaction recorded successfully');

      // If it's a like, create or get chat and return chatId
      if (action == 'like') {
        print('💬 [FeedService] Creating/getting chat for liked item');
        final chatId = await _createOrGetChat(itemId);
        return chatId;
      }
      
      return null; // No chat for pass action
    } catch (e) {
      print('❌ [FeedService] Error recording interaction: $e');
      throw Exception('Error al registrar la interacción: $e');
    }
  }

  // Create or get chat for a liked item
  Future<String> _createOrGetChat(String itemId) async {
    try {
      print('💬 [FeedService] Creating/getting chat for item: $itemId');
      
      final user = SupabaseConfig.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get item owner and title using RPC function (bypasses RLS)
      final itemResponse = await SupabaseConfig.client.rpc(
        'get_item_owner',
        params: {'item_id': itemId},
      );

      if (itemResponse == null || (itemResponse is List && itemResponse.isEmpty)) {
        throw Exception('Item not found');
      }

      // Handle both single result and list result
      final ownerId = itemResponse is List 
          ? itemResponse.first['owner_id'] as String
          : itemResponse['owner_id'] as String;
      final itemTitle = itemResponse is List 
          ? itemResponse.first['title'] as String
          : itemResponse['title'] as String;
      print('👤 [FeedService] Item owner: $ownerId');
      print('📦 [FeedService] Item title: $itemTitle');

      // Check if chat already exists
      final existingChat = await SupabaseConfig.from('chats')
          .select('id')
          .or('and(a_user_id.eq.${user.id},b_user_id.eq.$ownerId,item_id.eq.$itemId),and(a_user_id.eq.$ownerId,b_user_id.eq.${user.id},item_id.eq.$itemId)')
          .maybeSingle();

      if (existingChat != null) {
        print('♻️ [FeedService] Found existing chat: ${existingChat['id']}');
        return existingChat['id'] as String;
      }

      // Create new chat
      print('🆕 [FeedService] Creating new chat');
      final chatResponse = await SupabaseConfig.from('chats').insert({
        'item_id': itemId,
        'a_user_id': user.id,
        'b_user_id': ownerId,
        'status': 'coordinating',
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final chatId = chatResponse['id'] as String;
      print('✅ [FeedService] Chat created with ID: $chatId');

      // Add initial message
      await SupabaseConfig.from('messages').insert({
        'chat_id': chatId,
        'sender_id': user.id,
        'content': 'Me interesa el artículo "$itemTitle". ¿Está disponible?',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });

      print('💌 [FeedService] Initial message sent');
      return chatId;
    } catch (e) {
      print('❌ [FeedService] Error creating chat: $e');
      throw Exception('Error al crear el chat: $e');
    }
  }
}
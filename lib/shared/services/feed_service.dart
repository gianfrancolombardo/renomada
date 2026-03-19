import 'dart:typed_data';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../../features/feed/providers/feed_provider.dart';
import 'signed_url_cache.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  factory FeedService() => _instance;
  FeedService._internal();

  // Use getter to ensure proper initialization (fixes Flutter Web issues)
  SignedUrlCache get _urlCache => SignedUrlCache();

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
            distanceKm: row['distance_km'] != null ? (row['distance_km'] as num).toDouble() : null,
            firstPhotoUrl: null, // Will be set later
          );
  }

  // Get recent feed items without location filter (for users without location permission)
  // Maximum 10 items, no pagination
  Future<List<FeedItem>> getFeedItemsWithoutLocation() async {
    try {
      print('🔍 [FeedService] Starting recent feed items fetch (no location)');
      
      final user = SupabaseConfig.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      print('👤 [FeedService] User authenticated: ${user.id}');

      // Call the RPC function for recent items (no pagination, max 10)
      print('🚀 [FeedService] Calling RPC function: feed_items_recent');
      
      final response = await SupabaseConfig.rpc('feed_items_recent', {
        'p_user_id': user.id,
      });
      
      print('📦 [FeedService] RPC response received: ${response?.length ?? 0} items');

      if (response == null || response.isEmpty) {
        print('📭 [FeedService] No items found in response');
        return [];
      }

      final feedItems = <FeedItem>[];
      final List<String> photoPaths = [];
      final List<String> avatarPaths = [];
      
      final responseList = response is List ? response : (response != null ? [response] : []);
      
      for (final row in responseList) {
        if (row is! Map) continue;
        
        final photoPath = row['first_photo_path'];
        if (photoPath != null && photoPath is String && photoPath.isNotEmpty) {
          photoPaths.add(photoPath);
        }
        
        final avatarPath = row['owner_avatar_url'];
        if (avatarPath != null && avatarPath is String && _isStoragePath(avatarPath)) {
          avatarPaths.add(avatarPath);
        }
      }

      final Map<String, String> photoUrls = await _getBatchSignedUrls(photoPaths, 'item-photos');
      final Map<String, String> avatarUrls = await _getBatchSignedUrls(avatarPaths, 'avatars');

      for (final row in responseList) {
        try {
          if (row is! Map) continue;

          String? firstPhotoUrl;
          final photoPath = row['first_photo_path'];
          if (photoPath != null && photoPath is String && photoPath.isNotEmpty) {
            firstPhotoUrl = photoUrls[photoPath];
          }

          String? ownerAvatarUrl = row['owner_avatar_url'] as String?;
          if (ownerAvatarUrl != null && _isStoragePath(ownerAvatarUrl)) {
            ownerAvatarUrl = avatarUrls[ownerAvatarUrl];
          }

          // Create item (matching feed_items_by_radius structure)
          final item = Item(
            id: row['item_id'] as String,
            ownerId: row['owner_id'] as String,
            title: row['item_title'] as String,
            description: row['item_description'] as String?,
            status: ItemStatus.values.firstWhere(
              (v) => v.name == row['item_status'],
              orElse: () => ItemStatus.available,
            ),
            condition: parseItemCondition(row['item_condition'] as String?),
            exchangeType: parseExchangeType(row['item_exchange_type'] as String?),
            createdAt: DateTime.parse(row['item_created_at'] as String),
            updatedAt: row['item_updated_at'] != null 
                ? DateTime.parse(row['item_updated_at'] as String)
                : null,
          );

          final owner = UserProfile(
            userId: row['owner_id'] as String,
            username: row['owner_username'] as String?,
            avatarUrl: ownerAvatarUrl,
            lastSeenAt: row['owner_last_seen_at'] != null 
                ? DateTime.parse(row['owner_last_seen_at'] as String)
                : null,
          );

          final feedItem = FeedItem(
            item: item,
            owner: owner,
            distanceKm: row['distance_km'] != null ? (row['distance_km'] as num).toDouble() : null,
            firstPhotoUrl: firstPhotoUrl,
          );

          feedItems.add(feedItem);
        } catch (e) {
          print('❌ [FeedService] Error parsing feed item: $e');
          continue;
        }
      }

      print('🎉 [FeedService] Successfully processed ${feedItems.length} recent feed items');
      return feedItems;
    } catch (e) {
      print('💥 [FeedService] Error fetching recent feed items: $e');
      throw Exception('Error al cargar items recientes: $e');
    }
  }

  // Get feed items within radius
  Future<List<FeedItem>> getFeedItems({
    required double radiusKm,
    int page = 0,
    int limit = 10,  // ✨ Changed: Default 10 instead of 20 for better performance
  }) async {
    try {
      print('🔍 [FeedService] Starting feed items fetch with radius: ${radiusKm}km, page: $page');
      
      // Get current user's location from profile
      final user = SupabaseConfig.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      print('👤 [FeedService] User authenticated: ${user.id}');

      // Log the location actually used by the RPC: profiles.last_location.
      // feed_items_by_radius only receives p_user_id, so the backend reads last_location internally.
      try {
        final profile = await SupabaseConfig.from('profiles')
            .select('last_location')
            .eq('user_id', user.id)
            .maybeSingle();

        final raw = profile?['last_location'];
        final parsed = _parseLastLocationForLog(raw);
        if (parsed != null) {
          print('📍 [FeedService] Using profile last_location: lat=${parsed['lat']} lon=${parsed['lon']} (radius=${radiusKm}km)');
        } else if (raw != null) {
          print('📍 [FeedService] Using profile last_location (unparsed): $raw (radius=${radiusKm}km)');
        } else {
          print('📍 [FeedService] profiles.last_location is null (radius=${radiusKm}km)');
        }
      } catch (e) {
        // Logging only; don't fail the feed.
        print('⚠️ [FeedService] Could not log last_location: $e');
      }

      // Call the RPC function with user_id (more efficient)
      print('🚀 [FeedService] Calling RPC function: feed_items_by_radius');
      
      final params = <String, dynamic>{
        'p_user_id': user.id,
        'p_radius_km': radiusKm,
        'p_page_offset': page * limit,
        'p_page_limit': limit,
      };
      if (AppConstants.feedFreshnessDays != null) {
        params['p_freshness_days'] = AppConstants.feedFreshnessDays;
      }
      final response = await SupabaseConfig.rpc('feed_items_by_radius', params);
      
      print('📦 [FeedService] RPC response received: ${response?.length ?? 0} items');

      if (response == null || response.isEmpty) {
        print('📭 [FeedService] No items found in response');
        return [];
      }

      final feedItems = <FeedItem>[];

      // ✨ OPTIMIZATION: Collect all paths for batch processing
      final List<String> photoPaths = [];
      final List<String> avatarPaths = [];
      
      final responseList = response is List ? response : (response != null ? [response] : []);
      
      for (final row in responseList) {
        if (row is! Map) continue;
        
        // Collect photo paths
        final photoPath = row['first_photo_path'];
        if (photoPath != null && photoPath is String && photoPath.isNotEmpty) {
          photoPaths.add(photoPath);
        }
        
        // Collect avatar paths (only for storage paths, not external URLs)
        final avatarPath = row['owner_avatar_url'];
        if (avatarPath != null && avatarPath is String && _isStoragePath(avatarPath)) {
          avatarPaths.add(avatarPath);
        }
      }

      // ✨ OPTIMIZATION: Batch process signed URLs
      final Map<String, String> photoUrls = await _getBatchSignedUrls(photoPaths, 'item-photos');
      final Map<String, String> avatarUrls = await _getBatchSignedUrls(avatarPaths, 'avatars');

      // Process items
      for (final row in responseList) {
        try {
          if (row is! Map) {
            print('⚠️ [FeedService] Invalid row format: $row');
            continue;
          }

          print('🔄 [FeedService] Processing item: ${row['item_title'] ?? 'Unknown'}');
          
          // ✨ OPTIMIZATION: Get signed URLs from batch processing
          String? firstPhotoUrl;
          final photoPath = row['first_photo_path'];
          if (photoPath != null && photoPath is String && photoPath.isNotEmpty) {
            firstPhotoUrl = photoUrls[photoPath];
          }

          // ✨ OPTIMIZATION: Get avatar URL from batch processing or use external URL directly
          String? ownerAvatarUrl = row['owner_avatar_url'] as String?;
          if (ownerAvatarUrl != null) {
            if (_isStoragePath(ownerAvatarUrl)) {
              // It's a storage path, get signed URL from batch
              ownerAvatarUrl = avatarUrls[ownerAvatarUrl];
            }
            // If it's an external URL (dicebear.com, etc.), use it directly
          }

          // Update row with signed avatar URL before creating feed item
          final updatedRow = Map<String, dynamic>.from(row);
          updatedRow['owner_avatar_url'] = ownerAvatarUrl;

          final feedItem = _createFeedItem(updatedRow);
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

  Map<String, double>? _parseLastLocationForLog(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map) {
      final coords = raw['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lon = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        return {'lat': lat, 'lon': lon};
      }
    }

    if (raw is String) {
      // Text: POINT(lon lat) or SRID=...;POINT(lon lat)
      final match = RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)').firstMatch(raw);
      if (match != null) {
        final lon = double.tryParse(match.group(1) ?? '');
        final lat = double.tryParse(match.group(2) ?? '');
        if (lon != null && lat != null) return {'lat': lat, 'lon': lon};
      }

      // WKB/EWKB hex: endianness byte + type + srid + lon + lat (double)
      final trimmed = raw.trim();
      final isHex = RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed) && trimmed.length >= 16;
      if (isHex) {
        try {
          final bytes = <int>[];
          for (int i = 0; i < trimmed.length; i += 2) {
            bytes.add(int.parse(trimmed.substring(i, i + 2), radix: 16));
          }
          if (bytes.length < 1 + 4 + 4 + 8 + 8) return null;

          final data = ByteData.sublistView(Uint8List.fromList(bytes));
          final endianByte = data.getUint8(0);
          final littleEndian = endianByte == 1;

          // Offsets (EWKB Point): 1 byte order + 4 bytes type + 4 bytes SRID = 9 bytes header
          final lon = data.getFloat64(9, littleEndian ? Endian.little : Endian.big);
          final lat = data.getFloat64(17, littleEndian ? Endian.little : Endian.big);

          if (lat.isFinite && lon.isFinite) return {'lat': lat, 'lon': lon};
        } catch (_) {
          // best-effort logging only
        }
      }
    }

    return null;
  }

  /// ✨ OPTIMIZATION: Batch process signed URLs to reduce API calls
  Future<Map<String, String>> _getBatchSignedUrls(List<String> paths, String bucket) async {
    final Map<String, String> urlMap = {};
    
    if (paths.isEmpty) return urlMap;
    
    print('🔄 [FeedService] Processing ${paths.length} signed URLs for $bucket');
    
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
          print('⚠️ [FeedService] Failed to get signed URL for $path: $e');
          return MapEntry(path, '');
        }
      });
      
      final results = await Future.wait(futures);
      urlMap.addAll(Map.fromEntries(results));
    }
    
    print('✅ [FeedService] Generated ${urlMap.length} signed URLs');
    return urlMap;
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
        'action': action
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
        'status': 'coordinating'
      }).select('id').single();

      final chatId = chatResponse['id'] as String;
      print('✅ [FeedService] Chat created with ID: $chatId');

      // Add initial message
      await SupabaseConfig.from('messages').insert({
        'chat_id': chatId,
        'sender_id': user.id,
        'content': 'Me interesa el artículo "$itemTitle". ¿Está disponible?',
        'status': 'sent'
      });

      print('💌 [FeedService] Initial message sent');
      
      // Wait a bit to ensure the chat is fully created
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify chat exists
      final verifyChat = await SupabaseConfig.from('chats')
          .select('id')
          .eq('id', chatId)
          .maybeSingle();
      
      if (verifyChat == null) {
        print('❌ [FeedService] Chat verification failed!');
        throw Exception('Chat was not created properly');
      }
      
      print('✅ [FeedService] Chat verified successfully');
      return chatId;
    } catch (e) {
      print('❌ [FeedService] Error creating chat: $e');
      throw Exception('Error al crear el chat: $e');
    }
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
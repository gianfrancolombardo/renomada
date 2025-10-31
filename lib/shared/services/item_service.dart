import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../models/item.dart';
import 'signed_url_cache.dart';

class ItemService {
  static final ItemService _instance = ItemService._internal();
  factory ItemService() => _instance;
  ItemService._internal();

  // Use getter to ensure proper initialization (fixes Flutter Web issues)
  SignedUrlCache get _urlCache => SignedUrlCache();

  // Create new item
  Future<Item> createItem({
    required String title,
    required String description,
    required ItemCondition condition,
    required ExchangeType exchangeType,
    required List<Uint8List> photos,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final itemId = const Uuid().v4();

    try {
      // Create item record first (required for RLS policies)
      final itemData = {
        'id': itemId,
        'owner_id': user.id,
        'title': title,
        'description': description,
        'status': ItemStatus.available.name,
        'condition': itemConditionToString(condition),
        'exchange_type': exchangeTypeToString(exchangeType),
      };

      final response = await SupabaseConfig.from('items')
          .insert(itemData)
          .select()
          .single();

      // Upload photos after item is created (so RLS policies work)
      await _uploadItemPhotos(itemId, photos);

      return Item.fromJson(response);
    } catch (e) {
      print('Error creating item: $e');
      throw Exception('Error al crear el item: $e');
    }
  }

  // Upload photos for an item
  Future<List<String>> _uploadItemPhotos(String itemId, List<Uint8List> photos) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final photoUrls = <String>[];

    try {
      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        
        // Validate photo size (max 5MB)
        if (photo.length > 5 * 1024 * 1024) {
          throw Exception('La foto ${i + 1} es demasiado grande. Máximo 5MB permitido.');
        }

        final fileName = '${itemId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final filePath = 'item-photos/${user.id}/$fileName';

        // Upload photo to storage
        await SupabaseConfig.storage
            .from('item-photos')
            .uploadBinary(filePath, photo);
        
        // Create photo record in item_photos table
        final photoRecord = {
          'id': const Uuid().v4(),
          'item_id': itemId,
          'path': filePath,
          'mime_type': 'image/jpeg',
          'size_bytes': photo.length,
        };
        
        await SupabaseConfig.from('item_photos')
            .insert(photoRecord);
        
        // Get signed URL for the uploaded photo
        final photoUrl = await SupabaseConfig.storage
            .from('item-photos')
            .createSignedUrl(filePath, 3600); // 1 hour expiration
        
        photoUrls.add(photoUrl);
      }
      
      return photoUrls;
    } catch (e) {
      throw Exception('Error al subir las fotos: $e');
    }
  }

  // Get all items owned by the current user (available and exchanged)
  Future<List<Item>> getUserItems() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    try {
      print('🔍 [ItemService] Fetching all items for user: ${user.id}');
      
      // ✨ OPTIMIZATION: Try to use optimized RPC function first
      try {
        final response = await SupabaseConfig.client.rpc(
          'get_user_items_with_photos',
          params: {'p_user_id': user.id},
        );

        final itemsResponse = response is List ? response : (response != null ? [response] : []);
        
        if (itemsResponse.isEmpty) {
          print('ℹ️ [ItemService] No items found');
          return [];
        }

        // ✨ OPTIMIZATION: Collect all photo paths for batch processing
        final List<String> photoPaths = [];
        for (final itemData in itemsResponse) {
          if (itemData is Map) {
            final photoPath = itemData['first_photo_path'];
            if (photoPath != null && photoPath is String && photoPath.isNotEmpty) {
              photoPaths.add(photoPath);
            }
          }
        }

        // ✨ OPTIMIZATION: Batch process signed URLs (cache URLs for later use)
        await _getBatchSignedUrls(photoPaths, 'item-photos');

        // Process items
        final List<Item> items = [];
        for (final itemData in itemsResponse) {
          try {
            if (itemData is! Map) {
              print('⚠️ [ItemService] Invalid item data format: $itemData');
              continue;
            }

            // Convert to Map<String, dynamic> for Item.fromJson
            final itemJson = Map<String, dynamic>.from(itemData);
            // Remove first_photo_path as it's not part of Item model
            itemJson.remove('first_photo_path');

            // Build Item from RPC response
            final item = Item.fromJson(itemJson);
            
            // Photo URLs are cached and will be retrieved by ItemPhoto widget via cache
            
            items.add(item);
          } catch (e) {
            print('❌ [ItemService] Error processing item: $e');
            print('🔍 [ItemService] Item data: $itemData');
            continue;
          }
        }

        print('✅ [ItemService] Loaded ${items.length} items with optimized query');
        return items;
      } catch (rpcError) {
        print('⚠️ [ItemService] Optimized RPC not available, using fallback: $rpcError');
        // Fallback to original method
        return await _getUserItemsFallback();
      }
    } catch (e) {
      print('❌ [ItemService] Error fetching user items: $e');
      print('❌ [ItemService] Error type: ${e.runtimeType}');
      
      // If it's a connectivity issue, provide more specific error
      if (e.toString().contains('Failed to fetch') || e.toString().contains('ClientException')) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      }
      
      throw Exception('Error al cargar tus items: $e');
    }
  }

  // Fallback method using original implementation
  Future<List<Item>> _getUserItemsFallback() async {
    final user = SupabaseConfig.currentUser!;
    
    // Test basic connectivity first
    await SupabaseConfig.from('items')
        .select('id')
        .limit(1);
    print('🔍 [ItemService] Basic connectivity test passed');
    
    final response = await SupabaseConfig.from('items')
        .select('*')
        .eq('owner_id', user.id)
        .inFilter('status', [ItemStatus.available.name, ItemStatus.exchanged.name])
        .order('created_at', ascending: false);

    print('📦 [ItemService] Received ${(response as List).length} items');
    
    return (response as List).map((json) {
      try {
        return Item.fromJson(json);
      } catch (e) {
        print('❌ [ItemService] Error parsing item: $e');
        print('🔍 [ItemService] Item JSON: $json');
        rethrow;
      }
    }).toList();
  }

  // Get a single item by ID
  Future<Item?> getItemById(String itemId) async {
    try {
      final response = await SupabaseConfig.from('items')
          .select('*')
          .eq('id', itemId)
          .single();
      return Item.fromJson(response);
    } catch (e) {
      print('Error fetching item by ID: $e');
      return null;
    }
  }

  // Update an existing item
  Future<Item> updateItem(Item item) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');
    if (item.ownerId != user.id) throw Exception('Unauthorized to update this item');

    final updateData = item.toJson();
    // Remove ID and owner_id from update data as they should not change
    updateData.remove('id');
    updateData.remove('owner_id');
    updateData['updated_at'] = DateTime.now().toIso8601String();

    final response = await SupabaseConfig.from('items')
        .update(updateData)
        .eq('id', item.id)
        .select()
        .single();

    return Item.fromJson(response);
  }

  // "Delete" an item (change status to exchanged)
  Future<void> deleteItem(String itemId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await SupabaseConfig.from('items')
        .update({'status': 'exchanged'})
        .eq('id', itemId)
        .eq('owner_id', user.id); // Ensure only owner can delete
  }

  // Change item status (available, exchanged, paused)
  Future<Item> changeItemStatus(String itemId, ItemStatus newStatus) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = {
      'status': newStatus.name,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await SupabaseConfig.from('items')
        .update(updateData)
        .eq('id', itemId)
        .eq('owner_id', user.id) // Ensure only owner can change status
        .select()
        .single();

    return Item.fromJson(response);
  }

  // Actually delete an item (remove from database)
  Future<void> permanentlyDeleteItem(String itemId) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Optionally, delete associated photos from storage here
    // For now, we'll rely on RLS to prevent unauthorized deletion

    await SupabaseConfig.from('items')
        .delete()
        .eq('id', itemId)
        .eq('owner_id', user.id); // Ensure only owner can delete
  }

  // Get photos for an item
  Future<List<String>> getItemPhotos(String itemId) async {
    try {
      final response = await SupabaseConfig.from('item_photos')
          .select('path')
          .eq('item_id', itemId)
          .order('created_at', ascending: true);

      final photoPaths = <String>[];
      
      for (final photoRecord in response as List) {
        final path = photoRecord['path'] as String;
        photoPaths.add(path);
      }

      if (photoPaths.isEmpty) return [];

      // ✨ OPTIMIZATION: Batch process signed URLs
      final photoUrls = await _getBatchSignedUrls(photoPaths, 'item-photos');
      return photoUrls.values.where((url) => url.isNotEmpty).toList();
    } catch (e) {
      print('Error fetching item photos: $e');
      return [];
    }
  }

  // Get first photo URL for an item (for display in lists)
  Future<String?> getItemFirstPhoto(String itemId) async {
    try {
      // ✨ OPTIMIZATION: Get just the first photo path
      final response = await SupabaseConfig.from('item_photos')
          .select('path')
          .eq('item_id', itemId)
          .order('created_at', ascending: true)
          .limit(1);

      if (response.isEmpty) return null;

      final path = response.first['path'] as String;
      
      // ✨ OPTIMIZATION: Use cache
      return await _getSignedUrlWithCache(path, 'item-photos');
    } catch (e) {
      print('Error fetching first photo: $e');
      return null;
    }
  }

  /// ✨ OPTIMIZATION: Batch process signed URLs to reduce API calls
  Future<Map<String, String>> _getBatchSignedUrls(List<String> paths, String bucket) async {
    final Map<String, String> urlMap = {};
    
    if (paths.isEmpty) return urlMap;
    
    print('🔄 [ItemService] Processing ${paths.length} signed URLs for $bucket');
    
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
          print('⚠️ [ItemService] Failed to get signed URL for $path: $e');
          return MapEntry(path, '');
        }
      });
      
      final results = await Future.wait(futures);
      urlMap.addAll(Map.fromEntries(results));
    }
    
    print('✅ [ItemService] Generated ${urlMap.length} signed URLs');
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
      print('⚠️ [ItemService] Failed to get signed URL for $path: $e');
      return null;
    }
  }
}
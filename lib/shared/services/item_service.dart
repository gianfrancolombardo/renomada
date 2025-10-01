import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../models/item.dart';

class ItemService {
  static final ItemService _instance = ItemService._internal();
  factory ItemService() => _instance;
  ItemService._internal();

  // Create new item
  Future<Item> createItem({
    required String title,
    required String description,
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

  // Get items owned by the current user (only available ones)
  Future<List<Item>> getUserItems() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return [];

    try {
      final response = await SupabaseConfig.from('items')
          .select('*')
          .eq('owner_id', user.id)
          .eq('status', 'available') // Only show available items
          .order('created_at', ascending: false);

      return (response as List).map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user items: $e');
      throw Exception('Error al cargar tus items: $e');
    }
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

      final photoUrls = <String>[];
      
      for (final photoRecord in response as List) {
        final path = photoRecord['path'] as String;
        
        // Get signed URL for the photo
        final signedUrl = await SupabaseConfig.storage
            .from('item-photos')
            .createSignedUrl(path, 3600); // 1 hour expiration
        
        photoUrls.add(signedUrl);
      }
      
      return photoUrls;
    } catch (e) {
      print('Error fetching item photos: $e');
      return [];
    }
  }

  // Get first photo URL for an item (for display in lists)
  Future<String?> getItemFirstPhoto(String itemId) async {
    try {
      final photos = await getItemPhotos(itemId);
      return photos.isNotEmpty ? photos.first : null;
    } catch (e) {
      print('Error fetching first photo: $e');
      return null;
    }
  }
}
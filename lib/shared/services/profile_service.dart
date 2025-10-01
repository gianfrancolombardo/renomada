import 'dart:typed_data';
import 'dart:io';
import '../../core/config/supabase_config.dart';
import '../models/user_profile.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Get current user profile
  Future<UserProfile?> getCurrentProfile() async {
    final user = SupabaseConfig.currentUser;
    if (user == null) {
      print('No authenticated user found');
      return null;
    }

    try {
      print('Fetching profile for user: ${user.id}');
      final response = await SupabaseConfig.from('profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      print('Profile response: $response');
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }


  // Update profile
  Future<UserProfile> updateProfile({
    String? username,
    String? avatarUrl,
    Map<String, dynamic>? lastLocation,
    bool? isLocationOptOut,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{};
    
    if (username != null) updateData['username'] = username;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (isLocationOptOut != null) updateData['is_location_opt_out'] = isLocationOptOut;

    // Handle location separately with PostGIS conversion
    if (lastLocation != null) {
      // Convert GeoJSON to PostGIS format (longitude first, then latitude)
      final coordinates = lastLocation['coordinates'] as List<dynamic>;
      final longitude = coordinates[0] as double;
      final latitude = coordinates[1] as double;
      
      // Use PostGIS format: POINT(longitude latitude) - no comma between values
      updateData['last_location'] = 'POINT($longitude $latitude)';
      updateData['last_seen_at'] = DateTime.now().toIso8601String();
    }

    final response = await SupabaseConfig.from('profiles')
        .update(updateData)
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  // Update location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) return;

    // Round coordinates to ~50m precision for privacy
    final roundedLat = _roundCoordinate(latitude);
    final roundedLon = _roundCoordinate(longitude);

    // Create GeoJSON Point for PostGIS
    final locationData = {
      'type': 'Point',
      'coordinates': [roundedLon, roundedLat], // GeoJSON format: [longitude, latitude]
    };

    await updateProfile(
      lastLocation: locationData,
      isLocationOptOut: false,
    );
  }

  // Round coordinate to ~50m precision
  double _roundCoordinate(double coordinate) {
    // Round to ~50m precision (approximately 0.0005 degrees)
    return (coordinate * 2000).round() / 2000;
  }

  // Opt out of location sharing
  Future<void> optOutOfLocation() async {
    await updateProfile(
      lastLocation: null,
      isLocationOptOut: true,
    );
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await SupabaseConfig.from('profiles')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (e) {
      return false;
    }
  }

  // Upload avatar to storage
  Future<String> uploadAvatar(String fileName, Uint8List fileBytes) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Additional validation
    if (fileBytes.isEmpty) {
      throw Exception('El archivo está vacío');
    }

    final fullPath = 'avatars/${user.id}/$fileName';

    try {
      print('Uploading avatar to path: $fullPath, size: ${fileBytes.length} bytes');
      
      await SupabaseConfig.storage
          .from('avatars')
          .uploadBinary(fullPath, fileBytes);

      // Get signed URL for the uploaded file (bucket is private)
      final url = await SupabaseConfig.storage
          .from('avatars')
          .createSignedUrl(fullPath, 3600); // 1 hour expiration

      print('Avatar uploaded successfully: $url');
      return url;
    } catch (e) {
      print('Storage upload error: $e');
      throw Exception('Error al subir el archivo: $e');
    }
  }

  // Upload avatar from file path
  Future<UserProfile> uploadAvatarFromPath(String imagePath) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Read file bytes
    final file = File(imagePath);
    final fileBytes = await file.readAsBytes();
    
    // Validate file size (max 5MB)
    if (fileBytes.length > 5 * 1024 * 1024) {
      throw Exception('El archivo es demasiado grande. Máximo 5MB permitido.');
    }
    
    // Validate file type (check file extension)
    final fileExtension = imagePath.toLowerCase().split('.').last;
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExtensions.contains(fileExtension)) {
      throw Exception('Tipo de archivo no válido. Solo se permiten imágenes (JPG, PNG, GIF, WebP).');
    }
    
    // Generate unique filename with proper extension
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    
    // Upload avatar and get URL
    final avatarUrl = await uploadAvatar(fileName, fileBytes);
    
    // Update profile with new avatar URL
    return await updateProfile(avatarUrl: avatarUrl);
  }

  // Get signed URL for avatar (for private bucket)
  Future<String?> getAvatarSignedUrl(String? avatarUrl) async {
    if (avatarUrl == null) return null;
    
    try {
      // Check if it's an external URL (like ui-avatars.com)
      if (avatarUrl.startsWith('http') && !avatarUrl.contains('supabase.co')) {
        print('External avatar URL, no need to sign: $avatarUrl');
        return avatarUrl; // Return as-is for external URLs
      }
      
      // Extract file path from the stored URL
      // URL format: https://project.supabase.co/storage/v1/object/sign/avatars/path/file.ext?token=...
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the path after 'avatars' bucket
      final avatarsIndex = pathSegments.indexOf('avatars');
      if (avatarsIndex == -1 || avatarsIndex + 1 >= pathSegments.length) {
        print('Invalid avatar URL format: $avatarUrl');
        return null;
      }
      
      // Reconstruct the file path
      final filePath = pathSegments.sublist(avatarsIndex + 1).join('/');
      
      // Get signed URL
      final signedUrl = await SupabaseConfig.storage
          .from('avatars')
          .createSignedUrl(filePath, 3600); // 1 hour expiration
      
      return signedUrl;
    } catch (e) {
      print('Error getting signed URL for avatar: $e');
      return null;
    }
  }

  // Upload avatar from bytes (for web compatibility)
  Future<UserProfile> uploadAvatarFromBytes(Uint8List fileBytes, String fileName) async {
    final user = SupabaseConfig.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate file size (max 5MB)
    if (fileBytes.length > 5 * 1024 * 1024) {
      throw Exception('El archivo es demasiado grande. Máximo 5MB permitido.');
    }
    
    // Validate file type (check file extension)
    final fileExtension = fileName.toLowerCase().split('.').last;
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExtensions.contains(fileExtension)) {
      throw Exception('Tipo de archivo no válido. Solo se permiten imágenes (JPG, PNG, GIF, WebP).');
    }
    
    // Generate unique filename with proper extension
    final uniqueFileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    
    // Upload avatar and get URL
    final avatarUrl = await uploadAvatar(uniqueFileName, fileBytes);
    
    // Update profile with new avatar URL
    return await updateProfile(avatarUrl: avatarUrl);
  }

  // Delete avatar
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      final filePath = 'avatars/${pathSegments[pathSegments.length - 2]}/$fileName';

      await SupabaseConfig.storage
          .from('avatars')
          .remove([filePath]);
    } catch (e) {
      // Ignore errors when deleting avatar
    }
  }
}

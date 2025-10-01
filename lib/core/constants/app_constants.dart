class AppConstants {
  // App Information
  static const String appName = 'ReNomada';
  static const String appVersion = '0.1.0';
  
  // Location & Radius
  static const double defaultSearchRadiusKm = 10.0;
  static const double minSearchRadiusKm = 1.0;
  static const double maxSearchRadiusKm = 50.0;
  static const int locationFreshnessHours = 24;
  
  // Image Constraints
  static const int maxPhotosPerItem = 3;
  static const int maxPhotoSizeBytes = 2 * 1024 * 1024; // 2MB
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/png', 'image/webp'];
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Storage
  static const String itemPhotosBucket = 'item-photos';
  
  // Rate Limits
  static const int maxItemsPerDay = 10;
  static const int maxMessagesPerMinute = 10;
}

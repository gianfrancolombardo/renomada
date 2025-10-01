import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  Future<LocationPermissionStatus> checkLocationPermission() async {
    final permission = await Permission.location.status;
    
    switch (permission) {
      case PermissionStatus.granted:
        return LocationPermissionStatus.granted;
      case PermissionStatus.denied:
        return LocationPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return LocationPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return LocationPermissionStatus.restricted;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  // Request location permission
  Future<LocationPermissionStatus> requestLocationPermission() async {
    final permission = await Permission.location.request();
    
    switch (permission) {
      case PermissionStatus.granted:
        return LocationPermissionStatus.granted;
      case PermissionStatus.denied:
        return LocationPermissionStatus.denied;
      case PermissionStatus.permanentlyDenied:
        return LocationPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return LocationPermissionStatus.restricted;
      default:
        return LocationPermissionStatus.denied;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check permission
      final permission = await checkLocationPermission();
      if (permission != LocationPermissionStatus.granted) {
        throw Exception('Location permission not granted');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  // Get location with high accuracy (for when user grants permission)
  Future<Position?> getHighAccuracyLocation() async {
    try {
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        throw Exception('Location services are disabled');
      }

      final permission = await checkLocationPermission();
      if (permission != LocationPermissionStatus.granted) {
        throw Exception('Location permission not granted');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Check if we can request permission (not permanently denied)
  Future<bool> canRequestPermission() async {
    final permission = await checkLocationPermission();
    return permission != LocationPermissionStatus.permanentlyDenied;
  }

  // Get user-friendly permission status message
  String getPermissionStatusMessage(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return 'Permiso de ubicación concedido';
      case LocationPermissionStatus.denied:
        return 'Permiso de ubicación denegado';
      case LocationPermissionStatus.permanentlyDenied:
        return 'Permiso de ubicación denegado permanentemente. Ve a configuración para habilitarlo.';
      case LocationPermissionStatus.restricted:
        return 'Permiso de ubicación restringido';
    }
  }

  // Calculate distance between two points in meters
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Check if location is within radius
  bool isWithinRadius(
    double userLat, double userLon,
    double targetLat, double targetLon,
    double radiusKm,
  ) {
    final distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= (radiusKm * 1000);
  }

  // Get location status for debugging
  Future<Map<String, dynamic>> getLocationStatus() async {
    final isEnabled = await isLocationServiceEnabled();
    final permission = await checkLocationPermission();
    final position = await getCurrentLocation();

    return {
      'isLocationServiceEnabled': isEnabled,
      'permissionStatus': permission.toString(),
      'hasCurrentLocation': position != null,
      'currentPosition': position != null ? {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp,
      } : null,
    };
  }
}

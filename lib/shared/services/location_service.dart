import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'location_log_service.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

// Custom exception for location errors
class LocationException implements Exception {
  final String message;
  final String code;
  
  LocationException(this.message, this.code);
  
  @override
  String toString() => message;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final LocationLogService _logService = LocationLogService();
  LocationPermissionStatus? _lastKnownPermissionStatus;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      await _logService.logGpsCheck(isEnabled);
      return isEnabled;
    } catch (e) {
      await _logService.logGpsCheck(false);
      return false;
    }
  }

  // Check location permission status
  Future<LocationPermissionStatus> checkLocationPermission() async {
    try {
      final permission = await permission_handler.Permission.location.status;
      LocationPermissionStatus status;
      
      switch (permission) {
        case permission_handler.PermissionStatus.granted:
          status = LocationPermissionStatus.granted;
          break;
        case permission_handler.PermissionStatus.denied:
          status = LocationPermissionStatus.denied;
          break;
        case permission_handler.PermissionStatus.permanentlyDenied:
          status = LocationPermissionStatus.permanentlyDenied;
          break;
        case permission_handler.PermissionStatus.restricted:
          status = LocationPermissionStatus.restricted;
          break;
        case permission_handler.PermissionStatus.limited:
          // iOS "While Using App" - treat as granted for our purposes
          status = LocationPermissionStatus.granted;
          break;
        default:
          status = LocationPermissionStatus.denied;
      }
      
      // Log permission check
      await _logService.logPermissionCheck(status);
      
      // Detect permission changes
      if (_lastKnownPermissionStatus != null && 
          _lastKnownPermissionStatus != status) {
        await _logService.logEvent(
          eventType: LocationEventType.permissionChanged,
          action: LocationAction.checkPermission,
          permissionStatus: status,
          metadata: {
            'previous_status': _permissionStatusToString(_lastKnownPermissionStatus!),
            'new_status': _permissionStatusToString(status),
          },
        );
      }
      
      _lastKnownPermissionStatus = status;
      return status;
    } catch (e) {
      await _logService.logEvent(
        eventType: LocationEventType.permissionCheck,
        action: LocationAction.checkPermission,
        errorCode: 'check_failed',
        errorMessage: e.toString(),
      );
      return LocationPermissionStatus.denied;
    }
  }
  
  String _permissionStatusToString(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.granted:
        return 'granted';
      case LocationPermissionStatus.denied:
        return 'denied';
      case LocationPermissionStatus.permanentlyDenied:
        return 'permanently_denied';
      case LocationPermissionStatus.restricted:
        return 'restricted';
    }
  }

  // Request location permission
  Future<LocationPermissionStatus> requestLocationPermission() async {
    try {
      final permission = await permission_handler.Permission.location.request();
      LocationPermissionStatus status;
      
      switch (permission) {
        case permission_handler.PermissionStatus.granted:
          status = LocationPermissionStatus.granted;
          break;
        case permission_handler.PermissionStatus.denied:
          status = LocationPermissionStatus.denied;
          break;
        case permission_handler.PermissionStatus.permanentlyDenied:
          status = LocationPermissionStatus.permanentlyDenied;
          break;
        case permission_handler.PermissionStatus.restricted:
          status = LocationPermissionStatus.restricted;
          break;
        case permission_handler.PermissionStatus.limited:
          // iOS "While Using App" - treat as granted
          status = LocationPermissionStatus.granted;
          await _logService.logEvent(
            eventType: LocationEventType.permissionLimited,
            action: LocationAction.requestPermission,
            permissionStatus: status,
          );
          break;
        default:
          status = LocationPermissionStatus.denied;
      }
      
      // Log permission request result
      await _logService.logPermissionRequest(status);
      
      _lastKnownPermissionStatus = status;
      return status;
    } catch (e) {
      await _logService.logEvent(
        eventType: LocationEventType.permissionDenied,
        action: LocationAction.requestPermission,
        errorCode: 'request_failed',
        errorMessage: e.toString(),
      );
      return LocationPermissionStatus.denied;
    }
  }

  // Get current location
  Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Log location request
      await _logService.logLocationRequest(
        accuracy: accuracy,
        timeout: timeout,
      );
      
      // Check if location services are enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        await _logService.logLocationError(
          errorCode: 'gps_disabled',
          errorMessage: 'Location services are disabled',
          errorDetails: {'action': 'get_current_location'},
        );
        throw LocationException('GPS disabled', 'gps_disabled');
      }

      // Check permission
      final permission = await checkLocationPermission();
      if (permission != LocationPermissionStatus.granted) {
        await _logService.logLocationError(
          errorCode: 'permission_denied',
          errorMessage: 'Location permission not granted',
          errorDetails: {
            'permission_status': _permissionStatusToString(permission),
            'action': 'get_current_location',
          },
        );
        throw LocationException('Permission denied', 'permission_denied');
      }

      // Get current position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: timeout,
        );
      } on TimeoutException {
        await _logService.logLocationError(
          errorCode: 'timeout',
          errorMessage: 'Location request timed out',
          errorDetails: {
            'timeout_seconds': timeout.inSeconds,
            'accuracy': accuracy.toString(),
          },
        );
        throw LocationException('Location timeout', 'timeout');
      } catch (e) {
        // Check if it's a location service error
        if (e.toString().contains('location service') || 
            e.toString().contains('GPS')) {
          await _logService.logLocationError(
            errorCode: 'gps_error',
            errorMessage: e.toString(),
            errorDetails: {'action': 'get_current_location'},
          );
          throw LocationException('GPS error', 'gps_error');
        }
        rethrow;
      }

      // Check accuracy
      if (position.accuracy > 100) {
        await _logService.logEvent(
          eventType: LocationEventType.locationLowAccuracy,
          action: LocationAction.getLocation,
          position: position,
          metadata: {
            'accuracy_meters': position.accuracy,
            'threshold_meters': 100,
          },
        );
      }

      // Log success
      await _logService.logLocationSuccess(position);
      
      return position;
    } on LocationException {
      rethrow;
    } catch (e) {
      await _logService.logLocationError(
        errorCode: 'unknown_error',
        errorMessage: e.toString(),
        errorDetails: {
          'error_type': e.runtimeType.toString(),
          'action': 'get_current_location',
        },
      );
      return null;
    }
  }

  // Get location with high accuracy (for when user grants permission)
  Future<Position?> getHighAccuracyLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return await getCurrentLocation(
      accuracy: LocationAccuracy.high,
      timeout: timeout,
    );
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    try {
      await _logService.logSettingsOpened('location');
      await Geolocator.openLocationSettings();
    } catch (e) {
      await _logService.logEvent(
        eventType: LocationEventType.locationSettingsOpened,
        action: LocationAction.openLocationSettings,
        errorCode: 'open_failed',
        errorMessage: e.toString(),
      );
    }
  }

  // Open app settings
  // Returns true if permission was granted, false otherwise
  Future<bool> openAppSettings() async {
    try {
      await _logService.logSettingsOpened('app');
      
      // On web, openAppSettings() doesn't work - permissions are handled by the browser
      // Instead, we'll try to request permission directly
      if (kIsWeb) {
        // Check current permission status first
        final currentPermission = await checkLocationPermission();
        
        // On web, try to request permission directly
        // The browser will show its own permission prompt
        final permission = await requestLocationPermission();
        
        if (permission == LocationPermissionStatus.granted) {
          return true;
        }
        
        // If still denied, log that user needs to change browser settings manually
        await _logService.logEvent(
          eventType: LocationEventType.appSettingsOpened,
          action: LocationAction.openAppSettings,
          errorCode: 'web_permission_denied',
          errorMessage: 'On web, users must grant location permission through browser settings',
          metadata: {
            'platform': 'web',
            'previous_status': _permissionStatusToString(currentPermission),
            'new_status': _permissionStatusToString(permission),
            'note': 'Browser settings must be changed manually - no programmatic way to open them',
          },
        );
        
        // Return false to indicate permission was not granted
        return false;
      }
      
      // On Android/iOS, use the function from permission_handler package
      await permission_handler.openAppSettings();
      // On native platforms, we can't know if user granted permission until they return
      // So we return false and let the app check when user returns
      return false;
    } catch (e) {
      await _logService.logEvent(
        eventType: LocationEventType.appSettingsOpened,
        action: LocationAction.openAppSettings,
        errorCode: 'open_failed',
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Get browser-specific instructions for enabling location permission
  String getWebBrowserInstructions() {
    if (!kIsWeb) return '';
    
    // Provide instructions that work for most browsers
    return 'Para habilitar la ubicación en tu navegador:\n\n'
        '1. Busca el ícono de candado o información en la barra de direcciones\n'
        '2. Haz clic en "Configuración del sitio" o "Site settings"\n'
        '3. Busca "Ubicación" o "Location"\n'
        '4. Selecciona "Permitir" o "Allow"\n'
        '5. Recarga la página\n\n'
        'En Chrome móvil: Menú (⋮) → Configuración → Configuración del sitio → Ubicación\n'
        'En Safari móvil: Configuración → Safari → Ubicación';
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
    try {
      final isEnabled = await isLocationServiceEnabled();
      final permission = await checkLocationPermission();
      Position? position;
      
      if (permission == LocationPermissionStatus.granted && isEnabled) {
        try {
          position = await getCurrentLocation();
        } catch (e) {
          // Ignore errors when getting status
        }
      }

      final status = {
        'isLocationServiceEnabled': isEnabled,
        'permissionStatus': _permissionStatusToString(permission),
        'hasCurrentLocation': position != null,
        'currentPosition': position != null ? {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp.toIso8601String(),
        } : null,
      };
      
      // Log status check
      await _logService.logEvent(
        eventType: LocationEventType.refresh,
        action: LocationAction.refresh,
        permissionStatus: permission,
        gpsEnabled: isEnabled,
        locationObtained: position != null,
        metadata: status,
      );
      
      return status;
    } catch (e) {
      await _logService.logEvent(
        eventType: LocationEventType.refresh,
        action: LocationAction.refresh,
        errorCode: 'status_check_failed',
        errorMessage: e.toString(),
      );
      return {
        'error': e.toString(),
      };
    }
  }
  
  // Monitor permission changes (useful for detecting when user changes settings)
  Stream<LocationPermissionStatus> watchPermissionStatus() async* {
    LocationPermissionStatus? lastStatus;
    
    while (true) {
      final currentStatus = await checkLocationPermission();
      
      if (lastStatus != null && lastStatus != currentStatus) {
        yield currentStatus;
      }
      
      lastStatus = currentStatus;
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}

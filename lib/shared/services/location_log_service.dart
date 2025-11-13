import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../../core/config/supabase_config.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

enum LocationEventType {
  // Permission events
  permissionCheck,
  permissionRequest,
  permissionGranted,
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
  permissionLimited, // iOS only - "While Using App"
  permissionChanged,
  
  // GPS/Service events
  gpsCheck,
  gpsDisabled,
  gpsEnabled,
  
  // Location events
  locationRequest,
  locationSuccess,
  locationError,
  locationTimeout,
  locationLowAccuracy,
  
  // User actions
  settingsOpened,
  appSettingsOpened,
  locationSettingsOpened,
  skipLocation,
  
  // System events
  initialize,
  refresh,
  permissionStatusChanged,
}

enum LocationAction {
  checkPermission,
  requestPermission,
  getLocation,
  getHighAccuracyLocation,
  openSettings,
  openAppSettings,
  openLocationSettings,
  initialize,
  refresh,
  skip,
}

class LocationLogService {
  static final LocationLogService _instance = LocationLogService._internal();
  factory LocationLogService() => _instance;
  LocationLogService._internal();

  String? _currentSessionId;
  
  // Get or create session ID
  String get sessionId {
    _currentSessionId ??= _generateSessionId();
    return _currentSessionId!;
  }
  
  // Generate unique session ID
  String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
  }
  
  // Start new session (call when user starts location flow)
  void startNewSession() {
    _currentSessionId = _generateSessionId();
  }
  
  // Get platform name
  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
  
  // Log location event
  Future<void> logEvent({
    required LocationEventType eventType,
    required LocationAction action,
    LocationPermissionStatus? permissionStatus,
    bool? gpsEnabled,
    bool? locationObtained,
    Position? position,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? errorDetails,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Don't log if user is not authenticated
      if (!SupabaseConfig.isAuthenticated) {
        return;
      }
      
      final user = SupabaseConfig.currentUser;
      if (user == null) return;
      
      // Prepare log data
      final logData = <String, dynamic>{
        'user_id': user.id,
        'event_type': _eventTypeToString(eventType),
        'action': _actionToString(action),
        'session_id': sessionId,
        'platform': _platform,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Add permission status
      if (permissionStatus != null) {
        logData['permission_status'] = _permissionStatusToString(permissionStatus);
      }
      
      // Add GPS status
      if (gpsEnabled != null) {
        logData['gps_enabled'] = gpsEnabled;
      }
      
      // Add location obtained flag
      if (locationObtained != null) {
        logData['location_obtained'] = locationObtained;
      }
      
      // Add position data if available
      if (position != null) {
        logData['latitude'] = position.latitude;
        logData['longitude'] = position.longitude;
        logData['accuracy'] = position.accuracy;
        logData['altitude'] = position.altitude;
        logData['heading'] = position.heading;
        logData['speed'] = position.speed;
        logData['location_obtained'] = true;
      }
      
      // Add error information
      if (errorCode != null) {
        logData['error_code'] = errorCode;
      }
      if (errorMessage != null) {
        logData['error_message'] = errorMessage;
      }
      if (errorDetails != null && errorDetails.isNotEmpty) {
        logData['error_details'] = errorDetails;
      }
      
      // Add metadata
      if (metadata != null && metadata.isNotEmpty) {
        logData['metadata'] = metadata;
      }
      
      // Insert log (fire and forget - don't block on errors)
      SupabaseConfig.from('location_logs').insert(logData).then(
        (_) => null,
        onError: (error) {
          // Silently fail - we don't want logging errors to break the app
          if (kDebugMode) {
            print('Failed to log location event: $error');
          }
        },
      );
    } catch (e) {
      // Silently fail - logging should never break the app
      if (kDebugMode) {
        print('Error logging location event: $e');
      }
    }
  }
  
  // Helper methods to convert enums to strings
  String _eventTypeToString(LocationEventType type) {
    switch (type) {
      case LocationEventType.permissionCheck:
        return 'permission_check';
      case LocationEventType.permissionRequest:
        return 'permission_request';
      case LocationEventType.permissionGranted:
        return 'permission_granted';
      case LocationEventType.permissionDenied:
        return 'permission_denied';
      case LocationEventType.permissionPermanentlyDenied:
        return 'permission_permanently_denied';
      case LocationEventType.permissionRestricted:
        return 'permission_restricted';
      case LocationEventType.permissionLimited:
        return 'permission_limited';
      case LocationEventType.permissionChanged:
        return 'permission_changed';
      case LocationEventType.gpsCheck:
        return 'gps_check';
      case LocationEventType.gpsDisabled:
        return 'gps_disabled';
      case LocationEventType.gpsEnabled:
        return 'gps_enabled';
      case LocationEventType.locationRequest:
        return 'location_request';
      case LocationEventType.locationSuccess:
        return 'location_success';
      case LocationEventType.locationError:
        return 'location_error';
      case LocationEventType.locationTimeout:
        return 'location_timeout';
      case LocationEventType.locationLowAccuracy:
        return 'location_low_accuracy';
      case LocationEventType.settingsOpened:
        return 'settings_opened';
      case LocationEventType.appSettingsOpened:
        return 'app_settings_opened';
      case LocationEventType.locationSettingsOpened:
        return 'location_settings_opened';
      case LocationEventType.skipLocation:
        return 'skip_location';
      case LocationEventType.initialize:
        return 'initialize';
      case LocationEventType.refresh:
        return 'refresh';
      case LocationEventType.permissionStatusChanged:
        return 'permission_status_changed';
    }
  }
  
  String _actionToString(LocationAction action) {
    switch (action) {
      case LocationAction.checkPermission:
        return 'check_permission';
      case LocationAction.requestPermission:
        return 'request_permission';
      case LocationAction.getLocation:
        return 'get_location';
      case LocationAction.getHighAccuracyLocation:
        return 'get_high_accuracy_location';
      case LocationAction.openSettings:
        return 'open_settings';
      case LocationAction.openAppSettings:
        return 'open_app_settings';
      case LocationAction.openLocationSettings:
        return 'open_location_settings';
      case LocationAction.initialize:
        return 'initialize';
      case LocationAction.refresh:
        return 'refresh';
      case LocationAction.skip:
        return 'skip';
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
  
  // Convenience methods for common logging scenarios
  Future<void> logPermissionCheck(LocationPermissionStatus status) async {
    await logEvent(
      eventType: LocationEventType.permissionCheck,
      action: LocationAction.checkPermission,
      permissionStatus: status,
    );
  }
  
  Future<void> logPermissionRequest(LocationPermissionStatus status) async {
    await logEvent(
      eventType: status == LocationPermissionStatus.granted
          ? LocationEventType.permissionGranted
          : status == LocationPermissionStatus.permanentlyDenied
              ? LocationEventType.permissionPermanentlyDenied
              : status == LocationPermissionStatus.restricted
                  ? LocationEventType.permissionRestricted
                  : LocationEventType.permissionDenied,
      action: LocationAction.requestPermission,
      permissionStatus: status,
    );
  }
  
  Future<void> logGpsCheck(bool enabled) async {
    await logEvent(
      eventType: enabled ? LocationEventType.gpsEnabled : LocationEventType.gpsDisabled,
      action: LocationAction.checkPermission,
      gpsEnabled: enabled,
    );
  }
  
  Future<void> logLocationRequest({
    LocationAccuracy? accuracy,
    Duration? timeout,
  }) async {
    await logEvent(
      eventType: LocationEventType.locationRequest,
      action: accuracy == LocationAccuracy.high 
          ? LocationAction.getHighAccuracyLocation 
          : LocationAction.getLocation,
      metadata: {
        'accuracy': accuracy?.toString(),
        'timeout_seconds': timeout?.inSeconds,
      },
    );
  }
  
  Future<void> logLocationSuccess(Position position) async {
    await logEvent(
      eventType: LocationEventType.locationSuccess,
      action: LocationAction.getLocation,
      locationObtained: true,
      position: position,
      metadata: {
        'accuracy_meters': position.accuracy,
      },
    );
  }
  
  Future<void> logLocationError({
    required String errorCode,
    required String errorMessage,
    Map<String, dynamic>? errorDetails,
  }) async {
    LocationEventType eventType;
    switch (errorCode) {
      case 'timeout':
        eventType = LocationEventType.locationTimeout;
        break;
      case 'gps_disabled':
        eventType = LocationEventType.gpsDisabled;
        break;
      case 'low_accuracy':
        eventType = LocationEventType.locationLowAccuracy;
        break;
      default:
        eventType = LocationEventType.locationError;
    }
    
    await logEvent(
      eventType: eventType,
      action: LocationAction.getLocation,
      locationObtained: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      errorDetails: errorDetails,
    );
  }
  
  Future<void> logSettingsOpened(String settingsType) async {
    LocationEventType eventType;
    LocationAction action;
    
    switch (settingsType) {
      case 'app':
        eventType = LocationEventType.appSettingsOpened;
        action = LocationAction.openAppSettings;
        break;
      case 'location':
        eventType = LocationEventType.locationSettingsOpened;
        action = LocationAction.openLocationSettings;
        break;
      default:
        eventType = LocationEventType.settingsOpened;
        action = LocationAction.openSettings;
    }
    
    await logEvent(
      eventType: eventType,
      action: action,
    );
  }
  
  Future<void> logSkipLocation() async {
    await logEvent(
      eventType: LocationEventType.skipLocation,
      action: LocationAction.skip,
    );
  }
  
  Future<void> logInitialize(LocationPermissionStatus? permissionStatus) async {
    await logEvent(
      eventType: LocationEventType.initialize,
      action: LocationAction.initialize,
      permissionStatus: permissionStatus,
    );
  }
}


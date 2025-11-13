import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/profile_service.dart';
import '../../../shared/services/location_log_service.dart';

// Location state
class LocationState {
  final Position? currentPosition;
  final bool isLoading;
  final String? error;
  final LocationPermissionStatus permissionStatus;
  final bool hasRequestedPermission;

  const LocationState({
    this.currentPosition,
    this.isLoading = false,
    this.error,
    this.permissionStatus = LocationPermissionStatus.denied,
    this.hasRequestedPermission = false,
  });

  LocationState copyWith({
    Position? currentPosition,
    bool? isLoading,
    String? error,
    LocationPermissionStatus? permissionStatus,
    bool? hasRequestedPermission,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      hasRequestedPermission: hasRequestedPermission ?? this.hasRequestedPermission,
    );
  }

  bool get hasLocation => currentPosition != null;
  bool get isPermissionGranted => permissionStatus == LocationPermissionStatus.granted;
  bool get canRequestPermission => !hasRequestedPermission && permissionStatus != LocationPermissionStatus.permanentlyDenied;
}

// Location notifier
class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState()) {
    _initializeLocation();
  }

  final LocationService _locationService = LocationService();
  final ProfileService _profileService = ProfileService();
  final LocationLogService _logService = LocationLogService();

  // Initialize location status
  Future<void> _initializeLocation() async {
    try {
      _logService.startNewSession();
      final permission = await _locationService.checkLocationPermission();
      await _logService.logInitialize(permission);
      state = state.copyWith(permissionStatus: permission);
    } catch (e) {
      await _logService.logEvent(
        eventType: LocationEventType.initialize,
        action: LocationAction.initialize,
        errorCode: 'init_failed',
        errorMessage: e.toString(),
      );
    }
  }

  // Request location permission and get location
  Future<bool> requestLocationPermission() async {
    try {
      _logService.startNewSession(); // Start new session for this flow
      state = state.copyWith(isLoading: true, error: null);

      // Check GPS first
      final isGpsEnabled = await _locationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: 'El GPS está desactivado. Por favor, actívalo en la configuración.',
        );
        return false;
      }

      // Request permission
      final permission = await _locationService.requestLocationPermission();
      state = state.copyWith(
        permissionStatus: permission,
        hasRequestedPermission: true,
      );

      if (permission == LocationPermissionStatus.granted) {
        // Get current location
        Position? position;
        try {
          position = await _locationService.getHighAccuracyLocation();
        } on LocationException catch (e) {
          // Handle specific location errors
          String errorMessage;
          switch (e.code) {
            case 'gps_disabled':
              errorMessage = 'El GPS está desactivado. Por favor, actívalo en la configuración.';
              break;
            case 'permission_denied':
              errorMessage = 'Permiso de ubicación denegado.';
              break;
            case 'timeout':
              errorMessage = 'Tiempo de espera agotado. Intenta de nuevo en un lugar con mejor señal.';
              break;
            case 'gps_error':
              errorMessage = 'Error al obtener la ubicación. Verifica que el GPS esté activado.';
              break;
            default:
              errorMessage = 'No se pudo obtener la ubicación: ${e.message}';
          }
          
          state = state.copyWith(
            isLoading: false,
            error: errorMessage,
          );
          return false;
        } catch (e) {
          await _logService.logLocationError(
            errorCode: 'unknown_error',
            errorMessage: e.toString(),
            errorDetails: {'action': 'request_location_permission'},
          );
          
          state = state.copyWith(
            isLoading: false,
            error: 'Error al obtener ubicación: ${e.toString()}',
          );
          return false;
        }
        
        if (position != null) {
          state = state.copyWith(
            currentPosition: position,
            isLoading: false,
            error: null,
          );

          // Update location in profile
          final updateSuccess = await _updateProfileLocation(position);
          if (!updateSuccess) {
            // Location obtained but failed to save - log it but don't fail the operation
            await _logService.logEvent(
              eventType: LocationEventType.locationSuccess,
              action: LocationAction.getHighAccuracyLocation,
              position: position,
              errorCode: 'save_failed',
              errorMessage: 'Location obtained but failed to save to profile',
            );
          }
          
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'No se pudo obtener la ubicación actual',
          );
          return false;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _locationService.getPermissionStatusMessage(permission),
        );
        return false;
      }
    } catch (e) {
      await _logService.logLocationError(
        errorCode: 'request_permission_failed',
        errorMessage: e.toString(),
        errorDetails: {'action': 'request_location_permission'},
      );
      
      state = state.copyWith(
        isLoading: false,
        error: 'Error al obtener ubicación: ${e.toString()}',
      );
      return false;
    }
  }

  // Get current location (if permission is already granted)
  Future<bool> getCurrentLocation() async {
    try {
      if (!state.isPermissionGranted) {
        await _logService.logEvent(
          eventType: LocationEventType.permissionDenied,
          action: LocationAction.getLocation,
          permissionStatus: state.permissionStatus,
          errorCode: 'permission_not_granted',
          errorMessage: 'Permission not granted',
        );
        state = state.copyWith(error: 'Permiso de ubicación no concedido');
        return false;
      }

      state = state.copyWith(isLoading: true, error: null);

      // Check GPS first
      final isGpsEnabled = await _locationService.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: 'El GPS está desactivado. Por favor, actívalo en la configuración.',
        );
        return false;
      }

      Position? position;
      try {
        position = await _locationService.getCurrentLocation();
      } on LocationException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'gps_disabled':
            errorMessage = 'El GPS está desactivado. Por favor, actívalo en la configuración.';
            break;
          case 'permission_denied':
            errorMessage = 'Permiso de ubicación denegado.';
            break;
          case 'timeout':
            errorMessage = 'Tiempo de espera agotado. Intenta de nuevo en un lugar con mejor señal.';
            break;
          case 'gps_error':
            errorMessage = 'Error al obtener la ubicación. Verifica que el GPS esté activado.';
            break;
          default:
            errorMessage = 'No se pudo obtener la ubicación: ${e.message}';
        }
        
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
        return false;
      } catch (e) {
        await _logService.logLocationError(
          errorCode: 'unknown_error',
          errorMessage: e.toString(),
          errorDetails: {'action': 'get_current_location'},
        );
        
        state = state.copyWith(
          isLoading: false,
          error: 'Error al obtener ubicación: ${e.toString()}',
        );
        return false;
      }
      
      if (position != null) {
        state = state.copyWith(
          currentPosition: position,
          isLoading: false,
          error: null,
        );

        // Update location in profile
        final updateSuccess = await _updateProfileLocation(position);
        if (!updateSuccess) {
          // Location obtained but failed to save - log it
          await _logService.logEvent(
            eventType: LocationEventType.locationSuccess,
            action: LocationAction.getLocation,
            position: position,
            errorCode: 'save_failed',
            errorMessage: 'Location obtained but failed to save to profile',
          );
        }
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo obtener la ubicación actual',
        );
        return false;
      }
    } catch (e) {
      await _logService.logLocationError(
        errorCode: 'get_location_failed',
        errorMessage: e.toString(),
        errorDetails: {'action': 'get_current_location'},
      );
      
      state = state.copyWith(
        isLoading: false,
        error: 'Error al obtener ubicación: ${e.toString()}',
      );
      return false;
    }
  }

  // Update location in profile
  Future<bool> _updateProfileLocation(Position position) async {
    try {
      await _profileService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      await _logService.logEvent(
        eventType: LocationEventType.locationSuccess,
        action: LocationAction.getLocation,
        position: position,
        metadata: {'saved_to_profile': true},
      );
      
      return true;
    } catch (e) {
      // Log error but don't update state - location was obtained successfully
      await _logService.logEvent(
        eventType: LocationEventType.locationSuccess,
        action: LocationAction.getLocation,
        position: position,
        errorCode: 'save_failed',
        errorMessage: e.toString(),
        errorDetails: {'action': 'update_profile_location'},
      );
      return false;
    }
  }

  // Check if location is fresh (within last hour)
  bool isLocationFresh() {
    if (state.currentPosition == null) return false;
    
    final now = DateTime.now();
    final locationTime = state.currentPosition!.timestamp;
    final difference = now.difference(locationTime);
    
    return difference.inHours < 24; // 24 hours freshness
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  // Get distance to a point
  double getDistanceTo(double latitude, double longitude) {
    if (state.currentPosition == null) return 0.0;
    
    return _locationService.calculateDistance(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  // Check if point is within radius
  bool isWithinRadius(double latitude, double longitude, double radiusKm) {
    if (state.currentPosition == null) return false;
    
    return _locationService.isWithinRadius(
      state.currentPosition!.latitude,
      state.currentPosition!.longitude,
      latitude,
      longitude,
      radiusKm,
    );
  }
}

// Providers
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});

// Convenience providers
final currentLocationProvider = Provider<Position?>((ref) {
  return ref.watch(locationProvider).currentPosition;
});

final locationPermissionProvider = Provider<LocationPermissionStatus>((ref) {
  return ref.watch(locationProvider).permissionStatus;
});

final hasLocationProvider = Provider<bool>((ref) {
  return ref.watch(locationProvider).hasLocation;
});

final isLocationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(locationProvider).isLoading;
});

final locationErrorProvider = Provider<String?>((ref) {
  return ref.watch(locationProvider).error;
});

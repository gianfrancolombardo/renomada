import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/profile_service.dart';

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

  // Initialize location status
  Future<void> _initializeLocation() async {
    final permission = await _locationService.checkLocationPermission();
    state = state.copyWith(permissionStatus: permission);
  }

  // Request location permission and get location
  Future<bool> requestLocationPermission() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Request permission
      final permission = await _locationService.requestLocationPermission();
      state = state.copyWith(
        permissionStatus: permission,
        hasRequestedPermission: true,
      );

      if (permission == LocationPermissionStatus.granted) {
        // Get current location
        final position = await _locationService.getHighAccuracyLocation();
        
        if (position != null) {
          state = state.copyWith(
            currentPosition: position,
            isLoading: false,
            error: null,
          );

          // Update location in profile
          await _updateProfileLocation(position);
          
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
        state = state.copyWith(error: 'Permiso de ubicación no concedido');
        return false;
      }

      state = state.copyWith(isLoading: true, error: null);

      final position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        state = state.copyWith(
          currentPosition: position,
          isLoading: false,
          error: null,
        );

        // Update location in profile
        await _updateProfileLocation(position);
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo obtener la ubicación actual',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al obtener ubicación: ${e.toString()}',
      );
      return false;
    }
  }

  // Update location in profile
  Future<void> _updateProfileLocation(Position position) async {
    try {
      await _profileService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      // Log error but don't update state - location was obtained successfully
      print('Error updating profile location: $e');
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

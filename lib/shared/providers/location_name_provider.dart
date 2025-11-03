import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../features/profile/providers/location_provider.dart';
import '../../features/profile/providers/profile_provider.dart';

// Location name state (city/province)
class LocationNameState {
  final String? locationName;
  final bool isLoading;
  final String? error;

  const LocationNameState({
    this.locationName,
    this.isLoading = false,
    this.error,
  });

  LocationNameState copyWith({
    String? locationName,
    bool? isLoading,
    String? error,
  }) {
    return LocationNameState(
      locationName: locationName ?? this.locationName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Location name notifier
class LocationNameNotifier extends StateNotifier<LocationNameState> {
  LocationNameNotifier(this.ref) : super(const LocationNameState()) {
    // Listen to location changes and update when location becomes available
    ref.listen<LocationState>(
      locationProvider,
      (previous, next) {
        print('📍 [LocationName] Location state changed');
        print('   - Previous hasLocation: ${previous?.hasLocation}');
        print('   - Next hasLocation: ${next.hasLocation}');
        if (next.hasLocation && next.currentPosition != null) {
          _loadLocationName();
        }
      },
    );
    
    // Also try to load on initialization
    _loadLocationName();
  }

  final Ref ref;

  Future<void> _loadLocationName() async {
    final locationState = ref.read(locationProvider);
    
    print('📍 [LocationName] Checking location state...');
    print('📍 [LocationName] hasLocation: ${locationState.hasLocation}');
    print('📍 [LocationName] currentPosition: ${locationState.currentPosition}');
    print('📍 [LocationName] isPermissionGranted: ${locationState.isPermissionGranted}');
    
    double? latitude;
    double? longitude;
    
    // Try to get location from current position first
    if (locationState.hasLocation && locationState.currentPosition != null) {
      latitude = locationState.currentPosition!.latitude;
      longitude = locationState.currentPosition!.longitude;
      print('📍 [LocationName] Using current position from locationProvider');
    } else {
      // Fallback: try to get from profile's lastLocation
      try {
        final profileState = ref.read(profileProvider);
        if (profileState.profile?.lastLocation != null) {
          final lastLoc = profileState.profile!.lastLocation!;
          print('📍 [LocationName] Trying to use profile lastLocation: $lastLoc');
          
          if (lastLoc['coordinates'] != null && lastLoc['coordinates'] is List) {
            final coords = lastLoc['coordinates'] as List;
            if (coords.length >= 2) {
              // GeoJSON format: [longitude, latitude]
              longitude = (coords[0] as num).toDouble();
              latitude = (coords[1] as num).toDouble();
              print('📍 [LocationName] Using profile coordinates: lat=$latitude, lon=$longitude');
            }
          }
        }
      } catch (e) {
        print('📍 [LocationName] Error reading profile location: $e');
      }
    }
    
    if (latitude == null || longitude == null) {
      print('📍 [LocationName] No location available (neither current nor profile), returning empty state');
      state = const LocationNameState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('📍 [LocationName] Getting placemark for coordinates:');
      print('   - Latitude: $latitude');
      print('   - Longitude: $longitude');
      print('   - Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      String? locationName;
      
      if (kIsWeb) {
        // For web, use OpenStreetMap Nominatim API (free, no API key required)
        print('📍 [LocationName] Using Nominatim API for web...');
        locationName = await _getLocationNameFromNominatim(latitude, longitude);
      } else {
        // For mobile, use geocoding package
        print('📍 [LocationName] Using geocoding package for mobile...');
        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        print('📍 [LocationName] Placemarks received: ${placemarks.length}');
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          
          print('📍 [LocationName] Placemark details:');
          print('   - locality: ${placemark.locality}');
          print('   - administrativeArea: ${placemark.administrativeArea}');
          print('   - subAdministrativeArea: ${placemark.subAdministrativeArea}');
          print('   - subLocality: ${placemark.subLocality}');
          print('   - country: ${placemark.country}');
          print('   - name: ${placemark.name}');
          print('   - thoroughfare: ${placemark.thoroughfare}');
          
          // Build location name: Just City (we'll add "en" prefix in the UI)
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            locationName = placemark.locality;
          } else if (placemark.administrativeArea != null && 
                     placemark.administrativeArea!.isNotEmpty) {
            locationName = placemark.administrativeArea;
          } else if (placemark.subAdministrativeArea != null && 
                     placemark.subAdministrativeArea!.isNotEmpty) {
            locationName = placemark.subAdministrativeArea;
          } else if (placemark.name != null && placemark.name!.isNotEmpty) {
            locationName = placemark.name;
          }
        } else {
          print('📍 [LocationName] No placemarks found');
        }
      }

      print('📍 [LocationName] Final location name: $locationName');

      state = state.copyWith(
        locationName: locationName,
        isLoading: false,
        error: null,
      );
    } catch (e, stackTrace) {
      print('❌ [LocationName] Error getting location name: $e');
      print('📍 [LocationName] Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refresh location name
  Future<void> refresh() async {
    await _loadLocationName();
  }

  // Get location name using OpenStreetMap Nominatim API (for web)
  Future<String?> _getLocationNameFromNominatim(double latitude, double longitude) async {
    try {
      // Nominatim is free but requires a user agent
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&accept-language=es,en',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RenomadaApp/1.0 (contact@renomada.app)', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        
        print('📍 [LocationName] Nominatim response: $address');
        
        if (address != null) {
          // Try to get city/town/village first, then municipality, then state
          String? city = address['city'] as String? ?? 
                         address['town'] as String? ?? 
                         address['village'] as String? ??
                         address['municipality'] as String?;
          
          String? state = address['state'] as String? ?? 
                         address['region'] as String? ??
                         address['province'] as String?;
          
          if (city != null && city.isNotEmpty) {
            // Return only city for web (we'll add "en" prefix in the UI)
            return city;
          } else if (state != null && state.isNotEmpty) {
            return state;
          } else {
            // Fallback to display name if available
            final displayName = data['display_name'] as String?;
            if (displayName != null && displayName.isNotEmpty) {
              // Take first part of display name (usually the most specific location)
              return displayName.split(',').first.trim();
            }
          }
        }
      } else {
        print('📍 [LocationName] Nominatim API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [LocationName] Error calling Nominatim API: $e');
    }
    
    return null;
  }
}

// Provider
final locationNameProvider = 
    StateNotifierProvider<LocationNameNotifier, LocationNameState>((ref) {
  return LocationNameNotifier(ref);
});


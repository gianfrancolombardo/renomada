import 'dart:typed_data';

class UserProfile {
  final String userId;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? lastLocation; // PostGIS point as JSON
  final DateTime? lastSeenAt;
  final bool isLocationOptOut;
  final bool hasSeenOnboarding;

  const UserProfile({
    required this.userId,
    this.username,
    this.avatarUrl,
    this.lastLocation,
    this.lastSeenAt,
    this.isLocationOptOut = false,
    this.hasSeenOnboarding = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedLastLocation;
    final rawLastLocation = json['last_location'];
    if (rawLastLocation != null) {
      // Common cases:
      // - PostGIS can return a GeoJSON-like object with `type` + `coordinates`
      // - It can return a string like `SRID=4326;POINT(lon lat)` or `POINT(lon lat)`
      if (rawLastLocation is Map) {
        parsedLastLocation = rawLastLocation.cast<String, dynamic>();
      } else if (rawLastLocation is String) {
        parsedLastLocation = _parsePostgisLastLocationString(rawLastLocation);
      }
    }

    return UserProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastLocation: parsedLastLocation,
      lastSeenAt: json['last_seen_at'] != null 
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      isLocationOptOut: json['is_location_opt_out'] as bool? ?? false,
      hasSeenOnboarding: json['has_seen_onboarding'] as bool? ?? false,
    );
  }

  static Map<String, dynamic>? _parsePostgisLastLocationString(String raw) {
    // Case 1: Text format, e.g. "POINT(lon lat)" or "SRID=4326;POINT(lon lat)"
    final pointMatch = RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)').firstMatch(raw);
    if (pointMatch != null) {
      final lon = double.tryParse(pointMatch.group(1) ?? '');
      final lat = double.tryParse(pointMatch.group(2) ?? '');
      if (lat != null && lon != null) {
        return {
          'type': 'Point',
          // GeoJSON: [longitude, latitude]
          'coordinates': [lon, lat],
        };
      }
    }

    // Case 2: WKB hex (as returned by PostGIS sometimes), e.g.
    // "0101000020E6100000CDCCCCCCCC4C0240E7FBA9F1D2CD4440"
    // Expected layout for EWKB Point:
    // - 1 byte: endianness (1 = little endian)
    // - 4 bytes: geometry type (1 = Point)
    // - 4 bytes: SRID
    // - 8 bytes: X (lon)
    // - 8 bytes: Y (lat)
    final trimmed = raw.trim();
    final isHex = RegExp(r'^[0-9a-fA-F]+$').hasMatch(trimmed) && trimmed.length >= 16;
    if (isHex) {
      try {
        final bytes = <int>[];
        for (int i = 0; i < trimmed.length; i += 2) {
          bytes.add(int.parse(trimmed.substring(i, i + 2), radix: 16));
        }
        if (bytes.length < 1 + 4 + 4 + 8 + 8) return null;

        final ByteData data = ByteData.sublistView(Uint8List.fromList(bytes));
        final endianByte = data.getUint8(0);
        final littleEndian = endianByte == 1;

        // geometry type at offset 1..4
        final geomType = data.getUint32(1, littleEndian ? Endian.little : Endian.big);
        // In PostGIS EWKB, geometry type may include flags (e.g. SRID present => 0x20000001).
        // We only need to ensure it's a Point (lower bits equal 1).
        if ((geomType & 0xFFFF) != 1) return null;

        // srid at offset 5..8 (not used)
        // final srid = data.getUint32(5, endian: littleEndian ? Endian.little : Endian.big);

        // lon then lat
        // Offsets (EWKB Point): 1 byte order + 4 bytes type + 4 bytes SRID = 9 bytes header
        final lon = data.getFloat64(9, littleEndian ? Endian.little : Endian.big);
        final lat = data.getFloat64(17, littleEndian ? Endian.little : Endian.big);

        if (lat.isFinite && lon.isFinite) {
          return {
            'type': 'Point',
            'coordinates': [lon, lat],
          };
        }
      } catch (_) {
        // Best-effort only; ignore parse errors.
      }
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'last_location': lastLocation,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_location_opt_out': isLocationOptOut,
      'has_seen_onboarding': hasSeenOnboarding,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    Map<String, dynamic>? lastLocation,
    DateTime? lastSeenAt,
    bool? isLocationOptOut,
    bool? hasSeenOnboarding,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLocation: lastLocation ?? this.lastLocation,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isLocationOptOut: isLocationOptOut ?? this.isLocationOptOut,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.userId == userId &&
        other.username == username &&
        other.avatarUrl == avatarUrl &&
        other.lastLocation == lastLocation &&
        other.lastSeenAt == lastSeenAt &&
        other.isLocationOptOut == isLocationOptOut &&
        other.hasSeenOnboarding == hasSeenOnboarding;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      username,
      avatarUrl,
      lastLocation,
      lastSeenAt,
      isLocationOptOut,
      hasSeenOnboarding,
    );
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, username: $username, avatarUrl: $avatarUrl, lastLocation: $lastLocation, lastSeenAt: $lastSeenAt, isLocationOptOut: $isLocationOptOut, hasSeenOnboarding: $hasSeenOnboarding)';
  }
}

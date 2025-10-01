class UserProfile {
  final String userId;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? lastLocation; // PostGIS point as JSON
  final DateTime? lastSeenAt;
  final bool isLocationOptOut;

  const UserProfile({
    required this.userId,
    this.username,
    this.avatarUrl,
    this.lastLocation,
    this.lastSeenAt,
    this.isLocationOptOut = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      lastLocation: json['last_location'] != null 
          ? {'type': 'Point', 'coordinates': [0.0, 0.0]} // Placeholder for PostGIS data
          : null,
      lastSeenAt: json['last_seen_at'] != null 
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      isLocationOptOut: json['is_location_opt_out'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'last_location': lastLocation,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_location_opt_out': isLocationOptOut,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    Map<String, dynamic>? lastLocation,
    DateTime? lastSeenAt,
    bool? isLocationOptOut,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLocation: lastLocation ?? this.lastLocation,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isLocationOptOut: isLocationOptOut ?? this.isLocationOptOut,
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
        other.isLocationOptOut == isLocationOptOut;
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
    );
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, username: $username, avatarUrl: $avatarUrl, lastLocation: $lastLocation, lastSeenAt: $lastSeenAt, isLocationOptOut: $isLocationOptOut)';
  }
}

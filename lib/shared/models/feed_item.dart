
class FeedItem {
  final String itemId;
  final String ownerId;
  final String? ownerUsername;
  final String? ownerAvatarUrl;
  final double? distanceM;
  final String title;
  final String? description;
  final DateTime createdAt;

  const FeedItem({
    required this.itemId,
    required this.ownerId,
    this.ownerUsername,
    this.ownerAvatarUrl,
    this.distanceM,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      itemId: json['item_id'] as String,
      ownerId: json['owner_id'] as String,
      ownerUsername: json['owner_username'] as String?,
      ownerAvatarUrl: json['owner_avatar_url'] as String?,
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'owner_id': ownerId,
      'owner_username': ownerUsername,
      'owner_avatar_url': ownerAvatarUrl,
      'distance_m': distanceM,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FeedItem copyWith({
    String? itemId,
    String? ownerId,
    String? ownerUsername,
    String? ownerAvatarUrl,
    double? distanceM,
    String? title,
    String? description,
    DateTime? createdAt,
  }) {
    return FeedItem(
      itemId: itemId ?? this.itemId,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      distanceM: distanceM ?? this.distanceM,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper to format distance
  String get formattedDistance {
    if (distanceM == null) return 'Distancia desconocida';
    
    if (distanceM! < 1000) {
      return '${distanceM!.round()} m';
    } else {
      final km = distanceM! / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  // Helper to format creation date
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'Ahora';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedItem &&
        other.itemId == itemId &&
        other.ownerId == ownerId &&
        other.ownerUsername == ownerUsername &&
        other.ownerAvatarUrl == ownerAvatarUrl &&
        other.distanceM == distanceM &&
        other.title == title &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      itemId,
      ownerId,
      ownerUsername,
      ownerAvatarUrl,
      distanceM,
      title,
      description,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'FeedItem(itemId: $itemId, ownerId: $ownerId, ownerUsername: $ownerUsername, ownerAvatarUrl: $ownerAvatarUrl, distanceM: $distanceM, title: $title, description: $description, createdAt: $createdAt)';
  }
}

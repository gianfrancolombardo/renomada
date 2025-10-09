
enum ItemStatus {
  available,
  exchanged,
  paused,
}

class Item {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Item({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.status = ItemStatus.available,
    required this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    try {
      return Item(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: ItemStatus.values.firstWhere(
          (v) => v.name == (json['status'] ?? 'available'),
          orElse: () => ItemStatus.available,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
    } catch (e) {
      print('❌ [Item.fromJson] Error: $e');
      print('🔍 [Item.fromJson] JSON keys: ${json.keys}');
      print('🔍 [Item.fromJson] Full JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    ItemStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == ItemStatus.available;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ownerId,
      title,
      description,
      status,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, ownerId: $ownerId, title: $title, description: $description, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

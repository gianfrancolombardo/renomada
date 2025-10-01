
class ItemPhoto {
  final String id;
  final String itemId;
  final String path;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;

  const ItemPhoto({
    required this.id,
    required this.itemId,
    required this.path,
    this.mimeType,
    this.sizeBytes,
    required this.createdAt,
  });

  factory ItemPhoto.fromJson(Map<String, dynamic> json) {
    return ItemPhoto(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      path: json['path'] as String,
      mimeType: json['mime_type'] as String?,
      sizeBytes: json['size_bytes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'path': path,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ItemPhoto copyWith({
    String? id,
    String? itemId,
    String? path,
    String? mimeType,
    int? sizeBytes,
    DateTime? createdAt,
  }) {
    return ItemPhoto(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      path: path ?? this.path,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper to get signed URL for display
  String getSignedUrl() {
    // This will be implemented in the service layer
    return path;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemPhoto &&
        other.id == id &&
        other.itemId == itemId &&
        other.path == path &&
        other.mimeType == mimeType &&
        other.sizeBytes == sizeBytes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      itemId,
      path,
      mimeType,
      sizeBytes,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'ItemPhoto(id: $id, itemId: $itemId, path: $path, mimeType: $mimeType, sizeBytes: $sizeBytes, createdAt: $createdAt)';
  }
}

enum ChatStatus {
  coordinating,
  deliveryCoordinated,
  deliveryCompleted,
}

class Chat {
  final String id;
  final String itemId;
  final String aUserId;
  final String bUserId;
  final DateTime createdAt;
  final ChatStatus status;

  const Chat({
    required this.id,
    required this.itemId,
    required this.aUserId,
    required this.bUserId,
    required this.createdAt,
    this.status = ChatStatus.coordinating,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      aUserId: json['a_user_id'] as String,
      bUserId: json['b_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: ChatStatus.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => ChatStatus.coordinating,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'a_user_id': aUserId,
      'b_user_id': bUserId,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  Chat copyWith({
    String? id,
    String? itemId,
    String? aUserId,
    String? bUserId,
    DateTime? createdAt,
    ChatStatus? status,
  }) {
    return Chat(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      aUserId: aUserId ?? this.aUserId,
      bUserId: bUserId ?? this.bUserId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  // Helper method to get the other user ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == aUserId ? bUserId : aUserId;
  }

  // Helper method to check if user is participant
  bool isParticipant(String userId) {
    return userId == aUserId || userId == bUserId;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        other.id == id &&
        other.itemId == itemId &&
        other.aUserId == aUserId &&
        other.bUserId == bUserId &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      itemId,
      aUserId,
      bUserId,
      createdAt,
      status,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, itemId: $itemId, aUserId: $aUserId, bUserId: $bUserId, createdAt: $createdAt, status: $status)';
  }
}

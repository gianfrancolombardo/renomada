enum MessageStatus {
  sent,
  delivered,
  read,
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['id'] as String,
        chatId: json['chat_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        status: MessageStatus.values.firstWhere(
          (v) => v.name == (json['status'] ?? 'sent'),
          orElse: () => MessageStatus.sent,
        ),
      );
    } catch (e) {
      print('❌ [Message.fromJson] Error: $e');
      print('🔍 [Message.fromJson] JSON keys: ${json.keys}');
      print('🔍 [Message.fromJson] id: ${json['id']} (${json['id']?.runtimeType})');
      print('🔍 [Message.fromJson] chat_id: ${json['chat_id']} (${json['chat_id']?.runtimeType})');
      print('🔍 [Message.fromJson] sender_id: ${json['sender_id']} (${json['sender_id']?.runtimeType})');
      print('🔍 [Message.fromJson] content: ${json['content']} (${json['content']?.runtimeType})');
      print('🔍 [Message.fromJson] created_at: ${json['created_at']} (${json['created_at']?.runtimeType})');
      print('🔍 [Message.fromJson] status: ${json['status']} (${json['status']?.runtimeType})');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  // Helper method to check if message is from current user
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.chatId == chatId &&
        other.senderId == senderId &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      chatId,
      senderId,
      content,
      createdAt,
      status,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, senderId: $senderId, content: $content, createdAt: $createdAt, status: $status)';
  }
}

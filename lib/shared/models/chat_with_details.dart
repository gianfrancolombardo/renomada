import 'chat.dart';
import 'message.dart';
import 'item.dart';
import 'user_profile.dart';

class ChatWithDetails {
  final Chat chat;
  final Item item;
  final UserProfile otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final String? firstPhotoUrl;

  const ChatWithDetails({
    required this.chat,
    required this.item,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.firstPhotoUrl,
  });

  factory ChatWithDetails.fromJson(Map<String, dynamic> json) {
    return ChatWithDetails(
      chat: Chat.fromJson(json['chat'] as Map<String, dynamic>),
      item: Item.fromJson(json['item'] as Map<String, dynamic>),
      otherUser: UserProfile.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      firstPhotoUrl: json['first_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat': chat.toJson(),
      'item': item.toJson(),
      'other_user': otherUser.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'first_photo_url': firstPhotoUrl,
    };
  }

  ChatWithDetails copyWith({
    Chat? chat,
    Item? item,
    UserProfile? otherUser,
    Message? lastMessage,
    int? unreadCount,
    String? firstPhotoUrl,
  }) {
    return ChatWithDetails(
      chat: chat ?? this.chat,
      item: item ?? this.item,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      firstPhotoUrl: firstPhotoUrl ?? this.firstPhotoUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatWithDetails &&
        other.chat == chat &&
        other.item == item &&
        other.otherUser == otherUser &&
        other.lastMessage == lastMessage &&
        other.unreadCount == unreadCount &&
        other.firstPhotoUrl == firstPhotoUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      chat,
      item,
      otherUser,
      lastMessage,
      unreadCount,
      firstPhotoUrl,
    );
  }

  @override
  String toString() {
    return 'ChatWithDetails(chat: $chat, item: $item, otherUser: $otherUser, lastMessage: $lastMessage, unreadCount: $unreadCount, firstPhotoUrl: $firstPhotoUrl)';
  }
}

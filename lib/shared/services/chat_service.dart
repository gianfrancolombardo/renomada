import '../../core/config/supabase_config.dart';
import '../models/chat.dart';
import '../models/chat_with_details.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/message.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // Get all chats for current user with details
  Future<List<ChatWithDetails>> getUserChats() async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      // Use RPC function to get chats with details (bypasses RLS)
      final chatsResponse = await SupabaseConfig.client.rpc(
        'get_user_chats_with_details',
        params: {'p_user_id': currentUserId},
      );

      final List<ChatWithDetails> chatsWithDetails = [];

      for (final chatData in chatsResponse) {
        // Build Chat object
        final chat = Chat(
          id: chatData['chat_id'] as String,
          itemId: chatData['item_id'] as String,
          aUserId: chatData['a_user_id'] as String,
          bUserId: chatData['b_user_id'] as String,
          createdAt: DateTime.parse(chatData['chat_created_at'] as String),
          status: ChatStatus.values.firstWhere(
            (e) => e.name == chatData['chat_status'],
            orElse: () => ChatStatus.coordinating,
          ),
        );

        // Build Item object
        final item = Item(
          id: chatData['item_id'] as String,
          ownerId: chatData['item_owner_id'] as String,
          title: chatData['item_title'] as String,
          description: chatData['item_description'] as String?,
          status: ItemStatus.values.firstWhere(
            (e) => e.name == chatData['item_status'],
            orElse: () => ItemStatus.available,
          ),
          createdAt: DateTime.parse(chatData['chat_created_at'] as String),
        );

        // Build UserProfile object
        final otherUser = UserProfile(
          userId: chatData['other_user_id'] as String,
          username: chatData['other_username'] as String? ?? 'Usuario',
          avatarUrl: chatData['other_avatar_url'] as String?,
        );

        // Build Message object (if exists)
        Message? lastMessage;
        if (chatData['last_message_id'] != null) {
          lastMessage = Message(
            id: chatData['last_message_id'] as String,
            chatId: chatData['chat_id'] as String,
            senderId: chatData['last_message_sender_id'] as String,
            content: chatData['last_message_content'] as String,
            createdAt: DateTime.parse(chatData['last_message_created_at'] as String),
            status: MessageStatus.sent,
          );
        }

        final unreadCount = chatData['unread_count'] as int;

        chatsWithDetails.add(ChatWithDetails(
          chat: chat,
          item: item,
          otherUser: otherUser,
          lastMessage: lastMessage,
          unreadCount: unreadCount,
        ));
      }

      return chatsWithDetails;
    } catch (e) {
      throw Exception('Failed to fetch user chats: $e');
    }
  }

  // Get or create chat for item
  Future<Chat> getOrCreateChat({
    required String itemId,
    required String otherUserId,
  }) async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      // First try to find existing chat
      final existingChats = await SupabaseConfig.client
          .from('chats')
          .select()
          .eq('item_id', itemId)
          .or('a_user_id.eq.$currentUserId,b_user_id.eq.$currentUserId')
          .or('a_user_id.eq.$otherUserId,b_user_id.eq.$otherUserId');

      if (existingChats.isNotEmpty) {
        return Chat.fromJson(existingChats.first);
      }

      // Create new chat
      final chatData = {
        'item_id': itemId,
        'a_user_id': currentUserId,
        'b_user_id': otherUserId,
        'status': 'coordinating',
      };

      final response = await SupabaseConfig.client
          .from('chats')
          .insert(chatData)
          .select()
          .single();

      return Chat.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get or create chat: $e');
    }
  }

  // Update chat status
  Future<void> updateChatStatus({
    required String chatId,
    required ChatStatus status,
  }) async {
    try {
      await SupabaseConfig.client
          .from('chats')
          .update({'status': status.name})
          .eq('id', chatId);
    } catch (e) {
      throw Exception('Failed to update chat status: $e');
    }
  }

  // Get chat by ID
  Future<Chat?> getChatById(String chatId) async {
    try {
      final response = await SupabaseConfig.client
          .from('chats')
          .select()
          .eq('id', chatId)
          .maybeSingle();

      if (response == null) return null;
      return Chat.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  // Check if user can access chat
  Future<bool> canAccessChat(String chatId) async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      final chat = await getChatById(chatId);
      
      if (chat == null) return false;
      return chat.isParticipant(currentUserId);
    } catch (e) {
      return false;
    }
  }

  // Get chat with full details
  Future<ChatWithDetails?> getChatWithDetails(String chatId) async {
    try {
      final currentUserId = SupabaseConfig.currentUser!.id;
      
      // Get chat with item details
      final chatResponse = await SupabaseConfig.client
          .from('chats')
          .select('''
            id,
            item_id,
            a_user_id,
            b_user_id,
            created_at,
            status,
            items!inner(
              id,
              title,
              description,
              status,
              created_at,
              updated_at
            )
          ''')
          .eq('id', chatId)
          .maybeSingle();

      if (chatResponse == null) return null;

      final chat = Chat.fromJson(chatResponse);
      final item = Item.fromJson(chatResponse['items']);
      
      // Get other user profile
      final otherUserId = chat.getOtherUserId(currentUserId);
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('user_id, username, avatar_url')
          .eq('user_id', otherUserId)
          .maybeSingle();
      
      final otherUser = profileResponse != null 
          ? UserProfile.fromJson(profileResponse)
          : UserProfile(userId: otherUserId);

      // Get last message
      final lastMessageResponse = await SupabaseConfig.client
          .from('messages')
          .select('id, content, created_at, sender_id')
          .eq('chat_id', chat.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastMessage = lastMessageResponse != null
          ? Message.fromJson(lastMessageResponse)
          : null;

      // Get unread count
      final unreadResponse = await SupabaseConfig.client
          .from('messages')
          .select('id')
          .eq('chat_id', chat.id)
          .neq('sender_id', currentUserId)
          .eq('status', 'sent');

      final unreadCount = unreadResponse.length;

      return ChatWithDetails(
        chat: chat,
        item: item,
        otherUser: otherUser,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
      );
    } catch (e) {
      throw Exception('Failed to get chat details: $e');
    }
  }

  // Delete chat (soft delete by updating status)
  Future<void> deleteChat(String chatId) async {
    try {
      await updateChatStatus(
        chatId: chatId,
        status: ChatStatus.deliveryCompleted,
      );
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Stream of chats for realtime updates
  Stream<List<ChatWithDetails>> getUserChatsStream() {
    final currentUserId = SupabaseConfig.currentUser!.id;
    
    return SupabaseConfig.client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('a_user_id', currentUserId)
        .map((data) {
      // This is a simplified version - in a real app you'd want to
      // fetch the full details for each chat
      return data.map((chat) => ChatWithDetails.fromJson(chat)).toList();
    });
  }
}

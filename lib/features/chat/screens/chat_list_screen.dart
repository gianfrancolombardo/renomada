import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/chat_with_details.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_card.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_error_state.dart';
import '../widgets/chat_loading_state.dart';
import 'chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversaciones'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final chatState = ref.watch(chatProvider);
          
          if (chatState.isLoading && chatState.chats.isEmpty) {
            return const ChatLoadingState();
          }

          if (chatState.hasError) {
            return ChatErrorState(
              error: chatState.error!,
              onRetry: () => ref.read(chatProvider.notifier).refreshChats(),
            );
          }

          if (chatState.chats.isEmpty) {
            return const ChatEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(chatProvider.notifier).refreshChats(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatState.chats.length,
              itemBuilder: (context, index) {
                final chat = chatState.chats[index];
                return ChatCard(
                  chat: chat,
                  onTap: () => _navigateToChat(context, chat),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateToChat(BuildContext context, ChatWithDetails chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.chat.id,
          chat: chat,
        ),
      ),
    );
  }
}

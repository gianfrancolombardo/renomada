import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/chat_with_details.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_card.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_error_state.dart';
import '../widgets/chat_loading_state.dart';

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
    return Consumer(
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
            padding: EdgeInsets.all(20.w),
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
    );
  }

  void _navigateToChat(BuildContext context, ChatWithDetails chat) {
    context.push('/chat/${chat.chat.id}');
  }
}

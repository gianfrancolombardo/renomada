import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../core/config/supabase_config.dart';
import '../providers/chat_providers.dart';
import '../../profile/providers/profile_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_header.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final ChatWithDetails? chat;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.chat,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatWithDetails? _loadedChat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messageProvider.notifier).loadMessages(widget.chatId);
      // Load chat details if not provided (e.g., when navigating from like)
      if (widget.chat == null) {
        _loadChatDetails();
      }
    });
  }

  Future<void> _loadChatDetails() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final chatDetails = await chatService.getChatWithDetails(widget.chatId);
      if (mounted && chatDetails != null) {
        setState(() {
          _loadedChat = chatDetails;
        });
      }
    } catch (e) {
      print('Error loading chat details: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.chat ?? _loadedChat) != null 
            ? ChatHeader(chat: widget.chat ?? _loadedChat!)
            : const Text('Chat'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final messageState = ref.watch(messageProvider);
                
                if (messageState.isLoading && messageState.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (messageState.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar mensajes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          messageState.error!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(messageProvider.notifier).loadMessages(widget.chatId),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (messageState.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Inicia la conversación',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (widget.chat ?? _loadedChat) != null 
                              ? 'Envía un mensaje sobre "${(widget.chat ?? _loadedChat)!.item.title}"'
                              : 'Envía un mensaje',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final currentUserProfile = ref.watch(profileDataProvider);
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messageState.messages.length,
                  itemBuilder: (context, index) {
                    final message = messageState.messages[index];
                    return MessageBubble(
                      message: message,
                      isFromCurrentUser: message.isFromUser(SupabaseConfig.currentUser?.id ?? ''),
                      currentUserProfile: currentUserProfile,
                    );
                  },
                );
              },
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final messageState = ref.watch(messageProvider);
              return ChatInput(
                controller: _messageController,
                onSend: _sendMessage,
                isLoading: messageState.isSending,
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;

    ref.read(messageProvider.notifier).sendMessage(content).then((message) {
      if (message != null) {
        _messageController.clear();
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

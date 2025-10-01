import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/chat_service.dart';
import '../../../shared/services/message_service.dart';
import '../../../shared/services/chat_realtime_service.dart';
import 'chat_provider.dart';
import 'message_provider.dart';

// Chat service provider
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

// Message service provider
final messageServiceProvider = Provider<MessageService>((ref) => MessageService());

// Chat realtime service provider
final chatRealtimeServiceProvider = ChangeNotifierProvider<ChatRealtimeService>((ref) => ChatRealtimeService());

// Chat provider
final chatProvider = ChangeNotifierProvider<ChatProvider>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatProvider(chatService);
});

// Message provider
final messageProvider = ChangeNotifierProvider<MessageProvider>((ref) {
  final messageService = ref.watch(messageServiceProvider);
  return MessageProvider(messageService);
});

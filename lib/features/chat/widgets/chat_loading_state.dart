import 'package:flutter/material.dart';
import '../widgets/chat_list_skeleton.dart';

/// Loading state for chat list - uses skeleton loader for better UX
class ChatLoadingState extends StatelessWidget {
  const ChatLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatListSkeleton(itemCount: 5);
  }
}

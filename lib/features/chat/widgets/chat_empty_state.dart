import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/unified_empty_state.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return UnifiedEmptyState(
      icon: LucideIcons.messageCircle,
      title: 'Aún no tienes conversaciones',
      subtitle: 'Haz swipe en algunos items para empezar a chatear con otros usuarios',
      primaryButtonText: 'Explorar items',
      primaryButtonIcon: LucideIcons.compass,
      onPrimaryButtonPressed: () => context.go('/feed'),
    );
  }
}

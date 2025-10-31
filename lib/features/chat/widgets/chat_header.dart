import 'package:flutter/material.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../shared/widgets/avatar_image.dart';

class ChatHeader extends StatelessWidget {
  final ChatWithDetails chat;

  const ChatHeader({
    super.key,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        _buildAvatar(context, colorScheme),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chat.otherUser.username ?? 'Nómada',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                chat.item.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Menu oculto por ahora
        // PopupMenuButton<String>(
        //   onSelected: (value) => _handleMenuAction(context, value),
        //   itemBuilder: (context) => [
        //     const PopupMenuItem(
        //       value: 'status',
        //       child: Row(
        //         children: [
        //           Icon(Icons.info_outline),
        //           SizedBox(width: 8),
        //           Text('Cambiar estado'),
        //         ],
        //       ),
        //     ),
        //     const PopupMenuItem(
        //       value: 'report',
        //       child: Row(
        //         children: [
        //           Icon(Icons.report_outlined),
        //           SizedBox(width: 8),
        //           Text('Reportar'),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, ColorScheme colorScheme) {
    final username = chat.otherUser.username ?? 'Nómada';
    final initial = username.substring(0, 1).toUpperCase();

    // ✨ OPTIMIZATION: Use AvatarImage widget which handles external URLs correctly
    return AvatarImage(
      avatarUrl: chat.otherUser.avatarUrl,
      radius: 20,
      backgroundColor: colorScheme.primaryContainer,
      placeholder: Text(
        initial,
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

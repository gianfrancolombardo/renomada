import 'package:flutter/material.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../shared/models/chat.dart';

class ChatCard extends StatelessWidget {
  final ChatWithDetails chat;
  final VoidCallback onTap;

  const ChatCard({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12), // Mismo que los items
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12), // Mismo que los items
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar - adjusted size to match content height
                _buildAvatar(context, colorScheme),
                const SizedBox(width: 12),
                // Content - reorganized hierarchy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First line: Username and timestamp
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.otherUser.username ?? 'Nómada',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.lastMessage != null)
                            Text(
                              _formatTime(chat.lastMessage!.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Second line: Item title
                      Text(
                        chat.item.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Third line: Last message or status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage?.content ?? _getStatusText(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: chat.lastMessage != null
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: TextStyle(
                                  color: colorScheme.tertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  String _getStatusText() {
    switch (chat.chat.status) {
      case ChatStatus.coordinating:
        return 'Coordinando entrega...';
      case ChatStatus.deliveryCoordinated:
        return 'Entrega coordinada';
      case ChatStatus.deliveryCompleted:
        return 'Entrega completada';
    }
  }

  Widget _buildAvatar(BuildContext context, ColorScheme colorScheme) {
    final avatarUrl = chat.otherUser.avatarUrl;
    final username = chat.otherUser.username ?? 'Nómada';
    final initial = username.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 28,
      backgroundColor: colorScheme.primaryContainer,
      child: avatarUrl != null
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    initial,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  );
                },
              ),
            )
          : Text(
              initial,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
    );
  }
}

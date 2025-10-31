import 'package:flutter/material.dart';
import '../../../shared/models/message.dart';
import '../../../shared/models/user_profile.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;
  final UserProfile? currentUserProfile;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.currentUserProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? colorScheme.surfaceVariant
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isFromCurrentUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isFromCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isFromCurrentUser
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isFromCurrentUser
                              ? colorScheme.onSurfaceVariant.withOpacity(0.7)
                              : colorScheme.onSecondaryContainer.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(),
                          size: 12,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    } else {
      return 'Ahora';
    }
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
    }
  }
}


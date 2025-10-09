import 'package:flutter/material.dart';
import '../../../shared/models/message.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/profile_service.dart';
import '../../../core/config/supabase_config.dart';

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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                'U', // This will be replaced with actual user data from chat context
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
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
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
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
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
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
                              ? colorScheme.onPrimary.withOpacity(0.7)
                              : colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(),
                          size: 12,
                          color: colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            _CurrentUserAvatar(
              currentUserProfile: currentUserProfile,
              colorScheme: colorScheme,
            ),
          ],
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

class _CurrentUserAvatar extends StatefulWidget {
  final UserProfile? currentUserProfile;
  final ColorScheme colorScheme;

  const _CurrentUserAvatar({
    required this.currentUserProfile,
    required this.colorScheme,
  });

  @override
  State<_CurrentUserAvatar> createState() => _CurrentUserAvatarState();
}

class _CurrentUserAvatarState extends State<_CurrentUserAvatar> {
  String? _signedAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSignedAvatarUrl();
  }

  @override
  void didUpdateWidget(_CurrentUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUserProfile?.avatarUrl != widget.currentUserProfile?.avatarUrl) {
      _loadSignedAvatarUrl();
    }
  }

  Future<void> _loadSignedAvatarUrl() async {
    if (widget.currentUserProfile?.avatarUrl == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final signedUrl = await ProfileService().getAvatarSignedUrl(widget.currentUserProfile!.avatarUrl);
      if (mounted) {
        setState(() {
          _signedAvatarUrl = signedUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading signed avatar URL: $e');
      if (mounted) {
        setState(() {
          _signedAvatarUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: widget.colorScheme.secondary,
      backgroundImage: _signedAvatarUrl != null
          ? NetworkImage(_signedAvatarUrl!)
          : null,
      child: _signedAvatarUrl == null
          ? _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.colorScheme.onSecondary,
                    ),
                  ),
                )
              : Text(
                  widget.currentUserProfile?.username?.substring(0, 1).toUpperCase() ?? 
                  SupabaseConfig.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    color: widget.colorScheme.onSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
          : null,
    );
  }
}

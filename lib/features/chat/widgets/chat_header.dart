import 'package:flutter/material.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../shared/models/chat.dart';

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
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: chat.otherUser.avatarUrl != null
              ? NetworkImage(chat.otherUser.avatarUrl!)
              : null,
          child: chat.otherUser.avatarUrl == null
              ? Text(
                  chat.otherUser.username?.substring(0, 1).toUpperCase() ?? '?',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chat.otherUser.username ?? 'Usuario',
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

  String _getStatusText() {
    switch (chat.chat.status) {
      case ChatStatus.coordinating:
        return 'Coordinando entrega';
      case ChatStatus.deliveryCoordinated:
        return 'Entrega coordinada';
      case ChatStatus.deliveryCompleted:
        return 'Entrega completada';
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (chat.chat.status) {
      case ChatStatus.coordinating:
        return colorScheme.outline;
      case ChatStatus.deliveryCoordinated:
        return colorScheme.primary;
      case ChatStatus.deliveryCompleted:
        return colorScheme.secondary;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'status':
        _showStatusDialog(context);
        break;
      case 'report':
        _showReportDialog(context);
        break;
    }
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Coordinando entrega'),
              leading: Radio<ChatStatus>(
                value: ChatStatus.coordinating,
                groupValue: chat.chat.status,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  // TODO: Update chat status
                },
              ),
            ),
            ListTile(
              title: const Text('Entrega coordinada'),
              leading: Radio<ChatStatus>(
                value: ChatStatus.deliveryCoordinated,
                groupValue: chat.chat.status,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  // TODO: Update chat status
                },
              ),
            ),
            ListTile(
              title: const Text('Entrega completada'),
              leading: Radio<ChatStatus>(
                value: ChatStatus.deliveryCompleted,
                groupValue: chat.chat.status,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  // TODO: Update chat status
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar usuario'),
        content: const Text(
          '¿Estás seguro de que quieres reportar a este usuario? '
          'Esto ayudará a mantener la comunidad segura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte enviado. Gracias por tu colaboración.'),
                ),
              );
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }
}

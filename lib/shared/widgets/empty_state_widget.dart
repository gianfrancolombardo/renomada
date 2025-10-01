import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              
              // Action button
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyFeedWidget extends StatelessWidget {
  final VoidCallback? onIncreaseRadius;
  final VoidCallback? onPublishFirst;

  const EmptyFeedWidget({
    super.key,
    this.onIncreaseRadius,
    this.onPublishFirst,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.explore_outlined,
      title: 'No hay artículos cerca',
      subtitle: 'Intenta aumentar el radio de búsqueda o sé el primero en publicar algo en tu área.',
      actionText: onPublishFirst != null ? 'Publicar artículo' : null,
      onActionPressed: onPublishFirst,
    );
  }
}

class EmptyChatsWidget extends StatelessWidget {
  final VoidCallback? onStartExploring;

  const EmptyChatsWidget({
    super.key,
    this.onStartExploring,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.chat_bubble_outline,
      title: 'No tienes conversaciones',
      subtitle: 'Explora artículos cerca de ti y comienza a chatear con otros nómadas.',
      actionText: onStartExploring != null ? 'Explorar artículos' : null,
      onActionPressed: onStartExploring,
    );
  }
}

class EmptyItemsWidget extends StatelessWidget {
  final VoidCallback? onCreateItem;

  const EmptyItemsWidget({
    super.key,
    this.onCreateItem,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'No has publicado artículos',
      subtitle: 'Comienza a compartir objetos que ya no necesitas con otros nómadas.',
      actionText: onCreateItem != null ? 'Crear artículo' : null,
      onActionPressed: onCreateItem,
    );
  }
}

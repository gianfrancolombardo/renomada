import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/unified_empty_state.dart';

class FeedEmptyState extends StatelessWidget {
  final double selectedRadius;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRefresh;

  const FeedEmptyState({
    super.key,
    required this.selectedRadius,
    required this.onRadiusChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedEmptyState(
      icon: LucideIcons.searchX,
      title: 'No hay artículos cerca',
      subtitle: 'No encontramos artículos dentro de ${selectedRadius.toInt()} km de tu ubicación.',
      customContent: _buildRadiusSelector(context),
      primaryButtonText: 'Publicar artículo',
      primaryButtonIcon: LucideIcons.plus,
      onPrimaryButtonPressed: () => context.go('/my-items'),
      secondaryButtonText: 'Actualizar',
      secondaryButtonIcon: LucideIcons.refreshCw,
      onSecondaryButtonPressed: onRefresh,
    );
  }

  Widget _buildRadiusSelector(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            'Prueba con un radio mayor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [25, 50].map((radius) {
              final isSelected = radius == selectedRadius;
              return GestureDetector(
                onTap: () => onRadiusChanged(radius.toDouble()),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    '${radius} km',
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

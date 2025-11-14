import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/unified_empty_state.dart';

class FeedEmptyState extends ConsumerStatefulWidget {
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
  ConsumerState<FeedEmptyState> createState() => _FeedEmptyStateState();
}

class _FeedEmptyStateState extends ConsumerState<FeedEmptyState> {
  String _getTitle() {
    return 'No hay artículos cerca';
  }

  String _getSubtitle() {
    // Single message for all cases - simple and consistent
    return '¡La comunidad está creciendo! Ya hay muchos artículos disponibles pero ninguno en tu área.';
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedEmptyState(
      icon: LucideIcons.searchX,
      title: _getTitle(),
      subtitle: _getSubtitle(),
      customContent: _buildRadiusSelector(context),
      primaryButtonText: 'Publicar objeto',
      primaryButtonIcon: LucideIcons.plus,
      onPrimaryButtonPressed: () => context.go('/my-items'),
      secondaryButtonText: 'Actualizar',
      secondaryButtonIcon: LucideIcons.refreshCw,
      onSecondaryButtonPressed: () {
        widget.onRefresh();
      },
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
              final isSelected = radius == widget.selectedRadius;
              return GestureDetector(
                onTap: () => widget.onRadiusChanged(radius.toDouble()),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/unified_empty_state.dart';
import '../providers/feed_provider.dart';
import '../../profile/providers/location_provider.dart';

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
  int? _totalActiveItems;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    // Only load count if location is available
    final locationState = ref.read(locationProvider);
    if (locationState.isPermissionGranted && locationState.hasLocation) {
      _loadTotalActiveItems();
    } else {
      // Skip loading count when no location
      setState(() {
        _isLoadingCount = false;
        _totalActiveItems = null;
      });
    }
  }

  Future<void> _loadTotalActiveItems() async {
    // Double check location is still available before calling
    final locationState = ref.read(locationProvider);
    if (!locationState.isPermissionGranted || !locationState.hasLocation) {
      setState(() {
        _isLoadingCount = false;
        _totalActiveItems = null;
      });
      return;
    }

    try {
      final feedService = ref.read(feedProvider.notifier).feedService;
      final count = await feedService.getTotalActiveItemsCount();
      if (mounted) {
        setState(() {
          _totalActiveItems = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      print('Error loading total active items: $e');
      if (mounted) {
        setState(() {
          _totalActiveItems = null;
          _isLoadingCount = false;
        });
      }
    }
  }

  String _getTitle() {
    return 'No hay artículos cerca';
  }

  String _getSubtitle() {
    if (_isLoadingCount) {
      return 'Cargando información de la comunidad...';
    }

    if (_totalActiveItems == null || _totalActiveItems == 0) {
      // No items in the platform yet
      return '¡Sé el primero en publicar! La comunidad apenas está comenzando y cada aporte cuenta para construir algo increíble juntos.';
    } else {
      // Single message that works for all cases - shows count and encourages growth
      final itemsText = _totalActiveItems == 1 ? 'artículo' : 'artículos';
      return '¡La comunidad está creciendo! Ya hay $_totalActiveItems $itemsText disponibles pero ninguno en tu área.';
    }
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
        // Only reload count if location is available
        final locationState = ref.read(locationProvider);
        if (locationState.isPermissionGranted && locationState.hasLocation) {
          _loadTotalActiveItems();
        }
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

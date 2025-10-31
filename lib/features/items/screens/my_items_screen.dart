import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/item_photo.dart';
import '../../../shared/widgets/unified_empty_state.dart';
import '../../../shared/models/item.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../providers/item_provider.dart';
import '../../../shared/services/item_service.dart';
import '../widgets/create_item_bottom_sheet.dart';
import '../widgets/edit_item_bottom_sheet.dart';
import '../widgets/item_list_skeleton.dart';

class MyItemsScreen extends ConsumerStatefulWidget {
  const MyItemsScreen({super.key});

  @override
  ConsumerState<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends ConsumerState<MyItemsScreen> {
  @override
  void initState() {
    super.initState();
    // Load user items when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userItemsProvider.notifier).loadUserItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userItemsState = ref.watch(userItemsProvider);
    
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await ref.read(userItemsProvider.notifier).loadUserItems();
          },
          child: _buildBody(userItemsState),
        ),
        Positioned(
          bottom: 20.h,
          right: 20.w,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showCreateItemModal(context),
              icon: Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20.sp,
              ),
              label: Text(
                'Publicar objeto',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  letterSpacing: 0.5,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(UserItemsState state) {
    if (state.isLoading && state.items.isEmpty) {
      // ✨ OPTIMIZATION: Use skeleton loader for better UX
      return const ItemListSkeleton(itemCount: 6);
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 40.sp,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Error al cargar objetos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  state.error!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.72),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(userItemsProvider.notifier).loadUserItems();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Reintentar',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return UnifiedEmptyState(
        icon: LucideIcons.package,
        title: 'Aún no tienes objetos',
        subtitle: 'Publica tu primer objeto para empezar a regalar',
        primaryButtonText: 'Publicar primer objeto',
        primaryButtonIcon: LucideIcons.plus,
        onPrimaryButtonPressed: () => _showCreateItemModal(context),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _buildItemCard(context, item);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            // TODO: Navigate to item detail
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Item photo with rounded corners
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: ItemPhoto(
                      itemId: item.id,
                      width: 72.w,
                      height: 72.h,
                    ),
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 6.h),
                      
                      // Condition and exchange type chips - Hidden for cleaner list view
                      // Wrap(
                      //   spacing: 6.w,
                      //   runSpacing: 4.h,
                      //   children: [
                      //     _buildSmallChip(
                      //       context,
                      //       label: item.condition.label,
                      //       icon: item.condition.icon,
                      //       color: _getConditionColor(item.condition),
                      //     ),
                      //     _buildSmallChip(
                      //       context,
                      //       label: item.exchangeType.label,
                      //       icon: item.exchangeType.icon,
                      //       color: _getExchangeTypeColor(item.exchangeType),
                      //     ),
                      //   ],
                      // ),
                      
                      SizedBox(height: 8.h),
                      
                      // Status and date
                      Row(
                        children: [
                          // Status chip
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: _getStatusColor(item.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20.r), // Totalmente redondeado
                            ),
                            child: Text(
                              _getStatusText(item.status),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _getStatusColor(item.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Date
                          Text(
                            _formatDate(item.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                // Actions menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleItemAction(context, item, value);
                  },
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  itemBuilder: (context) => [
                    // Only show "Mark as delivered" for available items
                    if (item.status == ItemStatus.available)
                      PopupMenuItem(
                        value: 'mark_delivered',
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.packageCheck,
                              size: 20.sp,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Marcar como entregado',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 20.sp,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Editar',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Eliminar',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  String _getStatusText(ItemStatus status) {
    switch (status) {
      case ItemStatus.available:
        return 'Disponible';
      case ItemStatus.exchanged:
        return 'Entregado';
      case ItemStatus.paused:
        return 'Pausado';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'Hace 1 semana' : 'Hace ${weeks} semanas';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'Hace 1 mes' : 'Hace ${months} meses';
    }
  }

  void _handleItemAction(BuildContext context, Item item, String action) {
    switch (action) {
      case 'mark_delivered':
        _markItemAsDelivered(context, item);
        break;
      case 'edit':
        _editItem(context, item);
        break;
      case 'delete':
        _confirmDeleteItem(context, item);
        break;
    }
  }

  Future<void> _markItemAsDelivered(BuildContext context, Item item) async {
    try {
      final itemService = ItemService();
      await itemService.changeItemStatus(item.id, ItemStatus.exchanged);
      
      // Update the item in the provider
      final updatedItem = item.copyWith(status: ItemStatus.exchanged);
      ref.read(userItemsProvider.notifier).updateItem(updatedItem);
      
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Item marcado como entregado');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error al marcar como entregado: ${e.toString()}');
      }
    }
  }

  void _editItem(BuildContext context, Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditItemBottomSheet(item: item),
    );
  }

  void _confirmDeleteItem(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        title: Text(
          'Eliminar objeto',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${item.title}"?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Eliminar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  Future<void> _deleteItem(Item item) async {
    try {
      final itemService = ItemService();
      await itemService.deleteItem(item.id);
      
      // Refresh the list
      await ref.read(userItemsProvider.notifier).loadUserItems();
      
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Objeto eliminado correctamente');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error al eliminar: ${e.toString()}');
      }
    }
  }

  void _showCreateItemModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateItemBottomSheet(),
    );
  }


  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.available:
        return Theme.of(context).colorScheme.tertiary; // Tertiary
      case ItemStatus.exchanged:
        return Theme.of(context).colorScheme.secondary;
      case ItemStatus.paused:
        return Theme.of(context).colorScheme.error;
    }
  }
}

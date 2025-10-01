import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/item_photo.dart';
import '../../../shared/models/item.dart';
import '../providers/item_provider.dart';
import '../../../shared/services/item_service.dart';
import '../widgets/create_item_bottom_sheet.dart';
import '../widgets/edit_item_bottom_sheet.dart';

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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Artículos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(userItemsProvider.notifier).loadUserItems();
        },
        child: _buildBody(userItemsState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateItemModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Crear Artículo'),
      ),
    );
  }

  Widget _buildBody(UserItemsState state) {
    if (state.isLoading) {
      return const Center(
        child: LoadingWidget(size: 32),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar artículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(userItemsProvider.notifier).loadUserItems();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes artículos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer artículo para empezar a intercambiar',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateItemModal(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear Primer Artículo'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _buildItemCard(context, item);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          // TODO: Navigate to item detail
        },
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Item photo
              ItemPhoto(
                itemId: item.id,
                width: 80.w,
                height: 80.h,
              ),
              
              SizedBox(width: 12.w),
              
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Status and date
                    Row(
                      children: [
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(item.status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(item.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Date
                        Text(
                          _formatDate(item.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  _handleItemAction(context, item, value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.available:
        return Colors.green;
      case ItemStatus.exchanged:
        return Colors.blue;
      case ItemStatus.paused:
        return Colors.orange;
    }
  }

  String _getStatusText(ItemStatus status) {
    switch (status) {
      case ItemStatus.available:
        return 'Disponible';
      case ItemStatus.exchanged:
        return 'Intercambiado';
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
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleItemAction(BuildContext context, Item item, String action) {
    switch (action) {
      case 'edit':
        _editItem(context, item);
        break;
      case 'delete':
        _confirmDeleteItem(context, item);
        break;
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
        title: const Text('Eliminar Artículo'),
        content: Text('¿Estás seguro de que quieres eliminar "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artículo eliminado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: ${e.toString()}')),
        );
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
}

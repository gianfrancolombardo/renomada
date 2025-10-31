import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../shared/models/item.dart';
import '../../../shared/services/item_service.dart';
import '../../../shared/utils/snackbar_utils.dart';
import '../providers/item_provider.dart';

class EditItemBottomSheet extends ConsumerStatefulWidget {
  final Item item;

  const EditItemBottomSheet({super.key, required this.item});

  @override
  ConsumerState<EditItemBottomSheet> createState() => _EditItemBottomSheetState();
}

class _EditItemBottomSheetState extends ConsumerState<EditItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ItemService _itemService = ItemService();
  
  Uint8List? _selectedPhoto;
  bool _isPickingImage = false;
  bool _isLoading = false;
  late ItemCondition _selectedCondition;
  late ExchangeType _selectedExchangeType;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.item.title;
    _descriptionController.text = widget.item.description ?? '';
    _selectedCondition = widget.item.condition;
    _selectedExchangeType = widget.item.exchangeType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Editar objeto',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    _buildTitleField(),
                    
                    SizedBox(height: 24.h),
                    
                    // Description field
                    _buildDescriptionField(),
                    
                    SizedBox(height: 24.h),
                    
                    // Condition selector
                    _buildConditionSelector(),
                    
                    SizedBox(height: 24.h),
                    
                    // Exchange type selector
                    _buildExchangeTypeSelector(),
                    
                    SizedBox(height: 24.h),
                    
                    // Photo section
                    _buildPhotoSection(),
                    
                    SizedBox(height: 32.h),
                    
                    // Action buttons
                    _buildActionButtons(),
                    
                    // Bottom spacing for safe area
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _titleController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: 'Ej: Libro de cocina, Ropa vintage...',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa un título para tu objeto';
            }
            if (value.trim().length < 3) {
              return 'El título debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _descriptionController,
          enabled: !_isLoading,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Describe tu objeto, su estado, por qué lo regalas...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa una descripción para tu objeto';
            }
            if (value.trim().length < 10) {
              return 'La descripción debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConditionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del objeto',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ItemCondition>(
            segments: [
              ButtonSegment<ItemCondition>(
                value: ItemCondition.likeNew,
                label: Text(ItemCondition.likeNew.label, style: TextStyle(fontSize: 12.sp)),
                icon: Icon(ItemCondition.likeNew.iconData, size: 18.sp),
              ),
              ButtonSegment<ItemCondition>(
                value: ItemCondition.used,
                label: Text(ItemCondition.used.label, style: TextStyle(fontSize: 12.sp)),
                icon: Icon(ItemCondition.used.iconData, size: 18.sp),
              ),
              ButtonSegment<ItemCondition>(
                value: ItemCondition.needsRepair,
                label: Text(ItemCondition.needsRepair.label, style: TextStyle(fontSize: 12.sp)),
                icon: Icon(ItemCondition.needsRepair.iconData, size: 18.sp),
              ),
            ],
            selected: {_selectedCondition},
            onSelectionChanged: _isLoading
                ? null
                : (Set<ItemCondition> newSelection) {
                    setState(() {
                      _selectedCondition = newSelection.first;
                    });
                  },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué quieres hacer?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ExchangeType>(
            segments: [
              ButtonSegment<ExchangeType>(
                value: ExchangeType.gift,
                label: Text(ExchangeType.gift.label, style: TextStyle(fontSize: 12.sp)),
                icon: Icon(ExchangeType.gift.iconData, size: 18.sp),
              ),
              ButtonSegment<ExchangeType>(
                value: ExchangeType.exchange,
                label: Text(ExchangeType.exchange.label, style: TextStyle(fontSize: 12.sp)),
                icon: Icon(ExchangeType.exchange.iconData, size: 18.sp),
              ),
            ],
            selected: {_selectedExchangeType},
            onSelectionChanged: _isLoading
                ? null
                : (Set<ExchangeType> newSelection) {
                    setState(() {
                      _selectedExchangeType = newSelection.first;
                    });
                  },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        
        // Photo preview
        if (_selectedPhoto != null) ...[
          _buildPhotoPreview(),
          SizedBox(height: 16.h),
        ],
        
        // Add photo button
        _buildAddPhotoButton(),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.memory(
              _selectedPhoto!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: GestureDetector(
              onTap: _removePhoto,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading || _isPickingImage ? null : _showPhotoOptions,
      icon: _isPickingImage 
          ? SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_a_photo),
      label: Text(_isPickingImage ? 'Seleccionando...' : 'Cambiar Foto'),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Icon(Icons.check_circle_outline, size: 24.sp),
        label: Text(
          _isLoading ? 'Guardando...' : 'Guardar',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de Galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedPhoto = bytes;
        });
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Error al seleccionar imagen: ${e.toString()}');
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated item
      final updatedItem = widget.item.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        condition: _selectedCondition,
        exchangeType: _selectedExchangeType,
        updatedAt: DateTime.now(),
      );

      // Update item
      await _itemService.updateItem(updatedItem);

      // Update photo if changed
      if (_selectedPhoto != null) {
        // For now, we'll keep the existing photo logic
        // In the future, we can implement photo replacement
      }

      // Refresh user items
      await ref.read(userItemsProvider.notifier).loadUserItems();

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Objeto actualizado correctamente');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error al actualizar: ${e.toString()}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

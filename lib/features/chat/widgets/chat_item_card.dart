import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/models/chat_with_details.dart';
import '../../../shared/models/item.dart';
import '../../../shared/widgets/item_badges.dart';
import '../../../core/config/supabase_config.dart';
import '../../../shared/services/item_service.dart';
import '../../profile/providers/profile_provider.dart';

class ChatItemCard extends ConsumerStatefulWidget {
  final ChatWithDetails chatDetails;
  final VoidCallback? onStatusChanged;
  final Future<void> Function(String message)? onSendSystemMessage;

  const ChatItemCard({
    super.key,
    required this.chatDetails,
    this.onStatusChanged,
    this.onSendSystemMessage,
  });

  @override
  ConsumerState<ChatItemCard> createState() => _ChatItemCardState();
}

class _ChatItemCardState extends ConsumerState<ChatItemCard> {
  bool _isChangingStatus = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.chatDetails.item;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = SupabaseConfig.currentUser?.id;
    final isOwner = currentUserId != null && item.ownerId == currentUserId;
    
    // Debug logs
    print('🖼️ [ChatItemCard] Building card for item: ${item.id}');
    print('🖼️ [ChatItemCard] Item title: ${item.title}');
    print('🖼️ [ChatItemCard] First photo URL: ${widget.chatDetails.firstPhotoUrl}');
    print('🖼️ [ChatItemCard] Photo URL is null: ${widget.chatDetails.firstPhotoUrl == null}');
    print('🖼️ [ChatItemCard] Photo URL length: ${widget.chatDetails.firstPhotoUrl?.length ?? 0}');
    if (widget.chatDetails.firstPhotoUrl != null) {
      print('🖼️ [ChatItemCard] Photo URL starts with https: ${widget.chatDetails.firstPhotoUrl!.startsWith('https')}');
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient background
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.secondaryContainer.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                // Item photo with professional styling
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: widget.chatDetails.firstPhotoUrl != null
                        ? _buildImageWidget(widget.chatDetails.firstPhotoUrl!, colorScheme)
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.surfaceVariant,
                                  colorScheme.surfaceVariant.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              size: 32.sp,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item title with better typography
                      Text(
                        item.title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12.h),
                      // Item badges
                      ItemBadges(item: item),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content section
          if (item.description != null && item.description!.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Text(
                item.description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          
          // Status change section (only for owner and if item is available)
          if (isOwner && item.status == ItemStatus.available)
            Container(
              margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
              child: _buildStatusChangeButton(context, item),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChangeButton(BuildContext context, Item item) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: colorScheme.primaryContainer.withOpacity(0.1),
      ),
      child: InkWell(
        onTap: _isChangingStatus ? null : () => _changeItemStatus(context, item),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isChangingStatus) ...[
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                SizedBox(width: 12.w),
              ] else ...[
                Icon(
                  LucideIcons.packageCheck,
                  size: 18.sp,
                  color: colorScheme.primary,
                ),
                SizedBox(width: 12.w),
              ],
              Text(
                'Marcar como entregado',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _changeItemStatus(BuildContext context, Item item) async {
    setState(() {
      _isChangingStatus = true;
    });

    try {
      final itemService = ItemService();
      await itemService.changeItemStatus(
        item.id,
        ItemStatus.exchanged,
      );

      // Send system message to chat if callback provided
      if (widget.onSendSystemMessage != null) {
        final profile = ref.read(profileDataProvider);
        final username = profile?.username ?? 'Usuario';
        await widget.onSendSystemMessage!('✅ $username marcó este item como entregado');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  LucideIcons.packageCheck,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Item marcado como entregado',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );

        // Notify parent widget about status change
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  LucideIcons.alertCircle,
                  color: Theme.of(context).colorScheme.onError,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Error al cambiar el estado: $e',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingStatus = false;
        });
      }
    }
  }


  Widget _buildImageWidget(String imageUrl, ColorScheme colorScheme) {
    print('🖼️ [ChatItemCard] Building image widget with URL: $imageUrl');
    
    // Try CachedNetworkImage first
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 80.w,
      height: 80.w,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) {
        print('🔄 [ChatItemCard] Loading image placeholder: $url');
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceVariant,
                colorScheme.surfaceVariant.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
            ),
          ),
        );
      },
      errorWidget: (context, url, error) {
        print('❌ [ChatItemCard] CachedNetworkImage error: $error');
        print('❌ [ChatItemCard] Falling back to Image.network');
        
        // Fallback to Image.network
        return Image.network(
          imageUrl,
          width: 80.w,
          height: 80.w,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('✅ [ChatItemCard] Image.network loaded successfully');
              return child;
            }
            print('🔄 [ChatItemCard] Image.network loading: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceVariant,
                    colorScheme.surfaceVariant.withOpacity(0.7),
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('❌ [ChatItemCard] Image.network also failed: $error');
            print('❌ [ChatItemCard] Stack trace: $stackTrace');
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceVariant,
                    colorScheme.surfaceVariant.withOpacity(0.7),
                  ],
                ),
              ),
              child: Icon(
                Icons.image_outlined,
                size: 32.sp,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            );
          },
        );
      },
    );
  }

}

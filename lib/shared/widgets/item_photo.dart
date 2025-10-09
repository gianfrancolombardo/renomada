import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/item_service.dart';

final _itemPhotoProvider = FutureProvider.family<String?, String>((ref, itemId) async {
  return ItemService().getItemFirstPhoto(itemId);
});

class ItemPhoto extends ConsumerWidget {
  final String itemId;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ItemPhoto({
    super.key,
    required this.itemId,
    this.width = 80,
    this.height = 80,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(_itemPhotoProvider(itemId));

    return SizedBox(
      width: width,
      height: height,
      child: photoAsync.when(
        data: (photoUrl) {
          if (photoUrl != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: fit,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => errorWidget ?? Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    LucideIcons.package,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          } else {
            return Container(
              color: Colors.grey.shade200,
              child:               placeholder ?? const Icon(
                LucideIcons.package,
                size: 32,
                color: Colors.grey,
              ),
            );
          }
        },
        loading: () => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, stack) => Container(
          color: Colors.grey.shade200,
          child: errorWidget ?? const Icon(
            LucideIcons.alertCircle,
            size: 32,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

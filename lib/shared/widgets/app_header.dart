import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onSubtitleTap;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.onSubtitleTap,
  });

  @override
  Widget build(BuildContext context) {
    print('📍 [AppHeader] Building header with:');
    print('   - title: $title');
    print('   - subtitle: $subtitle');
    
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: 16.w, // Ensure consistent padding on the edges
      title: subtitle != null && subtitle!.isNotEmpty
          ? GestureDetector(
              onTap: onSubtitleTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h), // Touch area
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Left aligned
                  children: [
                    Text(
                      'Buscando en',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        '$subtitle',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary, // Primary color for emphasis
                          fontWeight: FontWeight.w700, // Stronger weight
                          fontSize: 14.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      LucideIcons.chevronDown,
                      size: 14.sp,
                      color: Theme.of(context).colorScheme.primary, // Match the emphasis color
                    ),
                  ],
                ),
              ),
            )
          : Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
      actions: [
        if (actions != null) ...[
          ...actions!,
          SizedBox(width: 8.w), // Extra padding on the right edge
        ],
      ],
    );
  }

  @override
  Size get preferredSize => subtitle != null ? Size.fromHeight(72.h) : Size.fromHeight(56.h);
}

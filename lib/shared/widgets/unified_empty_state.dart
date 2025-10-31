import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Unified empty state widget for consistent UX across the app
class UnifiedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? primaryButtonText;
  final IconData? primaryButtonIcon;
  final VoidCallback? onPrimaryButtonPressed;
  final String? secondaryButtonText;
  final IconData? secondaryButtonIcon;
  final VoidCallback? onSecondaryButtonPressed;
  final Widget? customContent;

  const UnifiedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.primaryButtonText,
    this.primaryButtonIcon,
    this.onPrimaryButtonPressed,
    this.secondaryButtonText,
    this.secondaryButtonIcon,
    this.onSecondaryButtonPressed,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Icon with solid background - Icono de sección con tertiaryContainer
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48.sp,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 12.h),
            
            // Subtitle
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Custom content (optional)
            if (customContent != null) ...[
              SizedBox(height: 24.h),
              customContent!,
            ],
            
            SizedBox(height: 32.h),
            
            // Buttons
            Column(
              children: [
                // Primary button
                if (primaryButtonText != null && onPrimaryButtonPressed != null)
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: primaryButtonIcon != null
                        ? ElevatedButton.icon(
                            onPressed: onPrimaryButtonPressed,
                            icon: Icon(
                              primaryButtonIcon,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 20.sp,
                            ),
                            label: Text(
                              primaryButtonText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: onPrimaryButtonPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              primaryButtonText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                  ),
                
                // Secondary button
                if (secondaryButtonText != null && onSecondaryButtonPressed != null) ...[
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: secondaryButtonIcon != null
                        ? OutlinedButton.icon(
                            onPressed: onSecondaryButtonPressed,
                            icon: Icon(
                              secondaryButtonIcon,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20.sp,
                            ),
                            label: Text(
                              secondaryButtonText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: onSecondaryButtonPressed,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              secondaryButtonText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}


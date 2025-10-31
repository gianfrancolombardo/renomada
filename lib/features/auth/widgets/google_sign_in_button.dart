import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continuar con Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Image.asset(
                'assets/images/google_logo.png',
                width: 20.w,
                height: 20.w,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if asset is not found
                  return Icon(
                    LucideIcons.chrome,
                    size: 20.sp,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Utility class for showing standardized snackbars across the app
/// All snackbars have consistent styling: color, width, position, and behavior
class SnackbarUtils {
  SnackbarUtils._();

  /// Shows a success message with green background
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: const Color(0xFF4CAF50), // Success green
      action: action,
    );
  }

  /// Shows an error message with red background
  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: const Color(0xFFB3261E), // Error red
      action: action,
    );
  }

  /// Shows an info message with tertiary container color
  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      textColor: Theme.of(context).colorScheme.onTertiaryContainer,
      action: action,
    );
  }

  /// Shows a warning message with orange background
  static void showWarning(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message: message,
      backgroundColor: const Color(0xFFFF9800), // Warning orange
      action: action,
    );
  }

  /// Internal method to show a snackbar with consistent styling
  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    Color? textColor,
    SnackBarAction? action,
  }) {
    // Remove any existing snackbars before showing a new one
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        duration: const Duration(seconds: 4),
        action: action != null
            ? SnackBarAction(
                label: action.label,
                textColor: textColor ?? Colors.white,
                onPressed: action.onPressed,
              )
            : null,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable skeleton loader widget with shimmer effect
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainer,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius ?? BorderRadius.circular(8.r),
        ),
        child: child,
      ),
    );
  }

  /// Factory constructor for circular skeleton (e.g., avatars)
  factory SkeletonLoader.circle({
    required double width,
    required double height,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(width / 2),
    );
  }

  /// Factory constructor for rectangular skeleton
  factory SkeletonLoader.rectangular({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}


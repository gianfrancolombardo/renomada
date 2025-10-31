import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Skeleton loader for feed card
class FeedCardSkeleton extends StatelessWidget {
  const FeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader.rectangular(
            width: double.infinity,
            height: 300.h,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                SkeletonLoader.rectangular(
                  width: 250.w,
                  height: 20.h,
                ),
                SizedBox(height: 8.h),
                // Description skeleton
                SkeletonLoader.rectangular(
                  width: double.infinity,
                  height: 16.h,
                ),
                SizedBox(height: 4.h),
                SkeletonLoader.rectangular(
                  width: 180.w,
                  height: 16.h,
                ),
                SizedBox(height: 16.h),
                // Badges and distance skeleton
                Row(
                  children: [
                    SkeletonLoader.rectangular(
                      width: 80.w,
                      height: 24.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    SizedBox(width: 8.w),
                    SkeletonLoader.rectangular(
                      width: 100.w,
                      height: 24.h,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


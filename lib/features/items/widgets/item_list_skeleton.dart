import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Skeleton loader for item list
class ItemListSkeleton extends StatelessWidget {
  final int itemCount;

  const ItemListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildItemSkeletonItem(context),
        );
      },
    );
  }

  Widget _buildItemSkeletonItem(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // Photo skeleton
          SkeletonLoader.rectangular(
            width: 72.w,
            height: 72.h,
            borderRadius: BorderRadius.circular(8.r),
          ),
          SizedBox(width: 16.w),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                SkeletonLoader.rectangular(
                  width: double.infinity,
                  height: 16.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                SizedBox(height: 12.h),
                // Status and date skeleton
                Row(
                  children: [
                    SkeletonLoader.rectangular(
                      width: 80.w,
                      height: 24.h,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    const Spacer(),
                    SkeletonLoader.rectangular(
                      width: 60.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Menu icon skeleton
          SkeletonLoader.rectangular(
            width: 24.w,
            height: 24.h,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ],
      ),
    );
  }
}


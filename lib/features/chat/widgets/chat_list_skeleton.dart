import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Skeleton loader for chat list items
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: _buildChatSkeletonItem(context),
        );
      },
    );
  }

  Widget _buildChatSkeletonItem(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar skeleton
          SkeletonLoader.circle(
            width: 56.w,
            height: 56.w,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username skeleton
                SkeletonLoader.rectangular(
                  width: 150.w,
                  height: 16.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                SizedBox(height: 8.h),
                // Last message skeleton
                SkeletonLoader.rectangular(
                  width: 200.w,
                  height: 14.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge skeleton (unread count)
              SkeletonLoader.rectangular(
                width: 40.w,
                height: 20.h,
                borderRadius: BorderRadius.circular(10.r),
              ),
              SizedBox(height: 4.h),
              // Time skeleton
              SkeletonLoader.rectangular(
                width: 50.w,
                height: 12.h,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


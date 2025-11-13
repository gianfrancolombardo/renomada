import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Skeleton loader for chat list items
/// Matches the structure of ChatCard widget
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
          padding: EdgeInsets.only(bottom: 8.h),
          child: _buildChatSkeletonItem(context, index),
        );
      },
    );
  }

  Widget _buildChatSkeletonItem(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar skeleton (matches ChatCard: radius 28 = 56x56)
          SkeletonLoader.circle(
            width: 56.w,
            height: 56.w,
          ),
          SizedBox(width: 12.w),
          // Content skeleton (matches ChatCard structure)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // First line: Username and timestamp
                Row(
                  children: [
                    Expanded(
                      child: SkeletonLoader.rectangular(
                        width: double.infinity,
                        height: 16.h,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Time skeleton (small, right-aligned)
                    SkeletonLoader.rectangular(
                      width: 30.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Second line: Item title
                SkeletonLoader.rectangular(
                  width: double.infinity,
                  height: 14.h,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                SizedBox(height: 4.h),
                // Third line: Last message and badge
                Row(
                  children: [
                    Expanded(
                      child: SkeletonLoader.rectangular(
                        width: double.infinity,
                        height: 14.h,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Badge skeleton (unread count) - optional, show randomly
                    if (index % 3 == 0)
                      SkeletonLoader.rectangular(
                        width: 24.w,
                        height: 20.h,
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


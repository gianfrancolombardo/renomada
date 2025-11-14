import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/widgets/skeleton_loader.dart';

/// Skeleton loader for feed card
/// Matches the structure of FeedItemCard (full-screen card with image overlay)
class FeedCardSkeleton extends StatelessWidget {
  const FeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      height: 400.h, // Fixed height matching FeedItemCard
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image skeleton (full background)
            SkeletonLoader.rectangular(
              width: double.infinity,
              height: double.infinity,
            ),
            
            // Gradient overlay (matching FeedItemCard)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 220.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            
            // Content overlay (matching FeedItemCard structure)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User info row skeleton
                    Row(
                      children: [
                        // Avatar skeleton
                        SkeletonLoader.circle(
                          width: 40.w,
                          height: 40.w,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username skeleton
                              SkeletonLoader.rectangular(
                                width: 120.w,
                                height: 16.h,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              SizedBox(height: 4.h),
                              // Distance/time skeleton
                              SkeletonLoader.rectangular(
                                width: 100.w,
                                height: 14.h,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Item title skeleton
                    SkeletonLoader.rectangular(
                      width: double.infinity,
                      height: 24.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    SizedBox(height: 4.h),
                    SkeletonLoader.rectangular(
                      width: 200.w,
                      height: 24.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    SizedBox(height: 8.h),
                    // Badges skeleton
                    Row(
                      children: [
                        SkeletonLoader.rectangular(
                          width: 70.w,
                          height: 24.h,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        SizedBox(width: 8.w),
                        SkeletonLoader.rectangular(
                          width: 80.w,
                          height: 24.h,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    // Description skeleton (optional)
                    SkeletonLoader.rectangular(
                      width: double.infinity,
                      height: 14.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    SizedBox(height: 4.h),
                    SkeletonLoader.rectangular(
                      width: 180.w,
                      height: 14.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


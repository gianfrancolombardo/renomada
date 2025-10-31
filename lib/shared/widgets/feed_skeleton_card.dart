import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FeedSkeletonCard extends StatefulWidget {
  const FeedSkeletonCard({super.key});

  @override
  State<FeedSkeletonCard> createState() => _FeedSkeletonCardState();
}

class _FeedSkeletonCardState extends State<FeedSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      height: 400.h,
      decoration: BoxDecoration(
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
            // Main skeleton background
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surfaceContainerLow,
                          Theme.of(context).colorScheme.surfaceContainerLow.withOpacity(_animation.value * 0.3),
                          Theme.of(context).colorScheme.surfaceContainerLow,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Gradient overlay for text area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 220.h, // Extended to match feed card
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

            // Skeleton content
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
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Container(
                              width: 40.r,
                              height: 40.r,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(_animation.value),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Container(
                                    height: 16.h,
                                    width: 80.w,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(_animation.value),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 4.h),
                              AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Container(
                                    height: 12.h,
                                    width: 120.w,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(_animation.value * 0.6),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Title skeleton
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Container(
                          height: 20.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(_animation.value),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8.h),
                    // Description skeleton
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Container(
                          height: 16.h,
                          width: 200.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(_animation.value * 0.7),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 12.h),
                    // Badges skeleton
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(_animation.value * 0.6),
                                borderRadius: BorderRadius.circular(20.r), // Totalmente redondeado como el real
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(_animation.value * 0.7),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Container(
                                    width: 40.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(_animation.value * 0.7),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8.w),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(_animation.value * 0.6),
                                borderRadius: BorderRadius.circular(20.r), // Totalmente redondeado como el real
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(_animation.value * 0.7),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Container(
                                    width: 50.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(_animation.value * 0.7),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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

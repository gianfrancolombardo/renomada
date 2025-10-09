import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/feed/providers/feed_provider.dart';

class FeedItemCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const FeedItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    // Start dragging
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });

    // Update animation immediately based on drag progress
    final progress = (_dragOffset / MediaQuery.of(context).size.width).clamp(-1.0, 1.0);
    _animationController.value = progress.abs();
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.2; // Even more reduced threshold
    final velocityThreshold = 600; // Reduced velocity threshold for easier swiping

    // More robust swipe detection - any significant movement triggers swipe
    final shouldSwipe = _dragOffset.abs() > threshold || 
                       velocity.abs() > velocityThreshold;

    if (shouldSwipe) {
      if (_dragOffset > 0) {
        // Swipe right - Like
        _animateSwipeRight();
      } else {
        // Swipe left - Pass
        _animateSwipeLeft();
      }
    } else {
      // Return to center
      _animateReturnToCenter();
    }
  }

  void _animateSwipeRight() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Smooth animation to swipe off screen
    _animationController.forward().then((_) {
      setState(() {
        _dragOffset = screenWidth * 1.5;
      });
      
      // Call the callback after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onSwipeRight?.call();
      });
    });
  }

  void _animateSwipeLeft() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Smooth animation to swipe off screen for dislike (no loading)
    _animationController.forward().then((_) {
      setState(() {
        _dragOffset = -screenWidth * 1.5;
      });
      
      // Call the callback after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onSwipeLeft?.call();
      });
    });
  }

  void _animateReturnToCenter() {
    // Smooth return animation
    _animationController.reverse().then((_) {
      setState(() {
        _dragOffset = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * (_dragOffset > 0 ? 1 : -1),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  height: 400.h, // Fixed height for consistent layout
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
                        // Progressive swipe indicators - appear immediately during swipe
                        if (_dragOffset > 5) // Reduced threshold for immediate feedback
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                final progress = (_dragOffset / screenWidth).clamp(0.0, 1.0);
                                final opacity = progress * 0.8; // Start appearing immediately but cap at 0.8
                                final scale = 0.7 + (0.3 * progress);
                                final textOpacity = progress > 0.3 ? (progress - 0.3) / 0.7 : 0.0; // Text appears after 30% progress
                                
                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16.r),
                                        color: Colors.green.withOpacity(0.15 * progress),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.7 * progress),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Opacity(
                                          opacity: textOpacity,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.95),
                                              borderRadius: BorderRadius.circular(16.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.withOpacity(0.4 * progress),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '¡Lo quiero!',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 22.sp,
                                                letterSpacing: 0.8,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (_dragOffset < -5) // Reduced threshold for immediate feedback
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final screenWidth = MediaQuery.of(context).size.width;
                                final progress = (_dragOffset.abs() / screenWidth).clamp(0.0, 1.0);
                                final opacity = progress * 0.8; // Start appearing immediately but cap at 0.8
                                final scale = 0.7 + (0.3 * progress);
                                final textOpacity = progress > 0.3 ? (progress - 0.3) / 0.7 : 0.0; // Text appears after 30% progress
                                
                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16.r),
                                        color: Colors.red.withOpacity(0.15 * progress),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.7 * progress),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Opacity(
                                          opacity: textOpacity,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.95),
                                              borderRadius: BorderRadius.circular(16.r),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red.withOpacity(0.4 * progress),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'No gracias',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 22.sp,
                                                letterSpacing: 0.8,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Image background
                        if (widget.item.firstPhotoUrl != null)
                          Image.network(
                            widget.item.firstPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context).colorScheme.surfaceContainerLow,
                                child: Icon(
                                  LucideIcons.image,
                                  size: 48.sp,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Theme.of(context).colorScheme.surfaceContainerLow,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            color: Theme.of(context).colorScheme.surfaceContainerLow,
                            child: Icon(
                              LucideIcons.image,
                              size: 48.sp,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),

                        // Gradient overlay for better text readability
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 180.h, // Increased from 140.h to 180.h
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.9),
                                ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Content overlay
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
                                // User info row
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20.r,
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      backgroundImage: widget.item.owner.avatarUrl != null 
                                          ? NetworkImage(widget.item.owner.avatarUrl!)
                                          : null,
                                      child: widget.item.owner.avatarUrl == null 
                                          ? Text(
                                              widget.item.owner.username?.isNotEmpty == true 
                                                  ? widget.item.owner.username![0].toUpperCase()
                                                  : 'U',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.item.owner.username ?? 'Usuario',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '${widget.item.distanceKm.toStringAsFixed(1)} km de distancia',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Commented out timestamp for now
                                    // Text(
                                    //   _formatTimestamp(widget.item.item.createdAt),
                                    //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    //     color: Colors.white.withOpacity(0.8),
                                    //   ),
                                    // ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                // Item title
                                Text(
                                  widget.item.item.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.item.item.description?.isNotEmpty == true) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    widget.item.item.description!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/feed/providers/feed_provider.dart';
import 'item_badges.dart';

class FeedItemCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final bool showHintAnimation;

  const FeedItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.showHintAnimation = false,
  });

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _hintAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _hintAnimation;
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

    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 6800),
      vsync: this,
    );

    _hintAnimation = TweenSequence<double>([
      // Swipe Left (No Gracias) first with enough distance to trigger the red badge
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -100.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      // Bounce back to center and overshoot to Right (Lo Quiero) to trigger the green badge
      TweenSequenceItem(
        tween: Tween(begin: -100.0, end: 120.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 45,
      ),
      // Settle back to center
      TweenSequenceItem(
        tween: Tween(begin: 120.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
    ]).animate(_hintAnimationController);

    _hintAnimationController.addListener(() {
      setState(() {
        _dragOffset = _hintAnimation.value;
      });
      // Fallback screenWidth if context not ready usually doesn't happen because animation starts after delay,
      // but we use 400 as a safe fallback just in case.
      double screenWidth = 400.0;
      if (mounted) {
        screenWidth = MediaQuery.of(context).size.width;
      }
      final progress = (_dragOffset.abs() / screenWidth).clamp(0.0, 1.0);
      _animationController.value = progress;
    });

    if (widget.showHintAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            _hintAnimationController.forward();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _hintAnimationController.dispose();
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
    final threshold = screenWidth * 0.15; // Reduced threshold for easier swiping
    final velocityThreshold = 400; // Reduced velocity threshold for easier swiping

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

  /// Full-card tint + icon/label in a corner; aligns with card axes (no extra tilt).
  Widget _buildSwipeTintOverlay(BuildContext context, {required bool forLike}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final progress = (_dragOffset.abs() / screenWidth).clamp(0.0, 1.0);
    final textOpacity = progress < 0.05
        ? 0.0
        : (progress < 0.35 ? (progress - 0.05) / 0.3 : 1.0);
    final bgOpacity = (progress * 0.72).clamp(0.0, 0.52);

    final baseColor =
        forLike ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: baseColor.withValues(alpha: bgOpacity),
            ),
            Positioned(
              top: 28.h,
              left: forLike ? 20.w : null,
              right: forLike ? null : 20.w,
              child: Opacity(
                opacity: textOpacity,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.48),
                  child: Column(
                    crossAxisAlignment: forLike
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        forLike
                            ? LucideIcons.checkCircle2
                            : LucideIcons.xCircle,
                        color: Colors.white,
                        size: 44.sp,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        forLike ? '¡Lo quiero!' : 'No gracias',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                        textAlign:
                            forLike ? TextAlign.left : TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                            height: 220.h, // Extended from 180.h to 220.h for better readability
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
                                    _buildUserAvatar(context),
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
                                            widget.item.hasDistance
                                                ? '${widget.item.distanceKm!.toStringAsFixed(1)} km de distancia'
                                                : _formatTimeAgo(widget.item.item.createdAt),
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
                                SizedBox(height: 8.h),
                                // Item badges
                                ItemBadges(item: widget.item.item),
                                if (widget.item.item.description?.isNotEmpty == true) ...[
                                  SizedBox(height: 6.h),
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

                        // Full-card swipe tint + corner label (drawn on top)
                        if (_dragOffset > 5)
                          _buildSwipeTintOverlay(context, forLike: true),
                        if (_dragOffset < -5)
                          _buildSwipeTintOverlay(context, forLike: false),

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

  Widget _buildUserAvatar(BuildContext context) {
    final avatarUrl = widget.item.owner.avatarUrl;
    final username = widget.item.owner.username;
    final initial = username?.isNotEmpty == true 
        ? username![0].toUpperCase() 
        : 'U';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20.r,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: 40.r,
                  height: 40.r,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Error loading avatar: $error');
                    return Text(
                      initial,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              )
            : Text(
                initial,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'Publicado hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Publicado hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Publicado hace ${difference.inMinutes} min';
    } else {
      return 'Publicado ahora';
    }
  }
}
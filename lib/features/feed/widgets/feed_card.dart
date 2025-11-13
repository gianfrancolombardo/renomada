import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/feed_provider.dart';
import '../../../shared/widgets/avatar_image.dart';
import '../../../shared/widgets/item_badges.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/models/item.dart';

class FeedCard extends StatefulWidget {
  final FeedItem feedItem;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const FeedCard({
    super.key,
    required this.feedItem,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard>
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

    // Update animation based on drag
    final progress = (_dragOffset / MediaQuery.of(context).size.width).clamp(-1.0, 1.0);
    _animationController.value = progress.abs();
  }

  void _onPanEnd(DragEndDetails details) {

    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = MediaQuery.of(context).size.width * 0.3;

    if (_dragOffset.abs() > threshold || velocity.abs() > 500) {
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
    _animationController.forward().then((_) {
      widget.onSwipeRight();
    });
  }

  void _animateSwipeLeft() {
    _animationController.reverse().then((_) {
      widget.onSwipeLeft();
    });
  }

  void _animateReturnToCenter() {
    _animationController.animateTo(0.5);
    setState(() {
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.feedItem.item;
    final owner = widget.feedItem.owner;

    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * (_dragOffset > 0 ? 1 : -1),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo section
                          _buildPhotoSection(),
                          
                          // Content section
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Owner info
                                  _buildOwnerInfo(owner, item),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Item title
                                  Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Item description
                                  if (item.description != null && item.description!.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        item.description!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Item badges
                                  ItemBadges(item: item),
                                  
                                  const Spacer(),
                                  
                                  // Action buttons
                                  _buildActionButtons(),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoSection() {
    final photoUrl = widget.feedItem.firstPhotoUrl;
    
    return Container(
      height: 300,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: photoUrl != null
          ? CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          : Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }

  Widget _buildOwnerInfo(UserProfile owner, Item item) {
    final hasDistance = widget.feedItem.hasDistance;
    final distance = widget.feedItem.distanceKm;
    
    return Row(
      children: [
        AvatarImage(
          avatarUrl: owner.avatarUrl,
          radius: 20,
          backgroundColor: Colors.grey.shade300,
          placeholder: const Icon(Icons.person, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                owner.username ?? 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                hasDistance
                    ? '${distance!.toStringAsFixed(1)} km de distancia'
                    : _formatTimeAgo(item.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (owner.lastSeenAt != null)
          Text(
            _formatLastSeen(owner.lastSeenAt!),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pass button
        _buildActionButton(
          icon: Icons.close,
          color: Colors.red,
          onTap: widget.onSwipeLeft,
        ),
        
        // Like button
        _buildActionButton(
          icon: Icons.favorite,
          color: Colors.green,
          onTap: widget.onSwipeRight,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
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

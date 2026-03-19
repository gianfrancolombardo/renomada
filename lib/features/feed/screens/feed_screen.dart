import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/widgets/feed_item_card.dart';
import '../../../shared/widgets/radius_selector.dart';
import '../providers/feed_provider.dart';
import '../../../shared/services/feed_service.dart';
import '../widgets/feed_empty_state.dart';
import '../widgets/feed_loading_state.dart';
import '../widgets/feed_error_state.dart';
import '../../profile/providers/location_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/services/location_service.dart';
import '../widgets/manual_location_selector.dart';

class FeedScreen extends ConsumerStatefulWidget {
  final bool isRadiusSelectorVisible;
  final VoidCallback onToggleRadiusSelector;

  const FeedScreen({
    super.key,
    this.isRadiusSelectorVisible = false,
    required this.onToggleRadiusSelector,
  });

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isNavigatingToChat = false;
  bool _isInitializing = true; // Track initial loading phase
  bool _hasShownHintAnimation = false;

  bool _canUseLocationFeed(LocationState locationState) {
    return locationState.hasLocation;
  }

  @override
  void initState() {
    super.initState();
    // Load feed when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeed().then((_) {
        // Mark initialization as complete after a short delay to ensure smooth transition
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
        });
      });
    });
  }

  Future<void> _initializeFeed() async {
    final locationState = ref.read(locationProvider);
    
    // If we already have location, load feed immediately
    if (_canUseLocationFeed(locationState)) {
      await ref
          .read(feedProvider.notifier)
          .loadFeed(refresh: true);
      return;
    }
    
    // If permission is granted but no location, try to get it silently
    if (locationState.isPermissionGranted && !locationState.hasLocation) {
      await ref.read(locationProvider.notifier).getCurrentLocation();
      
      // Wait a bit for the location to be saved to profile
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load feed if we now have location
      final updatedLocationState = ref.read(locationProvider);
      if (updatedLocationState.hasLocation) {
        await ref
            .read(feedProvider.notifier)
            .loadFeed(refresh: true);
      }
    }
    
    // If no permission, we don't load anything yet. 
    // The UI will show the ManualLocationSelector.
    if (!locationState.isPermissionGranted) {
      // await ref.read(feedProvider.notifier).loadFeedWithoutLocation(refresh: true);
      // We do nothing here, letting the UI show the manual selector
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    // Update location first, then load feed
    final locationState = ref.read(locationProvider);
    
    if (locationState.hasLocation && locationState.isManual) {
      print('🔄 [FeedScreen] Refreshing nearby feed using manual location');
      await ref.read(feedProvider.notifier).refresh();
    } else if (locationState.isPermissionGranted && locationState.hasLocation) {
      print('🔄 [FeedScreen] Refreshing nearby feed using GPS location');
      await ref.read(locationProvider.notifier).getCurrentLocation();
      await ref.read(feedProvider.notifier).refresh();
    } else if (locationState.isPermissionGranted && !locationState.hasLocation) {
      await ref.read(locationProvider.notifier).getCurrentLocation();
      final updatedLocationState = ref.read(locationProvider);
      if (updatedLocationState.hasLocation) {
        await ref.read(feedProvider.notifier).refresh();
      } else {
        print('🔄 [FeedScreen] Refresh fallback to recent feed (no location available)');
        await ref.read(feedProvider.notifier).loadFeedWithoutLocation(refresh: true);
      }
    } else {
      // No permission, refresh recent items
      print('🔄 [FeedScreen] Refresh fallback to recent feed (no permission, no location)');
      await ref.read(feedProvider.notifier).loadFeedWithoutLocation(refresh: true);
    }
  }

  void _onRadiusChanged(double radiusKm) {
    ref.read(feedProvider.notifier).updateRadius(radiusKm);
  }

  void _onSwipeLeft(String itemId) {
    // Pass - remove from feed and record interaction
    ref.read(feedProvider.notifier).removeItem(itemId);
    _recordInteraction(itemId, 'pass');
    _moveToNextCard();
  }

  void _onSwipeRight(String itemId) async {
    // Like - remove from feed and record interaction
    ref.read(feedProvider.notifier).removeItem(itemId);
    
    // Show loading overlay
    setState(() {
      _isNavigatingToChat = true;
    });
    
    try {
      // Record interaction and get chatId
      final feedService = FeedService();
      final chatId = await feedService.recordInteraction(
        itemId: itemId,
        action: 'like',
      );
      
      // Navigate to chat after a short delay to allow the loading animation to complete
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isNavigatingToChat = false;
          });
          
          if (chatId != null) {
            context.go('/chat/$chatId');
          } else {
            // Fallback if no chatId returned
            print('Warning: No chatId returned for like action');
          }
        }
      });
    } catch (e) {
      print('Error recording like interaction: $e');
      if (mounted) {
        setState(() {
          _isNavigatingToChat = false;
        });
      }
    }
  }

  void _recordInteraction(String itemId, String action) {
    // Record interaction in background
    Future.microtask(() async {
      try {
        final chatId = await ref.read(feedProvider.notifier).feedService.recordInteraction(
          itemId: itemId,
          action: action,
        );
        
        // If it's a like and we got a chatId, navigate to chat
        if (action == 'like' && chatId != null) {
          print('🚀 [FeedScreen] Navigating to chat: $chatId');
          if (mounted) {
            context.push('/chat/$chatId');
          }
        }
      } catch (e) {
        print('Error recording interaction: $e');
      }
    });
  }

  void _moveToNextCard() {
    if (_currentIndex < ref.read(feedProvider).items.length - 1) {
      _currentIndex++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Load more items if available
      ref.read(feedProvider.notifier).loadMoreItems();
    }
  }




  Widget _buildActionButtons(FeedState feedState) {
    if (feedState.items.isEmpty) return const SizedBox.shrink();
    
    // Ensure _currentIndex is within bounds
    final safeIndex = _currentIndex.clamp(0, feedState.items.length - 1);
    final currentItem = feedState.items[safeIndex];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          GestureDetector(
            onTap: () => _onSwipeLeft(currentItem.item.id),
            child: Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.x,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: 28.sp,
              ),
            ),
          ),
          
          // Like button
          GestureDetector(
            onTap: () => _onSwipeRight(currentItem.item.id),
            child: Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.heart,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final locationState = ref.watch(locationProvider);
    final profileState = ref.watch(profileProvider);

    // Listen for location changes and load feed when location becomes available
    ref.listen<LocationState>(locationProvider, (previous, next) {
      if (previous?.hasLocation != next.hasLocation && 
          next.hasLocation && 
          next.isPermissionGranted &&
          feedState.items.isEmpty) {
        // Location just became available via GPS. Wait a bit for it to be saved to profile.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ref.read(feedProvider.notifier).loadFeed(refresh: true);
          }
        });
      }
    });

    return Stack(
      children: [
        _buildBody(feedState, locationState, profileState),
        
        // Loading overlay for chat navigation
        if (_isNavigatingToChat)
          Container(
            color: Theme.of(context).colorScheme.scrim.withOpacity(0.8),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        size: 40.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      '¡Perfecto!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Conectando...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(feedState, locationState, profileState) {
    return Column(
      children: [
        // Radius selector - now toggleable
        // Show if we have any location (GPS or manual)
        if (locationState.hasLocation)
          RadiusSelector(
            selectedRadius: feedState.selectedRadiusKm.toInt(),
            onRadiusChanged: (radius) => _onRadiusChanged(radius.toDouble()),
            isVisible: widget.isRadiusSelectorVisible,
          ),
        
        // Main content
        Expanded(
          child: _buildContent(feedState, locationState),
        ),
        
        // Action buttons below the content (show only when there are items and a location is set)
        if (feedState.items.isNotEmpty && locationState.hasLocation)
          _buildActionButtons(feedState),
      ],
    );
  }

  Widget _buildContent(FeedState feedState, LocationState locationState) {
    // Show skeleton during initial loading phase (checking location + loading feed)
    if (_isInitializing || (feedState.isLoading && feedState.items.isEmpty)) {
      return const FeedLoadingState();
    }

    // If we have a manual location set or a real location, show the feed content
    if (locationState.hasLocation) {
      return _buildFeedContent(feedState, locationState);
    }

    // If permission is granted but no location yet, show loading while trying to get it
    if (locationState.isPermissionGranted) {
      if (locationState.isLoading) {
        return const FeedLoadingState();
      }
      // If we are here, it means auto-location failed even with permission
      // Show manual selector
      return ManualLocationSelector(
        onLocationSelected: () {
          ref.read(feedProvider.notifier).loadFeed(
                refresh: true,
              );
        },
      );
    }

    // If no permission and no manual location, show manual selector
    return ManualLocationSelector(
      onLocationSelected: () {
        ref.read(feedProvider.notifier).loadFeed(
              refresh: true,
            );
      },
    );
  }

  Widget _buildFeedContent(FeedState feedState, LocationState locationState) {
    // Show feed content
    if (feedState.isLoading && feedState.items.isEmpty) {
      return const FeedLoadingState();
    }

    if (feedState.hasError) {
      return FeedErrorState(
        error: feedState.error!,
        onRetry: () {
          if (_canUseLocationFeed(locationState)) {
            ref.read(feedProvider.notifier).loadFeed(
                  refresh: true,
                );
          } else {
            ref.read(feedProvider.notifier).loadFeedWithoutLocation(refresh: true);
          }
        },
      );
    }

    if (feedState.isEmpty) {
      return FeedEmptyState(
        selectedRadius: feedState.selectedRadiusKm,
        onRadiusChanged: _onRadiusChanged,
        onRefresh: _onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable PageView scrolling
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Load more items when approaching the end (only if has location)
          if (index >= feedState.items.length - 3) {
            if (_canUseLocationFeed(locationState)) {
              ref.read(feedProvider.notifier).loadMoreItems();
            }
            // No pagination for recent items (max 10)
          }
        },
        itemCount: feedState.items.length + (feedState.items.length == 10 && !_canUseLocationFeed(locationState) ? 1 : 0),
        itemBuilder: (context, index) {
          // Show limit message after 10 items if no location
          if (!_canUseLocationFeed(locationState) && 
              feedState.items.length == 10 && 
              index == 10) {
            return _buildLimitReachedMessage(locationState);
          }

          if (index >= feedState.items.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedItem = feedState.items[index];
          
          bool showHint = false;
          if (index == 0 && !_hasShownHintAnimation) {
            showHint = true;
            // Schedule setting flag to true to avoid modifying state during build in a way that affects other widgets,
            // though just setting it is usually fine.
            _hasShownHintAnimation = true;
          }
          
          return FeedItemCard(
            item: feedItem,
            showHintAnimation: showHint,
            onTap: () {
              // TODO: Navigate to item details
            },
            onSwipeLeft: () => _onSwipeLeft(feedItem.item.id),
            onSwipeRight: () => _onSwipeRight(feedItem.item.id),
          );
        },
      ),
    );
  }

  Widget _buildLimitReachedMessage(LocationState locationState) {
    final isPermanentlyDenied = locationState.permissionStatus == LocationPermissionStatus.permanentlyDenied;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  LucideIcons.info,
                  size: 32.sp,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Límite alcanzado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'Has visto los 10 objetos más recientes disponibles sin ubicación.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Activa la ubicación para ver objetos cerca de ti y acceder a más contenido.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    if (isPermanentlyDenied) {
                      context.push('/location-recovery');
                    } else {
                      context.push('/location-permission');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        isPermanentlyDenied ? 'Abrir configuración' : 'Activar ubicación',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

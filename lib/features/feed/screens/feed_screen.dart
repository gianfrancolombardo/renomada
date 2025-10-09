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

  @override
  void initState() {
    super.initState();
    // Load feed when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFeed();
    });
  }

  Future<void> _initializeFeed() async {
    final locationState = ref.read(locationProvider);
    
    // If we already have location, load feed immediately
    if (locationState.isPermissionGranted && locationState.hasLocation) {
      await ref.read(feedProvider.notifier).loadFeed(refresh: true);
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
        await ref.read(feedProvider.notifier).loadFeed(refresh: true);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedIfPossible() async {
    final locationState = ref.read(locationProvider);
    
    if (locationState.isPermissionGranted && locationState.hasLocation) {
      await ref.read(feedProvider.notifier).loadFeed(refresh: true);
    } else if (locationState.isPermissionGranted && !locationState.hasLocation) {
      // If permission is granted but no location, try to get it silently
      await ref.read(locationProvider.notifier).getCurrentLocation();
      final updatedLocationState = ref.read(locationProvider);
      if (updatedLocationState.hasLocation) {
        await ref.read(feedProvider.notifier).loadFeed(refresh: true);
      }
    }
  }

  Future<void> _onRefresh() async {
    // Update location first, then load feed
    final locationState = ref.read(locationProvider);
    
    if (locationState.isPermissionGranted) {
      await ref.read(locationProvider.notifier).getCurrentLocation();
      await ref.read(feedProvider.notifier).refresh();
    } else {
      // Show location permission request
      await ref.read(locationProvider.notifier).requestLocationPermission();
      if (ref.read(locationProvider).isPermissionGranted) {
        await ref.read(feedProvider.notifier).refresh();
      }
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
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          GestureDetector(
            onTap: () => _onSwipeLeft(currentItem.item.id),
            child: Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.x,
                color: Colors.white,
                size: 32.sp,
              ),
            ),
          ),
          
          // Like button
          GestureDetector(
            onTap: () => _onSwipeRight(currentItem.item.id),
            child: Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.heart,
                color: Colors.white,
                size: 32.sp,
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
        // Location just became available, wait a bit for it to be saved to profile
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
            color: Colors.green.withOpacity(0.8),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60.w,
                      height: 60.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      '¡Perfecto!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 24.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Abriendo chat...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.green.shade700,
                        fontSize: 16.sp,
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
        if (locationState.isPermissionGranted && locationState.hasLocation)
          RadiusSelector(
            selectedRadius: feedState.selectedRadiusKm.toInt(),
            onRadiusChanged: (radius) => _onRadiusChanged(radius.toDouble()),
            isVisible: widget.isRadiusSelectorVisible,
          ),
        
        // Main content
        Expanded(
          child: _buildContent(feedState, locationState),
        ),
        
        // Action buttons below the content
        if (locationState.isPermissionGranted && locationState.hasLocation && 
            feedState.items.isNotEmpty)
          _buildActionButtons(feedState),
      ],
    );
  }

  Widget _buildContent(FeedState feedState, LocationState locationState) {
    // Check location permission first
    if (!locationState.isPermissionGranted) {
      return _buildLocationPermissionRequired();
    }

    // If permission is granted but no location, show loading while trying to get it
    if (!locationState.hasLocation) {
      if (locationState.isLoading) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Obteniendo ubicación...'),
            ],
          ),
        );
      }
      // If not loading and no location, try to get it automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(locationProvider.notifier).getCurrentLocation();
        }
      });
      return _buildLocationRequired();
    }

    // Show feed content
    if (feedState.isLoading && feedState.items.isEmpty) {
      return const FeedLoadingState();
    }

    if (feedState.hasError) {
      return FeedErrorState(
        error: feedState.error!,
        onRetry: () => ref.read(feedProvider.notifier).loadFeed(refresh: true),
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
          
          // Load more items when approaching the end
          if (index >= feedState.items.length - 3) {
            ref.read(feedProvider.notifier).loadMoreItems();
          }
        },
        itemCount: feedState.items.length,
        itemBuilder: (context, index) {
          if (index >= feedState.items.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedItem = feedState.items[index];
          
          return FeedItemCard(
            item: feedItem,
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

  Widget _buildLocationPermissionRequired() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  size: 40.sp,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Permisos de Ubicación Requeridos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'Para mostrarte artículos cerca de ti, necesitamos acceso a tu ubicación.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(locationProvider.notifier).requestLocationPermission();
                    if (ref.read(locationProvider).isPermissionGranted) {
                      await _loadFeedIfPossible();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Conceder Permisos',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRequired() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.my_location_outlined,
                  size: 40.sp,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Obteniendo Ubicación',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'Estamos obteniendo tu ubicación actual para mostrarte artículos cercanos.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }


}

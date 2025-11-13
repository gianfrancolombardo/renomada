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
    
    // If no permission, load recent items without location
    if (!locationState.isPermissionGranted) {
      await ref.read(feedProvider.notifier).loadFeedWithoutLocation(refresh: true);
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
    } else {
      // No permission, load recent items
      await ref.read(feedProvider.notifier).loadFeedWithoutLocation(refresh: true);
    }
  }

  Future<void> _onRefresh() async {
    // Update location first, then load feed
    final locationState = ref.read(locationProvider);
    
    if (locationState.isPermissionGranted && locationState.hasLocation) {
      await ref.read(locationProvider.notifier).getCurrentLocation();
      await ref.read(feedProvider.notifier).refresh();
    } else if (locationState.isPermissionGranted && !locationState.hasLocation) {
      await ref.read(locationProvider.notifier).getCurrentLocation();
      final updatedLocationState = ref.read(locationProvider);
      if (updatedLocationState.hasLocation) {
        await ref.read(feedProvider.notifier).refresh();
      } else {
        await ref.read(feedProvider.notifier).loadFeedWithoutLocation(refresh: true);
      }
    } else {
      // No permission, refresh recent items
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
        // Banner informativo cuando no hay ubicación
        if (!locationState.isPermissionGranted || !locationState.hasLocation)
          _buildLocationInfoBanner(locationState),
        
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
        
        // Action buttons below the content (show when there are items, regardless of location)
        if (feedState.items.isNotEmpty)
          _buildActionButtons(feedState),
      ],
    );
  }

  Widget _buildContent(FeedState feedState, LocationState locationState) {
    // If permission is granted but no location, show loading while trying to get it
    if (locationState.isPermissionGranted && !locationState.hasLocation) {
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
      // Show recent items while trying to get location
      return _buildFeedContent(feedState, locationState);
    }

    // If no permission, show recent items (feed limitado)
    if (!locationState.isPermissionGranted) {
      return _buildFeedContent(feedState, locationState);
    }

    // Show feed content (with location)
    return _buildFeedContent(feedState, locationState);
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
          if (locationState.isPermissionGranted && locationState.hasLocation) {
            ref.read(feedProvider.notifier).loadFeed(refresh: true);
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
            if (locationState.isPermissionGranted && locationState.hasLocation) {
              ref.read(feedProvider.notifier).loadMoreItems();
            }
            // No pagination for recent items (max 10)
          }
        },
        itemCount: feedState.items.length + (feedState.items.length == 10 && !locationState.isPermissionGranted ? 1 : 0),
        itemBuilder: (context, index) {
          // Show limit message after 10 items if no location
          if (!locationState.isPermissionGranted && 
              feedState.items.length == 10 && 
              index == 10) {
            return _buildLimitReachedMessage(locationState);
          }

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

  Widget _buildLocationInfoBanner(LocationState locationState) {
    final isPermanentlyDenied = locationState.permissionStatus == LocationPermissionStatus.permanentlyDenied;
    
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isPermanentlyDenied ? LucideIcons.mapPinOff : LucideIcons.mapPin,
              size: 20.sp,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPermanentlyDenied 
                      ? 'Ubicación bloqueada'
                      : 'Ubicación desactivada',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Mostrando últimos objetos, no los más cercanos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () {
              if (isPermanentlyDenied) {
                context.push('/location-recovery');
              } else {
                context.push('/location-permission');
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isPermanentlyDenied ? 'Abrir' : 'Activar',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

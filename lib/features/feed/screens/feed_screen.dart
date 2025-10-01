import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_card.dart';
import '../widgets/radius_selector.dart';
import '../widgets/feed_empty_state.dart';
import '../widgets/feed_loading_state.dart';
import '../widgets/feed_error_state.dart';
import '../../profile/providers/location_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/avatar_image.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

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

  void _onSwipeRight(String itemId) {
    // Like - remove from feed and record interaction
    ref.read(feedProvider.notifier).removeItem(itemId);
    _recordInteraction(itemId, 'like');
    _moveToNextCard();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReNomada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              // Navigate to location permission screen
              context.push('/location-permission');
            },
          ),
          _buildProfileDropdown(context, profileState.profile),
        ],
      ),
      body: Column(
        children: [
          // Radius selector
          if (locationState.isPermissionGranted && locationState.hasLocation)
            RadiusSelector(
              selectedRadius: feedState.selectedRadiusKm,
              onRadiusChanged: _onRadiusChanged,
            ),
          
          // Main content
          Expanded(
            child: _buildContent(feedState, locationState),
          ),
        ],
      ),
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
          
          return FeedCard(
            feedItem: feedItem,
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Permisos de Ubicación Requeridos',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Para mostrarte artículos cerca de ti, necesitamos acceso a tu ubicación.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await ref.read(locationProvider.notifier).requestLocationPermission();
                if (ref.read(locationProvider).isPermissionGranted) {
                  await _loadFeedIfPossible();
                }
              },
              child: const Text('Conceder Permisos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.my_location,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Obteniendo Ubicación',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos obteniendo tu ubicación actual para mostrarte artículos cercanos.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDropdown(BuildContext context, profile) {
    return PopupMenuButton<String>(
      icon: AvatarImage(
        avatarUrl: profile?.avatarUrl,
        radius: 16,
        backgroundColor: Colors.grey.shade300,
        placeholder: const Icon(Icons.person, size: 20),
      ),
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.push('/profile');
            break;
          case 'items':
            context.push('/my-items');
            break;
          case 'chats':
            context.push('/chats');
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 8),
              Text('Mi Perfil'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'items',
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined),
              SizedBox(width: 8),
              Text('Mis Artículos'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'chats',
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline),
              SizedBox(width: 8),
              Text('Conversaciones'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Cerrar Sesión'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }
}

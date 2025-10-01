import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/item.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/feed_service.dart';

// Feed item with owner information
class FeedItem {
  final Item item;
  final UserProfile owner;
  final double distanceKm;
  String? firstPhotoUrl;

  FeedItem({
    required this.item,
    required this.owner,
    required this.distanceKm,
    this.firstPhotoUrl,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      item: Item.fromJson(json['item']),
      owner: UserProfile.fromJson(json['owner']),
      distanceKm: (json['distance_km'] as num).toDouble(),
      firstPhotoUrl: json['first_photo_url'] as String?,
    );
  }
}

// Feed state
class FeedState {
  final List<FeedItem> items;
  final bool isLoading;
  final String? error;
  final double selectedRadiusKm;
  final bool hasMoreItems;
  final int currentPage;

  const FeedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.selectedRadiusKm = 10.0,
    this.hasMoreItems = true,
    this.currentPage = 0,
  });

  FeedState copyWith({
    List<FeedItem>? items,
    bool? isLoading,
    String? error,
    double? selectedRadiusKm,
    bool? hasMoreItems,
    int? currentPage,
  }) {
    return FeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => items.isEmpty && !isLoading;
  bool get hasError => error != null;
}

// Feed notifier
class FeedNotifier extends StateNotifier<FeedState> {
  final FeedService _feedService;

  FeedNotifier(this._feedService) : super(const FeedState());

  // Expose service for external use
  FeedService get feedService => _feedService;

  // Load feed items
  Future<void> loadFeed({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        items: [],
        currentPage: 0,
        hasMoreItems: true,
        isLoading: true,
        error: null,
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final newItems = await _feedService.getFeedItems(
        radiusKm: state.selectedRadiusKm,
        page: refresh ? 0 : state.currentPage,
      );

      final updatedItems = refresh 
          ? newItems 
          : [...state.items, ...newItems];

      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
        hasMoreItems: newItems.length >= 20, // Assuming 20 items per page
        currentPage: refresh ? 1 : state.currentPage + 1,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Load more items (pagination)
  Future<void> loadMoreItems() async {
    if (state.isLoading || !state.hasMoreItems) return;

    await loadFeed();
  }

  // Update radius and reload
  Future<void> updateRadius(double radiusKm) async {
    if (radiusKm == state.selectedRadiusKm) return;

    state = state.copyWith(selectedRadiusKm: radiusKm);
    await loadFeed(refresh: true);
  }

  // Remove item from feed (after pass)
  void removeItem(String itemId) {
    final updatedItems = state.items.where((item) => item.item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh feed
  Future<void> refresh() async {
    await loadFeed(refresh: true);
  }
}

// Providers
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(FeedService());
});

// Convenience providers
final feedItemsProvider = Provider<List<FeedItem>>((ref) {
  return ref.watch(feedProvider).items;
});

final feedLoadingProvider = Provider<bool>((ref) {
  return ref.watch(feedProvider).isLoading;
});

final feedErrorProvider = Provider<String?>((ref) {
  return ref.watch(feedProvider).error;
});

final selectedRadiusProvider = Provider<double>((ref) {
  return ref.watch(feedProvider).selectedRadiusKm;
});

final hasMoreItemsProvider = Provider<bool>((ref) {
  return ref.watch(feedProvider).hasMoreItems;
});

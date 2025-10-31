import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/item.dart';
import '../../../shared/services/item_service.dart';

// Item creation state
class ItemCreationState {
  final bool isLoading;
  final String? error;
  final Item? createdItem;

  const ItemCreationState({
    this.isLoading = false,
    this.error,
    this.createdItem,
  });

  ItemCreationState copyWith({
    bool? isLoading,
    String? error,
    Item? createdItem,
  }) {
    return ItemCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      createdItem: createdItem ?? this.createdItem,
    );
  }
}

// Item creation notifier
class ItemCreationNotifier extends StateNotifier<ItemCreationState> {
  final ItemService _itemService;

  ItemCreationNotifier(this._itemService) : super(const ItemCreationState());

  // Create new item
  Future<bool> createItem({
    required String title,
    required String description,
    required ItemCondition condition,
    required ExchangeType exchangeType,
    required List<Uint8List> photos,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final item = await _itemService.createItem(
        title: title,
        description: description,
        condition: condition,
        exchangeType: exchangeType,
        photos: photos,
      );

      state = state.copyWith(
        isLoading: false,
        createdItem: item,
        error: null,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Clear state
  void clearState() {
    state = const ItemCreationState();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// User items state
class UserItemsState {
  final List<Item> items;
  final bool isLoading;
  final String? error;

  const UserItemsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  UserItemsState copyWith({
    List<Item>? items,
    bool? isLoading,
    String? error,
  }) {
    return UserItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// User items notifier
class UserItemsNotifier extends StateNotifier<UserItemsState> {
  final ItemService _itemService;

  UserItemsNotifier(this._itemService) : super(const UserItemsState());

  // Load user's items
  Future<void> loadUserItems() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _itemService.getUserItems();
      // Sort items: available first, then exchanged (both sorted by creation date desc)
      final sortedItems = _sortUserItems(items);
      state = state.copyWith(
        items: sortedItems,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Sort items: available first (newest first), then exchanged (newest first)
  List<Item> _sortUserItems(List<Item> items) {
    final availableItems = items
        .where((item) => item.status == ItemStatus.available)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final exchangedItems = items
        .where((item) => item.status == ItemStatus.exchanged)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return [...availableItems, ...exchangedItems];
  }

  // Add item to list (after creation)
  void addItem(Item item) {
    final updatedItems = [item, ...state.items];
    state = state.copyWith(items: updatedItems);
  }

  // Remove item from list
  void removeItem(String itemId) {
    final updatedItems = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  // Update item in list
  void updateItem(Item updatedItem) {
    final updatedItems = state.items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    // Re-sort items after update to maintain correct order
    final sortedItems = _sortUserItems(updatedItems);
    state = state.copyWith(items: sortedItems);
  }
}

// Providers
final itemCreationProvider = StateNotifierProvider<ItemCreationNotifier, ItemCreationState>((ref) {
  return ItemCreationNotifier(ItemService());
});

final userItemsProvider = StateNotifierProvider<UserItemsNotifier, UserItemsState>((ref) {
  return UserItemsNotifier(ItemService());
});

final itemCreationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(itemCreationProvider).isLoading;
});

final userItemsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userItemsProvider).isLoading;
});

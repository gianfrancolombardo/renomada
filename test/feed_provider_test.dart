import 'package:flutter_test/flutter_test.dart';
import 'package:renomada/features/feed/providers/feed_provider.dart';
import 'package:renomada/shared/models/item.dart';
import 'package:renomada/shared/models/user_profile.dart';
import 'package:renomada/shared/services/feed_service.dart';

class FakeFeedRepository implements FeedRepository {
  final List<FeedItem> nearbyItems;
  final List<FeedItem> recentItems;

  int nearbyCalls = 0;
  int recentCalls = 0;

  FakeFeedRepository({
    required this.nearbyItems,
    required this.recentItems,
  });

  @override
  Future<List<FeedItem>> getFeedItems({
    required double radiusKm,
    int page = 0,
    int limit = 10,
  }) async {
    nearbyCalls++;
    return nearbyItems;
  }

  @override
  Future<List<FeedItem>> getFeedItemsWithoutLocation() async {
    recentCalls++;
    return recentItems;
  }
}

FeedItem makeFeedItem(String id) {
  final item = Item(
    id: id,
    ownerId: 'owner-$id',
    title: 'title-$id',
    description: 'desc-$id',
    createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
  );
  final owner = UserProfile(userId: item.ownerId);
  return FeedItem(item: item, owner: owner);
}

void main() {
  test('Carga por radio: items vacíos si el RPC por radio devuelve vacío', () async {
    final repo = FakeFeedRepository(
      nearbyItems: const [],
      recentItems: [makeFeedItem('r1')],
    );

    final notifier = FeedNotifier(
      repository: repo,
      feedService: FeedService(),
    );

    await notifier.loadFeed(
      refresh: true,
    );

    expect(notifier.state.items, isEmpty);
    expect(notifier.state.hasMoreItems, isFalse);
    expect(repo.nearbyCalls, 1); // no retries when nearby has items
    expect(repo.recentCalls, 0); // sin fallback
  });

  test('UserProfile.fromJson parsea last_location WKB EWKB', () {
    // Granollers (lon ~2.2875, lat ~41.6080) en WKB/hex como en tus logs.
    const lastLocationWkbHex =
        '0101000020E6100000CDCCCCCCCC4C0240E7FBA9F1D2CD4440';

    final profile = UserProfile.fromJson({
      'user_id': 'u1',
      'username': 'test',
      'avatar_url': null,
      'last_location': lastLocationWkbHex,
      'last_seen_at': '2026-03-19T02:00:38.999+00:00',
      'is_location_opt_out': false,
      'has_seen_onboarding': true,
    });

    final coords = profile.lastLocation?['coordinates'];
    expect(coords, isA<List>());
    expect((coords as List).length, 2);

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    expect(lon, closeTo(2.2875, 0.0005));
    expect(lat, closeTo(41.6080, 0.0005));
  });
}


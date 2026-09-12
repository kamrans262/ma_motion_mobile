import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/discovery/data/discovery_search_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_search_result.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/screens/discovery_search_screen.dart';

void main() {
  testWidgets('renders Maker and artwork unified-search sections', (
    tester,
  ) async {
    final repository = _FakeSearchRepository();
    DiscoverySearchMaker? openedMaker;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverySearchRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: DiscoverySearchScreen(
            onBack: () {},
            onFilterTap: () {},
            onMakerTap: (maker) => openedMaker = maker,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('discovery_search_field')),
      'Orbit',
    );

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Makers'), findsOneWidget);
    expect(find.text('Artwork'), findsOneWidget);
    expect(find.byKey(const Key('search_maker_4')), findsOneWidget);
    expect(find.byKey(const Key('artwork_tile_9')), findsOneWidget);
    expect(repository.lastQuery?.search, 'Orbit');

    await tester.tap(find.byKey(const Key('search_maker_4')));
    await tester.pump();

    expect(openedMaker?.id, 4);
    expect(tester.takeException(), isNull);
  });
}

class _FakeSearchRepository implements DiscoverySearchRepositoryContract {
  DiscoveryQuery? lastQuery;

  @override
  Future<DiscoverySearchResultPage> search({
    required DiscoveryQuery query,
    required int page,
    int perPage = 20,
  }) async {
    lastQuery = query;

    return const DiscoverySearchResultPage(
      artworks: <DiscoveryArtwork>[
        DiscoveryArtwork(id: 9, title: 'Orbit Light'),
      ],
      makers: <DiscoverySearchMaker>[
        DiscoverySearchMaker(
          id: 4,
          name: 'Orbit Artist',
          statistics: DiscoverySearchMakerStatistics(
            savedCount: 12,
            artworkCount: 4,
          ),
        ),
      ],
      artworkMeta: PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 1,
      ),
      makerMeta: PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 20,
        total: 1,
      ),
    );
  }
}

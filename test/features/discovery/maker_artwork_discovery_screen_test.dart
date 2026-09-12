import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/screens/maker_artwork_discovery_screen.dart';

void main() {
  testWidgets('renders artwork grid and active-filter badge', (tester) async {
    final container = ProviderContainer(
      overrides: [
        artworkDiscoveryRepositoryProvider.overrideWithValue(
          _FakeDiscoveryRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(discoveryQueryProvider.notifier)
        .setQuery(const DiscoveryQuery(typeIds: <int>{1}));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MakerArtworkDiscoveryScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('maker_artwork_discovery_screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('artwork_tile_1')), findsOneWidget);
    expect(find.byKey(const Key('active_filter_badge')), findsOneWidget);
    expect(find.byKey(const Key('maker_nav_settings')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('numbered bottom navigation loads the requested discovery page', (
    tester,
  ) async {
    final repository = _FakeDiscoveryRepository();
    final container = ProviderContainer(
      overrides: [
        artworkDiscoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MakerArtworkDiscoveryScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    final pageThree = find.byKey(const Key('maker_nav_3')).hitTestable();
    expect(pageThree, findsOneWidget);

    await tester.tap(pageThree);
    await tester.pumpAndSettle();

    expect(repository.requestedPages, contains(3));
    expect(find.byKey(const Key('artwork_tile_3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeDiscoveryRepository implements ArtworkDiscoveryRepositoryContract {
  final List<int> requestedPages = <int>[];

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
    DiscoveryQuery query = const DiscoveryQuery(),
  }) async {
    requestedPages.add(page);

    return DiscoveryArtworkPage(
      items: <DiscoveryArtwork>[
        DiscoveryArtwork(
          id: page,
          title: 'Artwork page $page',
          primaryMedia: DiscoveryArtworkMedia(
            id: page * 10,
            kind: 'image',
            url: '',
          ),
        ),
      ],
      meta: PaginationMeta(
        currentPage: page,
        lastPage: 4,
        perPage: 24,
        total: 96,
      ),
    );
  }
}

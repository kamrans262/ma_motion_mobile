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
  testWidgets(
    '430x932 discovery matches reference geometry and uses SVG assets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _FakeDiscoveryRepository(lastPage: 6);
      final container = ProviderContainer(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(repository),
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
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const Key('discovery_search_svg'))),
        const Size(24, 24),
      );
      expect(
        tester.getSize(find.byKey(const Key('discovery_filter_svg'))),
        const Size(24, 24),
      );
      expect(
        tester.getSize(find.byKey(const Key('maker_nav_saved_svg'))),
        const Size(16, 16),
      );
      expect(
        tester.getSize(find.byKey(const Key('maker_nav_settings_svg'))),
        const Size(16, 16),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('maker_bottom_navigation_surface')))
            .height,
        65,
      );

      final gap = tester.widget<SizedBox>(
        find.byKey(const Key('discovery_controls_grid_gap')),
      );
      expect(gap.height, 10);

      final firstTile = tester.getRect(
        find.byKey(const Key('artwork_tile_100')),
      );
      final searchIcon = tester.getRect(
        find.byKey(const Key('discovery_search_svg')),
      );
      final filterIcon = tester.getRect(
        find.byKey(const Key('discovery_filter_svg')),
      );
      expect(firstTile.left, closeTo(20, 0.1));
      expect(firstTile.top - searchIcon.bottom, closeTo(10, 0.1));
      expect(firstTile.top - filterIcon.bottom, closeTo(10, 0.1));

      final lastTile = tester.getRect(
        find.byKey(const Key('artwork_tile_109')),
      );
      final gridRect = tester.getRect(
        find.byKey(const Key('maker_artwork_discovery_grid')),
      );
      expect(lastTile.bottom, closeTo(gridRect.bottom, 0.2));

      final grid = tester.widget<GridView>(
        find.byKey(const Key('maker_artwork_discovery_grid')),
      );
      expect(grid.physics, isA<NeverScrollableScrollPhysics>());
      expect(repository.requestedPerPages.first, 10);
      expect(find.byKey(const Key('active_filter_badge')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'numbered pagination replaces the grid page without infinite scroll',
    (tester) async {
      final repository = _FakeDiscoveryRepository(lastPage: 6);
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
      await tester.pumpAndSettle();

      final pageThree = find.byKey(const Key('maker_nav_3')).hitTestable();
      expect(pageThree, findsOneWidget);

      await tester.tap(pageThree);
      await tester.pumpAndSettle();

      expect(repository.requestedPages, contains(3));
      expect(find.byKey(const Key('artwork_tile_300')), findsOneWidget);
      expect(find.byKey(const Key('artwork_tile_100')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'heart and settings bottom controls emit working navigation callbacks',
    (tester) async {
      var savedTapped = 0;
      var settingsTapped = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            artworkDiscoveryRepositoryProvider.overrideWithValue(
              _FakeDiscoveryRepository(lastPage: 4),
            ),
          ],
          child: MaterialApp(
            home: MakerArtworkDiscoveryScreen(
              onSavedTap: () => savedTapped++,
              onSettingsTap: () => settingsTapped++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('maker_nav_saved')).hitTestable());
      await tester.tap(
        find.byKey(const Key('maker_nav_settings')).hitTestable(),
      );
      await tester.pump();

      expect(savedTapped, 1);
      expect(settingsTapped, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('discovery stays overflow-safe on a compact phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(
            _FakeDiscoveryRepository(lastPage: 8),
          ),
        ],
        child: const MaterialApp(home: MakerArtworkDiscoveryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('maker_artwork_discovery_grid')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeDiscoveryRepository implements ArtworkDiscoveryRepositoryContract {
  _FakeDiscoveryRepository({required this.lastPage});

  final int lastPage;
  final List<int> requestedPages = <int>[];
  final List<int> requestedPerPages = <int>[];

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
    DiscoveryQuery query = const DiscoveryQuery(),
  }) async {
    requestedPages.add(page);
    requestedPerPages.add(perPage);

    return DiscoveryArtworkPage(
      items: List<DiscoveryArtwork>.generate(
        perPage,
        (index) => DiscoveryArtwork(
          id: (page * 100) + index,
          title: 'Artwork page $page item $index',
          primaryMedia: DiscoveryArtworkMedia(
            id: (page * 1000) + index,
            kind: 'image',
            url: '',
          ),
        ),
      ),
      meta: PaginationMeta(
        currentPage: page,
        lastPage: lastPage,
        perPage: perPage,
        total: lastPage * perPage,
      ),
    );
  }
}

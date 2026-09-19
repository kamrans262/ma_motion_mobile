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
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('430x932 discovery uses reference icons and 2-column default', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeDiscoveryRepository(lastPage: 2);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(repository),
        ],
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
      const Size(18, 18),
    );
    expect(find.byKey(const Key('maker_nav_saved_filled')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('maker_nav_settings_svg'))),
      const Size(18, 18),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('maker_bottom_navigation_surface')))
          .height,
      65,
    );

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const Key('maker_artwork_discovery_screen')),
    );
    expect(scaffold.backgroundColor, const Color(0xFF020101));

    final navMaterial = tester.widget<Material>(
      find.byKey(const Key('maker_bottom_navigation_material')),
    );
    expect(navMaterial.color, const Color(0xFF0F2419));

    expect(
      tester
          .getSize(find.byKey(const Key('discovery_controls_grid_gap')))
          .height,
      10,
    );

    final selected = tester.widget<Text>(
      find.byKey(const Key('maker_nav_column_text_2')),
    );
    final unselected = tester.widget<Text>(
      find.byKey(const Key('maker_nav_column_text_1')),
    );

    expect(selected.style?.fontFamily, 'HelveticaNeueLTStd');
    expect(selected.style?.fontSize, 16);
    expect(selected.style?.fontWeight, FontWeight.w500);
    expect(selected.style?.color, const Color(0xFF904AFF));
    expect(unselected.style?.fontFamily, 'HelveticaNeueLTStd');
    expect(unselected.style?.fontSize, 14);
    expect(unselected.style?.fontWeight, FontWeight.w500);
    expect(
      unselected.style?.color,
      const Color(0xFF904AFF).withValues(alpha: 0.50),
    );

    final grid = tester.widget<GridView>(
      find.byKey(const Key('maker_artwork_discovery_grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 2);
    expect(repository.requestedPages, <int>[1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1 to 4 controls reflow the same grid without API pagination', (
    tester,
  ) async {
    final repository = _FakeDiscoveryRepository(lastPage: 3);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: MakerArtworkDiscoveryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final requestsBefore = repository.requestedPages.length;

    await tester.tap(find.byKey(const Key('maker_nav_4')).hitTestable());
    await tester.pump();

    final grid = tester.widget<GridView>(
      find.byKey(const Key('maker_artwork_discovery_grid')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 4);
    expect(repository.requestedPages.length, requestsBefore);
    expect(find.byKey(const Key('artwork_tile_100')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search opens inline and filters the existing artwork grid', (
    tester,
  ) async {
    final repository = _FakeDiscoveryRepository(lastPage: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: MakerArtworkDiscoveryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('discovery_search_button')).hitTestable(),
    );
    await tester.pump();

    expect(find.byKey(const Key('discovery_inline_search')), findsOneWidget);
    expect(
      find.byKey(const Key('maker_artwork_discovery_screen')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('discovery_inline_search')),
      'Mara',
    );
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();

    expect(repository.lastQuery?.search, 'Mara');
    expect(repository.requestedPages.last, 1);
    final searchField = tester.widget<TextField>(
      find.byKey(const Key('discovery_inline_search')),
    );
    expect(searchField.decoration?.enabledBorder, isA<UnderlineInputBorder>());

    expect(
      find.byKey(const Key('discovery_search_close_icon')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('discovery_search_svg')), findsNothing);

    final closeRect = tester.getRect(
      find.byKey(const Key('discovery_search_close_icon')),
    );
    final fieldRect = tester.getRect(
      find.byKey(const Key('discovery_inline_search')),
    );
    expect(fieldRect.left - closeRect.right, closeTo(2, 0.5));

    await tester.tap(
      find.byKey(const Key('discovery_search_button')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('discovery_inline_search')), findsNothing);
    expect(find.byKey(const Key('discovery_search_svg')), findsOneWidget);
    expect(find.byKey(const Key('discovery_search_close_icon')), findsNothing);
    expect(repository.lastQuery?.search, '');

    expect(
      find.byKey(const Key('maker_artwork_discovery_grid')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolling near the end loads the next server page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeDiscoveryRepository(lastPage: 2);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: MakerArtworkDiscoveryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final grid = find.byKey(const Key('maker_artwork_discovery_grid'));
    expect(grid.hitTestable(), findsOneWidget);

    await tester.drag(grid.hitTestable(), const Offset(0, -5000));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.requestedPages, contains(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'heart and settings bottom controls emit Maker navigation callbacks',
    (tester) async {
      var savedTapped = 0;
      var settingsTapped = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            artworkDiscoveryRepositoryProvider.overrideWithValue(
              _FakeDiscoveryRepository(lastPage: 1),
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
            _FakeDiscoveryRepository(lastPage: 1),
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

    await tester.tap(find.byKey(const Key('maker_nav_4')).hitTestable());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

class _FakeDiscoveryRepository implements ArtworkDiscoveryRepositoryContract {
  _FakeDiscoveryRepository({required this.lastPage});

  final int lastPage;
  final List<int> requestedPages = <int>[];
  final List<int> requestedPerPages = <int>[];
  DiscoveryQuery? lastQuery;

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
    DiscoveryQuery query = const DiscoveryQuery(),
  }) async {
    requestedPages.add(page);
    requestedPerPages.add(perPage);
    lastQuery = query;

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

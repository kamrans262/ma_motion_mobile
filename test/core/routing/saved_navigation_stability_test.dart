import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/core/routing/app_router.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';
import 'package:ma_motion_mobile/features/saved_artworks/data/saved_artworks_repository.dart';

void main() {
  testWidgets('Heart navigation keeps every bottom navigation item stationary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(
      splashAutoPlay: false,
      splashDuration: Duration.zero,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDiscoveryRepositoryProvider.overrideWithValue(
            _EmptyDiscoveryRepository(),
          ),
          savedArtworksRepositoryProvider.overrideWithValue(
            _EmptySavedRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go('/maker/discovery');
    await tester.pumpAndSettle();

    final before = _bottomNavigationCenters(tester, heartFilled: false);

    await tester.tap(find.byKey(const Key('maker_nav_saved')).hitTestable());
    await tester.pump();

    expect(
      find.byKey(const Key('maker_saved_artworks_screen')),
      findsOneWidget,
    );
    _expectSameCenters(
      before,
      _bottomNavigationCenters(tester, heartFilled: true),
    );

    await tester.pump(const Duration(milliseconds: 80));
    _expectSameCenters(
      before,
      _bottomNavigationCenters(tester, heartFilled: true),
    );
  });
}

Map<String, Offset> _bottomNavigationCenters(
  WidgetTester tester, {
  required bool heartFilled,
}) {
  final finders = <String, Finder>{
    'heart': heartFilled
        ? find.byKey(const Key('maker_nav_saved_filled'))
        : find.byKey(const Key('maker_nav_saved_svg')),
    for (var index = 1; index <= 4; index++)
      'column_$index': find.byKey(Key('maker_nav_column_text_$index')),
    'settings': find.byKey(const Key('maker_nav_settings_svg')),
  };

  return <String, Offset>{
    for (final entry in finders.entries)
      entry.key: tester.getCenter(entry.value),
  };
}

void _expectSameCenters(
  Map<String, Offset> expected,
  Map<String, Offset> actual,
) {
  for (final entry in expected.entries) {
    expect(actual[entry.key]?.dx, closeTo(entry.value.dx, 0.01));
    expect(actual[entry.key]?.dy, closeTo(entry.value.dy, 0.01));
  }
}

class _EmptyDiscoveryRepository
    implements ArtworkDiscoveryRepositoryContract {
  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
    DiscoveryQuery query = const DiscoveryQuery(),
  }) async {
    return DiscoveryArtworkPage(
      items: const [],
      meta: PaginationMeta(
        currentPage: page,
        lastPage: page,
        perPage: perPage,
        total: 0,
      ),
    );
  }
}

class _EmptySavedRepository implements SavedArtworksRepositoryContract {
  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
  }) async {
    return DiscoveryArtworkPage(
      items: const [],
      meta: PaginationMeta(
        currentPage: page,
        lastPage: page,
        perPage: perPage,
        total: 0,
      ),
    );
  }

  @override
  Future<bool> isSaved(int artworkId) async => false;

  @override
  Future<void> save(int artworkId) async {}

  @override
  Future<void> unsave(int artworkId) async {}
}

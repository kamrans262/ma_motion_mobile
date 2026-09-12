import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/saved_artworks/data/saved_artworks_repository.dart';
import 'package:ma_motion_mobile/features/saved_artworks/presentation/screens/maker_saved_artworks_screen.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('saved artwork grid uses the same 1 to 4 column controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FakeSavedRepository();
    var settingsTapped = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedArtworksRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: MakerSavedArtworksScreen(onSettingsTap: () => settingsTapped++),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('maker_saved_artworks_screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('artwork_tile_91')), findsOneWidget);

    var grid = tester.widget<GridView>(
      find.byKey(const Key('maker_saved_artworks_grid')),
    );
    var delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);

    await tester.tap(find.byKey(const Key('maker_nav_4')).hitTestable());
    await tester.pump();

    grid = tester.widget<GridView>(
      find.byKey(const Key('maker_saved_artworks_grid')),
    );
    delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);

    await tester.tap(
      find.byKey(const Key('saved_artwork_remove_91')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(repository.unsavedIds, <int>[91]);
    expect(find.byKey(const Key('saved_artworks_empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('maker_nav_settings')).hitTestable());
    await tester.pump();

    expect(settingsTapped, 1);
    expect(tester.takeException(), isNull);
  });
}

class _FakeSavedRepository implements SavedArtworksRepositoryContract {
  bool saved = true;
  final List<int> unsavedIds = <int>[];

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
  }) async {
    return DiscoveryArtworkPage(
      items: saved
          ? const <DiscoveryArtwork>[
              DiscoveryArtwork(
                id: 91,
                title: 'Saved',
                primaryMedia: DiscoveryArtworkMedia(
                  id: 911,
                  kind: 'image',
                  url: '',
                ),
              ),
            ]
          : const <DiscoveryArtwork>[],
      meta: PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: perPage,
        total: saved ? 1 : 0,
      ),
    );
  }

  @override
  Future<bool> isSaved(int artworkId) async => saved;

  @override
  Future<void> save(int artworkId) async {
    saved = true;
  }

  @override
  Future<void> unsave(int artworkId) async {
    unsavedIds.add(artworkId);
    saved = false;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
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
    DiscoveryArtwork? openedArtwork;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedArtworksRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: MakerSavedArtworksScreen(
            onArtworkTap: (artwork) => openedArtwork = artwork,
            onSettingsTap: () => settingsTapped++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('maker_saved_artworks_screen')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('artwork_tile_91')), findsOneWidget);
    expect(find.byKey(const Key('maker_nav_saved_filled')), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const Key('maker_saved_artworks_screen')),
    );
    expect(scaffold.backgroundColor, AppColors.savedBackground);
    expect(AppColors.savedBackground, const Color(0xFF0F2519));

    final artistBar = find.byKey(const Key('saved_artwork_artist_bar_91'));
    final artistName = find.byKey(const Key('saved_artwork_artist_name_91'));
    expect(artistBar, findsOneWidget);
    expect(artistName, findsOneWidget);
    expect(tester.widget<Text>(artistName).data, 'Mara Vellan');
    expect(find.byKey(const Key('saved_artwork_remove_91')), findsNothing);
    expect(tester.widget<Text>(artistName).style?.color, AppColors.white);
    expect(
      tester.getRect(artistBar).bottom,
      tester.getRect(find.byKey(const Key('artwork_tile_91'))).bottom,
    );

    await tester.tap(find.byKey(const Key('artwork_tile_91')).hitTestable());
    await tester.pump();
    expect(openedArtwork?.id, 91);
    expect(repository.unsavedIds, isEmpty);

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

    expect(
      find.byKey(const Key('saved_artwork_artist_bar_91')),
      findsOneWidget,
    );
    expect(repository.unsavedIds, isEmpty);

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
                maker: DiscoveryMakerPreview(id: 5, name: 'Mara Vellan'),
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

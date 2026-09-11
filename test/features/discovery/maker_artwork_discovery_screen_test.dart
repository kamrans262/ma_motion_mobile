import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/screens/maker_artwork_discovery_screen.dart';

void main() {
  testWidgets(
    'renders two-column artwork grid, media indicator and Maker navigation',
    (tester) async {
      DiscoveryArtwork? tappedArtwork;
      int? tappedNavigationIndex;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            artworkDiscoveryRepositoryProvider.overrideWithValue(
              _FakeDiscoveryRepository(),
            ),
          ],
          child: MaterialApp(
            home: MakerArtworkDiscoveryScreen(
              onArtworkTap: (artwork) {
                tappedArtwork = artwork;
              },
              onBottomNavigationTap: (index) {
                tappedNavigationIndex = index;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(
        find.byKey(const Key('maker_artwork_discovery_screen')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('discovery_search_button')), findsOneWidget);
      expect(find.byKey(const Key('discovery_filter_button')), findsOneWidget);

      expect(find.byKey(const Key('artwork_tile_1')), findsOneWidget);
      expect(find.byKey(const Key('artwork_tile_2')), findsOneWidget);
      expect(
        find.byKey(const Key('artwork_video_play_indicator')),
        findsOneWidget,
      );

      expect(find.byKey(const Key('maker_nav_saved')), findsOneWidget);
      expect(find.byKey(const Key('maker_nav_1')), findsOneWidget);
      expect(find.byKey(const Key('maker_nav_2')), findsOneWidget);
      expect(find.byKey(const Key('maker_nav_3')), findsOneWidget);
      expect(find.byKey(const Key('maker_nav_4')), findsOneWidget);
      expect(find.byKey(const Key('maker_nav_settings')), findsOneWidget);

      await tester.tap(find.byKey(const Key('artwork_tile_1')));
      await tester.pump();
      expect(tappedArtwork?.id, 1);

      await tester.tap(find.byKey(const Key('maker_nav_settings')));
      await tester.pump();
      expect(tappedNavigationIndex, 5);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeDiscoveryRepository implements ArtworkDiscoveryRepositoryContract {
  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
  }) async {
    return const DiscoveryArtworkPage(
      items: <DiscoveryArtwork>[
        DiscoveryArtwork(
          id: 1,
          title: 'Sunset',
          primaryMedia: DiscoveryArtworkMedia(id: 11, kind: 'image', url: ''),
        ),
        DiscoveryArtwork(
          id: 2,
          title: 'Motion Work',
          primaryMedia: DiscoveryArtworkMedia(
            id: 12,
            kind: 'video',
            url: '',
            mimeType: 'video/mp4',
          ),
        ),
      ],
      meta: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 24, total: 2),
    );
  }
}

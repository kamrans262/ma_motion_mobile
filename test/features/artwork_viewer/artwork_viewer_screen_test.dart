import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/pagination_meta.dart';
import 'package:ma_motion_mobile/features/artwork_viewer/data/artwork_detail_repository.dart';
import 'package:ma_motion_mobile/features/artwork_viewer/domain/artwork_detail.dart';
import 'package:ma_motion_mobile/features/artwork_viewer/presentation/screens/artwork_viewer_screen.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_artwork_page.dart';
import 'package:ma_motion_mobile/features/saved_artworks/data/saved_artworks_repository.dart';

void main() {
  testWidgets('viewer renders media description dots and Maker info slide', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDetailRepositoryProvider.overrideWithValue(
            _FakeArtworkDetailRepository(),
          ),
          savedArtworksRepositoryProvider.overrideWithValue(
            _FakeSavedArtworksRepository(),
          ),
        ],
        child: const MaterialApp(home: ArtworkViewerScreen(artworkId: 41)),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('artwork_viewer_screen')), findsOneWidget);
    expect(find.byKey(const Key('artwork_viewer_save_button')), findsOneWidget);
    expect(find.byKey(const Key('artwork_viewer_description')), findsOneWidget);
    expect(
      find.text('Built in slow layers over eleven months.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('artwork_viewer_dots')), findsOneWidget);
    expect(find.byKey(const Key('artwork_viewer_dot_0')), findsOneWidget);
    expect(find.byKey(const Key('artwork_viewer_dot_1')), findsOneWidget);
    expect(find.byKey(const Key('artwork_viewer_dot_2')), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('artwork_viewer_page_view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('artwork_viewer_page_view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('artwork_maker_info_card')), findsOneWidget);
    expect(find.text('Mara Vellan · 2024'), findsOneWidget);
    expect(find.byKey(const Key('artwork_maker_info_website')), findsOneWidget);
    expect(find.text('https://artist.example'), findsOneWidget);
    expect(
      find.byKey(const Key('artwork_maker_info_location')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('artwork_private_email_notice')),
      findsOneWidget,
    );
    expect(find.textContaining('private'), findsOneWidget);
    expect(find.byKey(const Key('artwork_maker_saved_count')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewer save control persists artwork through saved repository', (
    tester,
  ) async {
    final savedRepository = _FakeSavedArtworksRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDetailRepositoryProvider.overrideWithValue(
            _FakeArtworkDetailRepository(),
          ),
          savedArtworksRepositoryProvider.overrideWithValue(savedRepository),
        ],
        child: const MaterialApp(home: ArtworkViewerScreen(artworkId: 41)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('artwork_viewer_save_button')).hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(savedRepository.savedIds, <int>[41]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewer has no overflow on 320x520 compact viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDetailRepositoryProvider.overrideWithValue(
            _FakeArtworkDetailRepository(),
          ),
          savedArtworksRepositoryProvider.overrideWithValue(
            _FakeSavedArtworksRepository(),
          ),
        ],
        child: const MaterialApp(home: ArtworkViewerScreen(artworkId: 41)),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('artwork_viewer_close_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('artwork_viewer_page_view')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const Key('artwork_viewer_page_view')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('artwork_viewer_page_view')),
      const Offset(-320, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('artwork_maker_info_scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeArtworkDetailRepository implements ArtworkDetailRepositoryContract {
  @override
  Future<ArtworkDetail> fetch(int artworkId) async {
    return ArtworkDetail(
      id: 41,
      title: 'Tide Register No. 4',
      description: 'Built in slow layers over eleven months.',
      media: const <DiscoveryArtworkMedia>[
        DiscoveryArtworkMedia(
          id: 91,
          kind: 'image',
          url: '',
          width: 800,
          height: 1000,
          isPrimary: true,
        ),
        DiscoveryArtworkMedia(
          id: 92,
          kind: 'image',
          url: '',
          width: 800,
          height: 1000,
        ),
      ],
      primaryMedia: const DiscoveryArtworkMedia(
        id: 91,
        kind: 'image',
        url: '',
        width: 800,
        height: 1000,
        isPrimary: true,
      ),
      locationText: 'Chicago, IL',
      maker: const ArtworkDetailMaker(
        id: 7,
        name: 'Mara Vellan',
        bio: 'A contemporary artist exploring the intersection of form and color.',
        location: 'Chicago, IL',
        profileImageUrl: null,
        websiteUrl: 'https://artist.example',
        savedCount: 12,
      ),
      createdAt: DateTime.utc(2024, 5, 1),
    );
  }
}

class _FakeSavedArtworksRepository implements SavedArtworksRepositoryContract {
  bool saved = false;
  final List<int> savedIds = <int>[];

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
  }) async {
    return DiscoveryArtworkPage(
      items: const <DiscoveryArtwork>[],
      meta: PaginationMeta(
        currentPage: page,
        lastPage: 1,
        perPage: perPage,
        total: 0,
      ),
    );
  }

  @override
  Future<bool> isSaved(int artworkId) async => saved;

  @override
  Future<void> save(int artworkId) async {
    saved = true;
    savedIds.add(artworkId);
  }

  @override
  Future<void> unsave(int artworkId) async {
    saved = false;
  }
}

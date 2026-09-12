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
  testWidgets('430x932 viewer matches supplied Maker artwork display contract', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
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

    await tester.pumpAndSettle();

    final close = tester.widget<IconButton>(
      find.byKey(const Key('artwork_viewer_close_button')),
    );
    expect(close.iconSize, 12);

    final imageGap = tester.widget<SizedBox>(
      find.byKey(const Key('artwork_image_description_gap')),
    );
    expect(imageGap.height, 40);

    final description = tester.widget<Text>(
      find.byKey(const Key('artwork_viewer_description')),
    );
    expect(description.style?.fontFamily, 'Arial');
    expect(description.style?.fontSize, 14);
    expect(description.style?.fontWeight, FontWeight.w400);
    expect(description.style?.color, const Color(0xFFF0F0F0));

    final dotsGap = tester.widget<SizedBox>(
      find.byKey(const Key('artwork_description_dots_gap')),
    );
    expect(dotsGap.height, 50);
    expect(find.byKey(const Key('artwork_viewer_dots')), findsOneWidget);

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

    final title = tester.widget<Text>(
      find.byKey(const Key('artwork_maker_info_title')),
    );
    expect(title.style?.fontFamily, 'Fraunces');
    expect(title.style?.fontSize, 16);

    final meta = tester.widget<Text>(
      find.byKey(const Key('artwork_maker_info_meta')),
    );
    expect(meta.style?.fontFamily, 'Instrument Sans');
    expect(meta.style?.fontSize, 12);

    expect(
      tester.getSize(find.byKey(const Key('artwork_maker_info_heart'))),
      const Size(24, 24),
    );

    final share = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('artwork_maker_info_share_button')),
        matching: find.text('Share'),
      ),
    );
    expect(share.style?.fontFamily, 'Instrument Sans');
    expect(share.style?.fontSize, 16);
    expect(share.style?.fontWeight, FontWeight.w600);

    final makerClose = tester.widget<IconButton>(
      find.byKey(const Key('artwork_maker_info_close_button')),
    );
    expect(makerClose.iconSize, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Maker detail heart saves the current artwork', (tester) async {
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

    await tester.tap(
      find.byKey(const Key('artwork_maker_info_save_button')).hitTestable(),
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

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('artwork_viewer_close_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('artwork_viewer_page_view')), findsOneWidget);
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
          width: 640,
          height: 1000,
          isPrimary: true,
        ),
        DiscoveryArtworkMedia(
          id: 92,
          kind: 'image',
          url: '',
          width: 640,
          height: 1000,
        ),
      ],
      primaryMedia: const DiscoveryArtworkMedia(
        id: 91,
        kind: 'image',
        url: '',
        width: 640,
        height: 1000,
        isPrimary: true,
      ),
      maker: const ArtworkDetailMaker(
        id: 7,
        name: 'Mara Vellan',
        bio: 'A contemporary artist exploring the intersection of form and color.',
        websiteUrl: 'https://artist.example',
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

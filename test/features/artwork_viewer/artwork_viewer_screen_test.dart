import 'dart:async';

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
  testWidgets(
    '430x932 viewer matches supplied single-carousel artwork reference',
    (tester) async {
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

      final scaffold = tester.widget<Scaffold>(
        find.byKey(const Key('artwork_viewer_screen')),
      );
      expect(scaffold.backgroundColor, const Color(0xFF020101));

      final close = tester.widget<IconButton>(
        find.byKey(const Key('artwork_viewer_close_button')),
      );
      expect(close.iconSize, 12);

      final description = tester.widget<Text>(
        find.byKey(const Key('artwork_viewer_description')),
      );
      expect(description.style?.fontFamily, 'Arial');
      expect(description.style?.fontSize, 14);
      expect(description.style?.fontWeight, FontWeight.w400);
      expect(description.style?.fontStyle, FontStyle.italic);
      expect(description.style?.color, const Color(0xFFF0F0F0));

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
      expect(find.text('Tide Register No. 4'), findsOneWidget);
      expect(find.text('Mara Vellan · 2024'), findsOneWidget);

      final title = tester.widget<Text>(
        find.byKey(const Key('artwork_maker_info_title')),
      );
      expect(title.style?.fontFamily, 'Instrument Sans');
      expect(title.style?.fontSize, 24);
      expect(title.style?.fontWeight, FontWeight.w700);

      final meta = tester.widget<Text>(
        find.byKey(const Key('artwork_maker_info_meta')),
      );
      expect(meta.style?.fontFamily, 'Instrument Sans');
      expect(meta.style?.fontSize, 15);

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
      expect(share.style?.fontSize, 18);
      expect(share.style?.fontWeight, FontWeight.w700);

      expect(
        find.byKey(const Key('artwork_viewer_close_button')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('seeded discovery artwork opens before detail request finishes', (
    tester,
  ) async {
    final repository = _DelayedArtworkDetailRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artworkDetailRepositoryProvider.overrideWithValue(repository),
          savedArtworksRepositoryProvider.overrideWithValue(
            _FakeSavedArtworksRepository(),
          ),
        ],
        child: MaterialApp(
          home: ArtworkViewerScreen(
            artworkId: 41,
            initialArtwork: DiscoveryArtwork(
              id: 41,
              title: 'Immediate artwork',
              description: 'Visible immediately',
              primaryMedia: const DiscoveryArtworkMedia(
                id: 91,
                kind: 'image',
                url: '',
                width: 640,
                height: 1000,
                isPrimary: true,
              ),
              maker: const DiscoveryMakerPreview(id: 7, name: 'Mara Vellan'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('artwork_viewer_page_view')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const Key('artwork_viewer_screen')),
    );
    expect(scaffold.backgroundColor, const Color(0xFF020101));

    repository.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('artwork_viewer_page_view')), findsOneWidget);
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

class _DelayedArtworkDetailRepository
    implements ArtworkDetailRepositoryContract {
  final Completer<ArtworkDetail> _completer = Completer<ArtworkDetail>();

  void complete() {
    if (_completer.isCompleted) return;

    _completer.complete(
      ArtworkDetail(
        id: 41,
        title: 'Loaded artwork',
        description: 'Loaded detail',
        media: const <DiscoveryArtworkMedia>[
          DiscoveryArtworkMedia(
            id: 91,
            kind: 'image',
            url: '',
            width: 640,
            height: 1000,
            isPrimary: true,
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
        maker: const ArtworkDetailMaker(id: 7, name: 'Mara Vellan'),
      ),
    );
  }

  @override
  Future<ArtworkDetail> fetch(int artworkId) => _completer.future;
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
        location: 'New York, NY',
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

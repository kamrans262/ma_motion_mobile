import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../discovery/domain/discovery_artwork.dart';
import '../../../saved_artworks/application/artwork_saved_status_provider.dart';
import '../../../saved_artworks/application/saved_artworks_controller.dart';
import '../../../saved_artworks/data/saved_artworks_repository.dart';
import '../../application/artwork_detail_provider.dart';
import '../../domain/artwork_detail.dart';
import '../widgets/artwork_maker_info_page.dart';
import '../widgets/artwork_viewer_dots.dart';

class ArtworkViewerScreen extends ConsumerStatefulWidget {
  const ArtworkViewerScreen({
    super.key,
    required this.artworkId,
    this.initialArtwork,
    this.onClose,
  });

  final int artworkId;
  final DiscoveryArtwork? initialArtwork;
  final VoidCallback? onClose;

  @override
  ConsumerState<ArtworkViewerScreen> createState() =>
      _ArtworkViewerScreenState();
}

class _ArtworkViewerScreenState extends ConsumerState<ArtworkViewerScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isSaving = false;
  final Set<String> _precachedUrls = <String>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleSaved(bool isSaved) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(savedArtworksRepositoryProvider);

      if (isSaved) {
        await repository.unsave(widget.artworkId);
      } else {
        await repository.save(widget.artworkId);
      }

      ref.invalidate(artworkSavedStatusProvider(widget.artworkId));
      ref.invalidate(savedArtworksControllerProvider);
    } catch (_) {
      // Keep the viewer intact if persistence is temporarily unavailable.
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareArtwork(ArtworkDetail artwork) async {
    final makerName = artwork.maker?.name.trim() ?? '';
    final website = artwork.maker?.websiteUrl?.trim() ?? '';
    final text = <String>[
      artwork.title,
      if (makerName.isNotEmpty) makerName,
      if (website.isNotEmpty) website,
    ].join('\n');

    await SharePlus.instance.share(
      ShareParams(title: artwork.title, text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(artworkDetailProvider(widget.artworkId));
    final asyncSaved = ref.watch(artworkSavedStatusProvider(widget.artworkId));
    final isSaved = asyncSaved.when(
      data: (value) => value,
      loading: () => false,
      error: (error, stackTrace) => false,
    );

    final seededArtwork = widget.initialArtwork == null
        ? null
        : ArtworkDetail.fromDiscovery(widget.initialArtwork!);
    final artwork = asyncDetail.value ?? seededArtwork;

    if (artwork != null) {
      _scheduleMediaPrecache(artwork);
    }

    return Scaffold(
      key: const Key('artwork_viewer_screen'),
      backgroundColor: AppColors.artworkBackground,
      body: artwork != null
          ? _buildViewer(context, artwork, isSaved: isSaved)
          : asyncDetail.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stackTrace) => _ViewerError(
                onRetry: () {
                  ref.invalidate(artworkDetailProvider(widget.artworkId));
                },
                onClose: widget.onClose,
              ),
              data: (_) => const SizedBox.shrink(),
            ),
    );
  }

  void _scheduleMediaPrecache(ArtworkDetail artwork) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final candidates = <DiscoveryArtworkMedia?>[
        artwork.primaryMedia,
        ...artwork.media,
      ];

      for (final media in candidates) {
        final url = media?.url.trim() ?? '';
        if (url.isEmpty || media?.isVideo == true || !_precachedUrls.add(url)) {
          continue;
        }

        unawaited(
          precacheImage(
            NetworkImage(url),
            context,
            onError: (error, stackTrace) {},
          ),
        );
      }
    });
  }

  Widget _buildViewer(
    BuildContext context,
    ArtworkDetail artwork, {
    required bool isSaved,
  }) {
    final media = artwork.media.isEmpty
        ? <DiscoveryArtworkMedia?>[artwork.primaryMedia]
        : artwork.media.cast<DiscoveryArtworkMedia?>();

    final visualPageCount = media.length;
    final totalPageCount = visualPageCount + 1;

    if (_currentPage >= totalPageCount) {
      _currentPage = 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _ViewerOverlayLayout.fromConstraints(constraints);
        final isMakerPage = _currentPage == visualPageCount;

        return Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const Key('artwork_viewer_page_view'),
              controller: _pageController,
              itemCount: totalPageCount,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                if (index == visualPageCount) {
                  return ArtworkMakerInfoPage(
                    artwork: artwork,
                    isSaved: isSaved,
                    isSaving: _isSaving,
                    onSavedTap: () => _toggleSaved(isSaved),
                    onShare: () => _shareArtwork(artwork),
                  );
                }

                return _ArtworkMediaPage(artwork: artwork, media: media[index]);
              },
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              top: isMakerPage ? layout.makerCloseTop : layout.mediaCloseTop,
              right: isMakerPage
                  ? layout.makerCloseRight
                  : layout.mediaCloseRight,
              child: _ViewerCloseButton(onPressed: widget.onClose),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              bottom: isMakerPage
                  ? layout.makerDotsBottom
                  : layout.mediaDotsBottom,
              child: Center(
                child: ArtworkViewerDots(
                  count: totalPageCount,
                  currentIndex: _currentPage,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ViewerOverlayLayout {
  const _ViewerOverlayLayout({
    required this.mediaCloseTop,
    required this.mediaCloseRight,
    required this.makerCloseTop,
    required this.makerCloseRight,
    required this.mediaDotsBottom,
    required this.makerDotsBottom,
  });

  final double mediaCloseTop;
  final double mediaCloseRight;
  final double makerCloseTop;
  final double makerCloseRight;
  final double mediaDotsBottom;
  final double makerDotsBottom;

  factory _ViewerOverlayLayout.fromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final makerCardTop = (height * 0.327).clamp(160.0, 335.0).toDouble();
    final makerCardHorizontal = (width * 0.0816).clamp(24.0, 40.0).toDouble();

    return _ViewerOverlayLayout(
      mediaCloseTop: (height * 0.049).clamp(28.0, 52.0).toDouble(),
      mediaCloseRight: (width * 0.107).clamp(28.0, 52.0).toDouble(),
      makerCloseTop: makerCardTop + 2,
      makerCloseRight: makerCardHorizontal + 2,
      mediaDotsBottom: (height * 0.25).clamp(80.0, 256.0).toDouble(),
      makerDotsBottom: (height * 0.207).clamp(64.0, 212.0).toDouble(),
    );
  }
}

class _ViewerCloseButton extends StatelessWidget {
  const _ViewerCloseButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        key: const Key('artwork_viewer_close_button'),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 12,
        color: const Color(0xFFF0F0F0),
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _ArtworkMediaPage extends StatelessWidget {
  const _ArtworkMediaPage({required this.artwork, required this.media});

  final ArtworkDetail artwork;
  final DiscoveryArtworkMedia? media;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = (constraints.maxWidth / 472)
            .clamp(0.68, 1.18)
            .toDouble();
        final horizontal = (constraints.maxWidth * 0.1398)
            .clamp(44.0, 72.0)
            .toDouble();
        final imageTop = (constraints.maxHeight * 0.1094)
            .clamp(56.0, 118.0)
            .toDouble();
        final imageWidth = constraints.maxWidth - (horizontal * 2);
        final aspectRatio = _aspectRatioFor(media);
        final naturalImageHeight = imageWidth / aspectRatio;
        final maxImageHeight =
            constraints.maxHeight * (constraints.maxHeight < 620 ? 0.50 : 0.52);
        final imageHeight = math.min(naturalImageHeight, maxImageHeight);
        final captionGap = (42 * widthScale).clamp(20.0, 44.0).toDouble();

        return SingleChildScrollView(
          key: const Key('artwork_media_page_scroll'),
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Column(
              children: [
                SizedBox(height: imageTop),
                SizedBox(
                  key: const Key('artwork_viewer_media_box'),
                  width: imageWidth,
                  height: imageHeight,
                  child: _MediaSurface(media: media),
                ),
                if ((artwork.description ?? '').isNotEmpty) ...[
                  SizedBox(height: captionGap),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * widthScale),
                    child: Text(
                      artwork.description!,
                      key: const Key('artwork_viewer_description'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 14,
                        height: 1.22,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: (132 * widthScale).clamp(84.0, 140.0)),
              ],
            ),
          ),
        );
      },
    );
  }

  static double _aspectRatioFor(DiscoveryArtworkMedia? media) {
    final width = media?.width;
    final height = media?.height;

    if (width != null && width > 0 && height != null && height > 0) {
      return width / height;
    }

    return 0.64;
  }
}

class _MediaSurface extends StatelessWidget {
  const _MediaSurface({required this.media});

  final DiscoveryArtworkMedia? media;

  @override
  Widget build(BuildContext context) {
    final url = media?.url.trim() ?? '';

    if (url.isEmpty) {
      return const ColoredBox(
        key: Key('artwork_viewer_media_fallback'),
        color: AppColors.inputFill,
        child: Center(
          child: Icon(Icons.image_outlined, size: 48, color: AppColors.primary),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          key: Key('artwork_viewer_media_${media!.id}'),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(
              color: AppColors.inputFill,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
        if (media!.isVideo)
          const Center(
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.play_arrow_rounded,
                size: 30,
                color: Color(0xFFE53935),
              ),
            ),
          ),
      ],
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _ViewerOverlayLayout.fromConstraints(constraints);

        return Stack(
          children: [
            Center(
              child: OutlinedButton(
                key: const Key('artwork_viewer_retry_button'),
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Try again'),
              ),
            ),
            Positioned(
              top: layout.mediaCloseTop,
              right: layout.mediaCloseRight,
              child: _ViewerCloseButton(onPressed: onClose),
            ),
          ],
        );
      },
    );
  }
}

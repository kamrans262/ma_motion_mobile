import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    this.onClose,
  });

  final int artworkId;
  final VoidCallback? onClose;

  @override
  ConsumerState<ArtworkViewerScreen> createState() =>
      _ArtworkViewerScreenState();
}

class _ArtworkViewerScreenState extends ConsumerState<ArtworkViewerScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _isSaving = false;

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

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(savedArtworksRepositoryProvider);

      if (isSaved) {
        await repository.unsave(widget.artworkId);
      } else {
        await repository.save(widget.artworkId);
      }

      ref.invalidate(artworkSavedStatusProvider(widget.artworkId));
      ref.invalidate(savedArtworksControllerProvider);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _shareArtwork(ArtworkDetail artwork) async {
    final makerName = artwork.maker?.name.trim() ?? '';
    final text = makerName.isEmpty
        ? artwork.title
        : '${artwork.title} — $makerName';

    await SharePlus.instance.share(
      ShareParams(
        title: artwork.title,
        text: text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(artworkDetailProvider(widget.artworkId));
    final asyncSaved = ref.watch(artworkSavedStatusProvider(widget.artworkId));
    final isSaved = asyncSaved.value ?? false;

    return Scaffold(
      key: const Key('artwork_viewer_screen'),
      backgroundColor: AppColors.black,
      body: asyncDetail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stackTrace) => _ViewerError(
          onRetry: () {
            ref.invalidate(artworkDetailProvider(widget.artworkId));
          },
          onClose: widget.onClose,
        ),
        data: (artwork) => _buildViewer(
          context,
          artwork,
          isSaved: isSaved,
        ),
      ),
    );
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

    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            key: const Key('artwork_viewer_page_view'),
            controller: _pageController,
            itemCount: totalPageCount,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentPage = index;
                });
              }
            },
            itemBuilder: (context, index) {
              if (index == visualPageCount) {
                return ArtworkMakerInfoPage(
                  artwork: artwork,
                  currentIndex: _currentPage,
                  pageCount: totalPageCount,
                  isSaved: isSaved,
                  isSaving: _isSaving,
                  onSavedTap: () => _toggleSaved(isSaved),
                  onShare: () => _shareArtwork(artwork),
                  onClose: widget.onClose,
                );
              }

              return _ArtworkMediaPage(
                artwork: artwork,
                media: media[index],
                currentIndex: _currentPage,
                pageCount: totalPageCount,
              );
            },
          ),
        ),
        if (_currentPage < visualPageCount)
          _ViewerCloseButton(onPressed: widget.onClose),
      ],
    );
  }
}

class _ViewerCloseButton extends StatelessWidget {
  const _ViewerCloseButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final widthScale =
        (MediaQuery.sizeOf(context).width / 430).clamp(0.78, 1.08);
    final visibleTop = (50 * widthScale).clamp(40.0, 54.0).toDouble();
    final buttonTop = visibleTop - 16;

    return Positioned(
      top: buttonTop,
      right: 18,
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          key: const Key('artwork_viewer_close_button'),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 12,
          color: const Color(0xFFF0F0F0),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}

class _ArtworkMediaPage extends StatelessWidget {
  const _ArtworkMediaPage({
    required this.artwork,
    required this.media,
    required this.currentIndex,
    required this.pageCount,
  });

  final ArtworkDetail artwork;
  final DiscoveryArtworkMedia? media;
  final int currentIndex;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = (constraints.maxWidth / 430).clamp(0.78, 1.08);
        final horizontal = (60 * widthScale).clamp(20.0, 60.0).toDouble();
        final top = (82 * widthScale).clamp(72.0, 88.0).toDouble();
        final imageWidth = constraints.maxWidth - (horizontal * 2);
        final maxImageHeight = math.max(
          140.0,
          constraints.maxHeight - top - 160,
        );

        return Padding(
          key: const Key('artwork_media_page_scroll'),
          padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 24),
          child: Column(
            children: [
              ConstrainedBox(
                key: const Key('artwork_viewer_media_box'),
                constraints: BoxConstraints(
                  maxWidth: imageWidth,
                  maxHeight: maxImageHeight,
                ),
                child: AspectRatio(
                  aspectRatio: _aspectRatioFor(media),
                  child: _MediaSurface(media: media),
                ),
              ),
              if ((artwork.description ?? '').isNotEmpty) ...[
                const SizedBox(
                  key: Key('artwork_image_description_gap'),
                  height: 40,
                ),
                Text(
                  artwork.description!,
                  key: const Key('artwork_viewer_description'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFF0F0F0),
                  ),
                ),
              ],
              const SizedBox(
                key: Key('artwork_description_dots_gap'),
                height: 50,
              ),
              ArtworkViewerDots(
                count: pageCount,
                currentIndex: currentIndex,
              ),
            ],
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
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: AppColors.primary,
          ),
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
  const _ViewerError({
    required this.onRetry,
    required this.onClose,
  });

  final VoidCallback onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
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
        _ViewerCloseButton(onPressed: onClose),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../discovery/domain/discovery_artwork.dart';
import '../../application/artwork_detail_provider.dart';
import '../../domain/artwork_detail.dart';
import '../widgets/artwork_maker_info_page.dart';
import '../widgets/artwork_viewer_dots.dart';

class ArtworkViewerScreen extends ConsumerStatefulWidget {
  const ArtworkViewerScreen({super.key, required this.artworkId, this.onClose});

  final int artworkId;
  final VoidCallback? onClose;

  @override
  ConsumerState<ArtworkViewerScreen> createState() =>
      _ArtworkViewerScreenState();
}

class _ArtworkViewerScreenState extends ConsumerState<ArtworkViewerScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

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

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(artworkDetailProvider(widget.artworkId));

    return Scaffold(
      key: const Key('artwork_viewer_screen'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: asyncDetail.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, stackTrace) => _ViewerError(
            onRetry: () {
              ref.invalidate(artworkDetailProvider(widget.artworkId));
            },
            onClose: widget.onClose,
          ),
          data: (artwork) => _buildViewer(artwork),
        ),
      ),
    );
  }

  Widget _buildViewer(ArtworkDetail artwork) {
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
                return ArtworkMakerInfoPage(artwork: artwork);
              }

              return _ArtworkMediaPage(
                artwork: artwork,
                media: media[index],
                onMakerAvatarTap: () {
                  _pageController.animateToPage(
                    visualPageCount,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                  );
                },
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: IconButton(
            key: const Key('artwork_viewer_close_button'),
            onPressed: widget.onClose,
            color: AppColors.white,
            iconSize: 27,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 34,
          child: IgnorePointer(
            child: Center(
              child: ArtworkViewerDots(
                count: totalPageCount,
                currentIndex: _currentPage,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtworkMediaPage extends StatelessWidget {
  const _ArtworkMediaPage({
    required this.artwork,
    required this.media,
    required this.onMakerAvatarTap,
  });

  final ArtworkDetail artwork;
  final DiscoveryArtworkMedia? media;
  final VoidCallback onMakerAvatarTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final horizontal = compact ? 18.0 : 28.0;
        final maxImageHeight = constraints.maxHeight * (compact ? 0.56 : 0.60);

        return SingleChildScrollView(
          key: const Key('artwork_media_page_scroll'),
          padding: EdgeInsets.fromLTRB(
            horizontal,
            compact ? 74 : 94,
            horizontal,
            110,
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxImageHeight),
                child: AspectRatio(
                  aspectRatio: _aspectRatioFor(media),
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      _MediaSurface(media: media),
                      if ((artwork.maker?.profileImageUrl ?? '').isNotEmpty)
                        Positioned(
                          right: compact ? 12 : 18,
                          bottom: compact ? -22 : -26,
                          child: GestureDetector(
                            key: const Key('artwork_maker_avatar_button'),
                            onTap: onMakerAvatarTap,
                            child: _SmallAvatar(
                              url: artwork.maker!.profileImageUrl!,
                              size: compact ? 50 : 58,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 44 : 56),
              if ((artwork.description ?? '').isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    artwork.description!,
                    key: const Key('artwork_viewer_description'),
                    style: AppTextStyles.onboardingHelper.copyWith(
                      fontSize: compact ? 15 : 17,
                      fontStyle: FontStyle.italic,
                      color: AppColors.white,
                      height: 1.35,
                    ),
                  ),
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

    return 0.86;
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
          fit: BoxFit.cover,
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

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person_outline_rounded,
            color: AppColors.white,
          );
        },
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We could not load this artwork.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.onboardingHelper,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const Key('artwork_viewer_retry_button'),
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
          child: IconButton(
            onPressed: onClose,
            color: AppColors.white,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }
}

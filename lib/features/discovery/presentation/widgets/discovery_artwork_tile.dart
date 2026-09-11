import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/discovery_artwork.dart';

class DiscoveryArtworkTile extends StatelessWidget {
  const DiscoveryArtworkTile({super.key, required this.artwork, this.onTap});

  final DiscoveryArtwork artwork;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final media = artwork.primaryMedia;

    return Semantics(
      button: true,
      label: artwork.title.isEmpty ? 'Artwork' : artwork.title,
      child: Material(
        color: const Color(0xFF13271D),
        child: InkWell(
          key: Key('artwork_tile_${artwork.id}'),
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ArtworkImage(
                url: media?.url,
                altText: media?.altText ?? artwork.title,
              ),
              if (media?.isVideo ?? false)
                const Center(child: _VideoPlayIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkImage extends StatelessWidget {
  const _ArtworkImage({required this.url, required this.altText});

  final String? url;
  final String altText;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return const _ArtworkFallback();
    }

    return Image.network(
      imageUrl,
      semanticLabel: altText.isEmpty ? null : altText,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }

        return const _ArtworkLoading();
      },
      errorBuilder: (context, error, stackTrace) {
        return const _ArtworkFallback();
      },
    );
  }
}

class _ArtworkLoading extends StatelessWidget {
  const _ArtworkLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF13271D),
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF13271D),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: AppColors.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _VideoPlayIndicator extends StatelessWidget {
  const _VideoPlayIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('artwork_video_play_indicator'),
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 27,
        color: Color(0xFFE53935),
      ),
    );
  }
}

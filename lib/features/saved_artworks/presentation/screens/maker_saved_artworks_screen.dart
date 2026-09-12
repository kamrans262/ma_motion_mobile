import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../discovery/domain/discovery_artwork.dart';
import '../../../discovery/presentation/widgets/discovery_artwork_tile.dart';
import '../../../discovery/presentation/widgets/discovery_layout_metrics.dart';
import '../../../discovery/presentation/widgets/maker_bottom_navigation.dart';
import '../../application/saved_artworks_controller.dart';

class MakerSavedArtworksScreen extends ConsumerStatefulWidget {
  const MakerSavedArtworksScreen({
    super.key,
    this.onBack,
    this.onArtworkTap,
    this.onSettingsTap,
  });

  final VoidCallback? onBack;
  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final VoidCallback? onSettingsTap;

  @override
  ConsumerState<MakerSavedArtworksScreen> createState() =>
      _MakerSavedArtworksScreenState();
}

class _MakerSavedArtworksScreenState
    extends ConsumerState<MakerSavedArtworksScreen> {
  int? _scheduledPerPage;

  void _ensurePageSize(SavedArtworksState state, int perPage) {
    if (state.isLoading) return;

    final neverLoaded =
        state.meta.currentPage == null && state.errorMessage == null;
    final needsResponsiveReload =
        state.meta.currentPage != null && state.perPage != perPage;

    if (!neverLoaded && !needsResponsiveReload) return;
    if (_scheduledPerPage == perPage) return;

    _scheduledPerPage = perPage;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref
          .read(savedArtworksControllerProvider.notifier)
          .loadInitial(perPage: perPage);

      if (mounted && _scheduledPerPage == perPage) {
        _scheduledPerPage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedArtworksControllerProvider);

    return Scaffold(
      key: const Key('maker_saved_artworks_screen'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = DiscoveryLayoutMetrics.fromWidth(
              constraints.maxWidth,
            );
            final gridHeight = math.max(
              0.0,
              constraints.maxHeight -
                  metrics.toolbarHeight -
                  metrics.controlsToGridGap,
            );
            final perPage = metrics.itemsPerPageFor(gridHeight);

            _ensurePageSize(state, perPage);

            return Column(
              children: [
                SizedBox(
                  height: metrics.toolbarHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.gridHorizontalPadding,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: IconButton(
                              key: const Key('saved_artworks_back_button'),
                              onPressed: widget.onBack,
                              padding: EdgeInsets.zero,
                              alignment: Alignment.bottomLeft,
                              color: AppColors.primary,
                              iconSize: 24,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              'Saved',
                              style: AppTextStyles.onboardingHeading.copyWith(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48, height: 48),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  key: const Key('saved_controls_grid_gap'),
                  height: metrics.controlsToGridGap,
                ),
                Expanded(
                  child: _SavedBody(
                    state: state,
                    horizontalPadding: metrics.gridHorizontalPadding,
                    gridSpacing: metrics.gridSpacing,
                    onArtworkTap: widget.onArtworkTap,
                    onRemove: (artworkId) {
                      ref
                          .read(savedArtworksControllerProvider.notifier)
                          .remove(artworkId);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MakerBottomNavigation(
        selectedPage: state.meta.currentPage ?? 1,
        totalPages: state.meta.lastPage ?? 1,
        heartSelected: true,
        onSavedTap: () {},
        onPageSelected: (page) {
          ref.read(savedArtworksControllerProvider.notifier).goToPage(page);
        },
        onSettingsTap: widget.onSettingsTap,
      ),
    );
  }
}

class _SavedBody extends ConsumerWidget {
  const _SavedBody({
    required this.state,
    required this.horizontalPadding,
    required this.gridSpacing,
    required this.onArtworkTap,
    required this.onRemove,
  });

  final SavedArtworksState state;
  final double horizontalPadding;
  final double gridSpacing;
  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                key: const Key('saved_artworks_retry_button'),
                onPressed: () {
                  ref
                      .read(savedArtworksControllerProvider.notifier)
                      .refresh();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Text(
          'No saved artwork yet.',
          key: Key('saved_artworks_empty'),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            color: AppColors.mutedText,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        key: const Key('maker_saved_artworks_grid'),
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: state.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: gridSpacing,
          crossAxisSpacing: gridSpacing,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final artwork = state.items[index];

          return Stack(
            fit: StackFit.expand,
            children: [
              DiscoveryArtworkTile(
                artwork: artwork,
                onTap: () => onArtworkTap?.call(artwork),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: AppColors.splashBackground.withValues(alpha: 0.86),
                  shape: const CircleBorder(),
                  child: InkResponse(
                    key: Key(
                      'saved_artwork_remove_' + artwork.id.toString(),
                    ),
                    onTap: () => onRemove(artwork.id),
                    radius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox.square(
                        dimension: 16,
                        child: SvgPicture.asset(
                          'assets/icons/heart.svg',
                          colorFilter: const ColorFilter.mode(
                            AppColors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

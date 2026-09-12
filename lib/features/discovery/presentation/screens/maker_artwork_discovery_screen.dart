import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_svg_asset.dart';
import '../../application/artwork_discovery_controller.dart';
import '../../domain/discovery_artwork.dart';
import '../../domain/discovery_query.dart';
import '../widgets/discovery_artwork_tile.dart';
import '../widgets/discovery_layout_metrics.dart';
import '../widgets/maker_bottom_navigation.dart';

class MakerArtworkDiscoveryScreen extends ConsumerStatefulWidget {
  const MakerArtworkDiscoveryScreen({
    super.key,
    this.onArtworkTap,
    this.onSearchTap,
    this.onFilterTap,
    this.onSavedTap,
    this.onSettingsTap,
    this.onBottomNavigationTap,
  });

  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSavedTap;
  final VoidCallback? onSettingsTap;

  /// Kept for compatibility with the earlier Maker navigation contract.
  final ValueChanged<int>? onBottomNavigationTap;

  @override
  ConsumerState<MakerArtworkDiscoveryScreen> createState() =>
      _MakerArtworkDiscoveryScreenState();
}

class _MakerArtworkDiscoveryScreenState
    extends ConsumerState<MakerArtworkDiscoveryScreen> {
  int? _scheduledPerPage;

  void _ensurePageSize({
    required ArtworkDiscoveryState state,
    required DiscoveryQuery query,
    required int perPage,
  }) {
    if (state.isLoadingInitial) return;

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
          .read(artworkDiscoveryControllerProvider.notifier)
          .loadInitial(query: query, perPage: perPage);

      if (mounted && _scheduledPerPage == perPage) {
        _scheduledPerPage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artworkDiscoveryControllerProvider);
    final query = ref.watch(discoveryQueryProvider);
    final filterCount = query.activeFilterCount;

    return Scaffold(
      key: const Key('maker_artwork_discovery_screen'),
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

            _ensurePageSize(state: state, query: query, perPage: perPage);

            return Column(
              children: [
                SizedBox(
                  height: metrics.toolbarHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.gridHorizontalPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ToolbarSvgButton(
                          buttonKey: const Key('discovery_search_button'),
                          iconKey: const Key('discovery_search_svg'),
                          assetName: 'assets/search.svg',
                          fallbackAssetName: 'assets/icons/search.svg',
                          tooltip: 'Search artwork and Makers',
                          size: metrics.toolbarIconSize,
                          alignment: Alignment.bottomLeft,
                          onPressed: widget.onSearchTap ?? () {},
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _ToolbarSvgButton(
                              buttonKey: const Key('discovery_filter_button'),
                              iconKey: const Key('discovery_filter_svg'),
                              assetName: 'assets/filter.svg',
                              fallbackAssetName: 'assets/icons/filter.svg',
                              tooltip: 'Filter artwork',
                              size: metrics.toolbarIconSize,
                              alignment: Alignment.bottomRight,
                              onPressed: widget.onFilterTap ?? () {},
                            ),
                            if (filterCount > 0)
                              Positioned(
                                right: -5,
                                bottom: metrics.toolbarIconSize - 2,
                                child: Container(
                                  key: const Key('active_filter_badge'),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$filterCount',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.black,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  key: const Key('discovery_controls_grid_gap'),
                  height: metrics.controlsToGridGap,
                ),
                Expanded(
                  child: _DiscoveryBody(
                    state: state,
                    horizontalPadding: metrics.gridHorizontalPadding,
                    gridSpacing: metrics.gridSpacing,
                    childAspectRatio: metrics.gridChildAspectRatioFor(gridHeight),
                    onArtworkTap: widget.onArtworkTap,
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
        onSavedTap:
            widget.onSavedTap ?? () => widget.onBottomNavigationTap?.call(0),
        onPageSelected: (page) {
          ref.read(artworkDiscoveryControllerProvider.notifier).goToPage(page);
        },
        onSettingsTap:
            widget.onSettingsTap ?? () => widget.onBottomNavigationTap?.call(4),
      ),
    );
  }
}

class _ToolbarSvgButton extends StatelessWidget {
  const _ToolbarSvgButton({
    required this.buttonKey,
    required this.iconKey,
    required this.assetName,
    required this.fallbackAssetName,
    required this.tooltip,
    required this.size,
    required this.alignment,
    required this.onPressed,
  });

  final Key buttonKey;
  final Key iconKey;
  final String assetName;
  final String fallbackAssetName;
  final String tooltip;
  final double size;
  final Alignment alignment;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          key: buttonKey,
          onTap: onPressed,
          radius: 28,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Align(
              alignment: alignment,
              child: SizedBox(
                key: iconKey,
                width: size,
                height: size,
                child: MaSvgAsset(
                  assetName: assetName,
                  fallbackAssetName: fallbackAssetName,
                  fit: BoxFit.contain,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryBody extends ConsumerWidget {
  const _DiscoveryBody({
    required this.state,
    required this.horizontalPadding,
    required this.gridSpacing,
    required this.childAspectRatio,
    required this.onArtworkTap,
  });

  final ArtworkDiscoveryState state;
  final double horizontalPadding;
  final double gridSpacing;
  final double childAspectRatio;
  final ValueChanged<DiscoveryArtwork>? onArtworkTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingInitial && state.items.isEmpty) {
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
                key: const Key('discovery_retry_button'),
                onPressed: () {
                  ref
                      .read(artworkDiscoveryControllerProvider.notifier)
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
          'No artwork matches these filters.',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            color: AppColors.mutedText,
          ),
        ),
      );
    }

    return Padding(
      key: const Key('discovery_grid_padding'),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GridView.builder(
        key: const Key('maker_artwork_discovery_grid'),
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: state.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: gridSpacing,
          crossAxisSpacing: gridSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          final artwork = state.items[index];

          return DiscoveryArtworkTile(
            artwork: artwork,
            onTap: () => onArtworkTap?.call(artwork),
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_svg_asset.dart';
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
  static const int _savedPerPage = 24;

  late final ScrollController _scrollController;
  bool _initialLoadScheduled = false;
  int _columnCount = 2;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 520) {
      unawaited(ref.read(savedArtworksControllerProvider.notifier).loadMore());
    }
  }

  void _scheduleInitialLoad(SavedArtworksState state) {
    if (state.meta.currentPage != null ||
        state.isLoading ||
        _initialLoadScheduled) {
      return;
    }

    _initialLoadScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref
          .read(savedArtworksControllerProvider.notifier)
          .loadInitial(perPage: _savedPerPage);

      if (mounted) {
        _initialLoadScheduled = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savedArtworksControllerProvider);
    _scheduleInitialLoad(state);

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
                    scrollController: _scrollController,
                    horizontalPadding: metrics.gridHorizontalPadding,
                    gridSpacing: metrics.gridSpacing,
                    columnCount: _columnCount,
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
        selectedColumnCount: _columnCount,
        heartSelected: true,
        onSavedTap: () {},
        onColumnCountSelected: (columnCount) {
          if (_columnCount == columnCount) return;

          setState(() {
            _columnCount = columnCount;
          });
        },
        onSettingsTap: widget.onSettingsTap,
      ),
    );
  }
}

class _SavedBody extends ConsumerWidget {
  const _SavedBody({
    required this.state,
    required this.scrollController,
    required this.horizontalPadding,
    required this.gridSpacing,
    required this.columnCount,
    required this.onArtworkTap,
    required this.onRemove,
  });

  final SavedArtworksState state;
  final ScrollController scrollController;
  final double horizontalPadding;
  final double gridSpacing;
  final int columnCount;
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
                  ref.read(savedArtworksControllerProvider.notifier).refresh();
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
        controller: scrollController,
        padding: EdgeInsets.zero,
        itemCount: state.items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
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
                    key: Key('saved_artwork_remove_${artwork.id}'),
                    onTap: () => onRemove(artwork.id),
                    radius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox.square(
                        dimension: 16,
                        child: const MaSvgAsset(
                          assetName: 'assets/heart.svg',
                          fallbackAssetName: 'assets/icons/heart.svg',
                          color: AppColors.primary,
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

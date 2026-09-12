import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/artwork_discovery_controller.dart';
import '../../domain/discovery_artwork.dart';
import '../../domain/discovery_query.dart';
import '../widgets/discovery_artwork_tile.dart';
import '../widgets/maker_bottom_navigation.dart';

class MakerArtworkDiscoveryScreen extends ConsumerStatefulWidget {
  const MakerArtworkDiscoveryScreen({
    super.key,
    this.onArtworkTap,
    this.onSearchTap,
    this.onFilterTap,
    this.onBottomNavigationTap,
  });

  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<int>? onBottomNavigationTap;

  @override
  ConsumerState<MakerArtworkDiscoveryScreen> createState() =>
      _MakerArtworkDiscoveryScreenState();
}

class _MakerArtworkDiscoveryScreenState
    extends ConsumerState<MakerArtworkDiscoveryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(artworkDiscoveryControllerProvider);
      final query = ref.read(discoveryQueryProvider);
      if (state.items.isEmpty && !state.isLoadingInitial) {
        ref
            .read(artworkDiscoveryControllerProvider.notifier)
            .loadInitial(query: query);
      }
    });
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
      ref.read(artworkDiscoveryControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artworkDiscoveryControllerProvider);
    final filterCount = ref.watch(
      discoveryQueryProvider.select((query) => query.activeFilterCount),
    );

    return Scaffold(
      key: const Key('maker_artwork_discovery_screen'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      key: const Key('discovery_search_button'),
                      tooltip: 'Search artwork and Makers',
                      onPressed: widget.onSearchTap ?? () {},
                      iconSize: 30,
                      color: AppColors.primary,
                      icon: const Icon(Icons.search_rounded),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: const Key('discovery_filter_button'),
                          tooltip: 'Filter artwork',
                          onPressed: widget.onFilterTap ?? () {},
                          iconSize: 30,
                          color: AppColors.primary,
                          icon: const Icon(Icons.tune_rounded),
                        ),
                        if (filterCount > 0)
                          Positioned(
                            right: 0,
                            top: 2,
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
            Expanded(
              child: _DiscoveryBody(
                state: state,
                scrollController: _scrollController,
                onArtworkTap: widget.onArtworkTap,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MakerBottomNavigation(
        selectedPage: (state.meta.currentPage ?? 1).clamp(1, 4).toInt(),
        onPageSelected: (page) {
          ref
              .read(artworkDiscoveryControllerProvider.notifier)
              .goToPage(page);

          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          }
        },
        onSettingsTap: () => widget.onBottomNavigationTap?.call(4),
      ),
    );
  }
}

class _DiscoveryBody extends ConsumerWidget {
  const _DiscoveryBody({
    required this.state,
    required this.scrollController,
    required this.onArtworkTap,
  });

  final ArtworkDiscoveryState state;
  final ScrollController scrollController;
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

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.inputFill,
      onRefresh: () {
        return ref.read(artworkDiscoveryControllerProvider.notifier).refresh();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = (constraints.maxWidth * 0.047).clamp(
            16.0,
            24.0,
          );

          return CustomScrollView(
            key: const Key('maker_artwork_discovery_scroll'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  8,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final artwork = state.items[index];
                    return DiscoveryArtworkTile(
                      artwork: artwork,
                      onTap: () => onArtworkTap?.call(artwork),
                    );
                  }, childCount: state.items.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 1,
                  ),
                ),
              ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.primary,
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

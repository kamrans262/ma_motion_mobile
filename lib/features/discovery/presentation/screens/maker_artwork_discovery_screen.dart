import 'dart:async';

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
    this.onFilterTap,
    this.onSavedTap,
    this.onSettingsTap,
    this.onBottomNavigationTap,
  });

  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSavedTap;
  final VoidCallback? onSettingsTap;

  /// Kept for compatibility with the existing Maker navigation contract.
  final ValueChanged<int>? onBottomNavigationTap;

  @override
  ConsumerState<MakerArtworkDiscoveryScreen> createState() =>
      _MakerArtworkDiscoveryScreenState();
}

class _MakerArtworkDiscoveryScreenState
    extends ConsumerState<MakerArtworkDiscoveryScreen> {
  static const int _discoveryPerPage = 48;

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;

  Timer? _searchDebounce;
  bool _searchOpen = false;
  bool _initialLoadScheduled = false;
  int _columnCount = 2;

  @override
  void initState() {
    super.initState();

    final initialSearch = ref
        .read(artworkDiscoveryControllerProvider)
        .query
        .search;

    _searchController = TextEditingController(text: initialSearch);
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _searchOpen = initialSearch.isNotEmpty;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.extentAfter < 520) {
      unawaited(
        ref.read(artworkDiscoveryControllerProvider.notifier).loadMore(),
      );
    }
  }

  void _scheduleInitialLoad(
    ArtworkDiscoveryState state,
    DiscoveryQuery filters,
  ) {
    if (state.meta.currentPage != null ||
        state.isLoadingInitial ||
        _initialLoadScheduled) {
      return;
    }

    _initialLoadScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await ref
          .read(artworkDiscoveryControllerProvider.notifier)
          .loadInitial(
            query: filters.withSearch(_searchController.text),
            perPage: _discoveryPerPage,
          );

      if (mounted) {
        _initialLoadScheduled = false;
      }
    });
  }

  void _openSearch() {
    if (!_searchOpen) {
      setState(() {
        _searchOpen = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _applySearch(value),
    );
  }

  Future<void> _applySearch(String value) {
    final filters = ref.read(discoveryQueryProvider);
    return ref
        .read(artworkDiscoveryControllerProvider.notifier)
        .loadInitial(
          query: filters.withSearch(value),
          perPage: _discoveryPerPage,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(artworkDiscoveryControllerProvider);
    final filters = ref.watch(discoveryQueryProvider);
    final filterCount = filters.activeFilterCount;

    _scheduleInitialLoad(state, filters);

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

            return Column(
              children: [
                SizedBox(
                  height: metrics.toolbarHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.gridHorizontalPadding,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ToolbarSvgButton(
                          buttonKey: const Key('discovery_search_button'),
                          iconKey: const Key('discovery_search_svg'),
                          assetName: 'assets/search.svg',
                          fallbackAssetName: 'assets/icons/search.svg',
                          tooltip: 'Search artwork',
                          size: metrics.toolbarIconSize,
                          alignment: Alignment.centerLeft,
                          onPressed: _openSearch,
                        ),
                        if (_searchOpen) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                key: const Key('discovery_inline_search'),
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: _onSearchChanged,
                                textInputAction: TextInputAction.search,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 14,
                                  height: 1,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primary,
                                ),
                                cursorColor: AppColors.primary,
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Artist name...',
                                  hintStyle: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: 14,
                                    height: 1,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.50,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.only(
                                    left: 0,
                                    right: 4,
                                    top: 10,
                                    bottom: 8,
                                  ),
                                  border: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
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
                              alignment: Alignment.centerRight,
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
                    scrollController: _scrollController,
                    horizontalPadding: metrics.gridHorizontalPadding,
                    gridSpacing: metrics.gridSpacing,
                    columnCount: _columnCount,
                    onArtworkTap: widget.onArtworkTap,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MakerBottomNavigation(
        selectedColumnCount: _columnCount,
        onSavedTap:
            widget.onSavedTap ?? () => widget.onBottomNavigationTap?.call(0),
        onColumnCountSelected: (columnCount) {
          if (_columnCount == columnCount) return;

          setState(() {
            _columnCount = columnCount;
          });
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
    required this.scrollController,
    required this.horizontalPadding,
    required this.gridSpacing,
    required this.columnCount,
    required this.onArtworkTap,
  });

  final ArtworkDiscoveryState state;
  final ScrollController scrollController;
  final double horizontalPadding;
  final double gridSpacing;
  final int columnCount;
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

          return DiscoveryArtworkTile(
            artwork: artwork,
            onTap: () => onArtworkTap?.call(artwork),
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../application/discovery_search_controller.dart';
import '../../domain/discovery_artwork.dart';
import '../../domain/discovery_query.dart';
import '../../domain/discovery_search_result.dart';
import '../widgets/discovery_artwork_tile.dart';

class DiscoverySearchScreen extends ConsumerStatefulWidget {
  const DiscoverySearchScreen({
    super.key,
    this.onBack,
    this.onFilterTap,
    this.onArtworkTap,
    this.onMakerTap,
  });

  final VoidCallback? onBack;
  final VoidCallback? onFilterTap;
  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final ValueChanged<DiscoverySearchMaker>? onMakerTap;

  @override
  ConsumerState<DiscoverySearchScreen> createState() =>
      _DiscoverySearchScreenState();
}

class _DiscoverySearchScreenState extends ConsumerState<DiscoverySearchScreen> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 520) {
      ref.read(discoverySearchControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(value),
    );
  }

  Future<void> _runSearch([String? value]) {
    final term = (value ?? _searchController.text).trim();
    final filters = ref.read(discoveryQueryProvider);

    return ref
        .read(discoverySearchControllerProvider.notifier)
        .search(term: term, filters: filters);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverySearchControllerProvider);
    final filterCount = ref.watch(
      discoveryQueryProvider.select((query) => query.activeFilterCount),
    );

    ref.listen<DiscoveryQuery>(discoveryQueryProvider, (previous, next) {
      if (_searchController.text.trim().isNotEmpty) {
        _runSearch();
      }
    });

    return Scaffold(
      key: const Key('discovery_search_screen'),
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 14),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('search_back_button'),
                    onPressed: widget.onBack,
                    color: AppColors.primary,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('discovery_search_field'),
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      style: AppTextStyles.field.copyWith(fontSize: 16),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Search Makers, artwork or shows',
                        hintStyle: AppTextStyles.fieldHint.copyWith(
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.primary50),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        key: const Key('search_filter_button'),
                        onPressed: widget.onFilterTap,
                        color: AppColors.primary,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                      if (filterCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            key: const Key('search_filter_badge'),
                            constraints: const BoxConstraints(
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$filterCount',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 9,
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
            Expanded(
              child: _SearchBody(
                state: state,
                scrollController: _scrollController,
                onRetry: _runSearch,
                onArtworkTap: widget.onArtworkTap,
                onMakerTap: widget.onMakerTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.state,
    required this.scrollController,
    required this.onRetry,
    required this.onArtworkTap,
    required this.onMakerTap,
  });

  final DiscoverySearchState state;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final ValueChanged<DiscoverySearchMaker>? onMakerTap;

  @override
  Widget build(BuildContext context) {
    if (state.term.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 34),
          child: Text(
            'Search by Maker name, artwork, show or other public content.',
            textAlign: TextAlign.center,
            style: AppTextStyles.onboardingHelper,
          ),
        ),
      );
    }

    if (state.isLoadingInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null &&
        state.artworks.isEmpty &&
        state.makers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingHelper,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
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
      );
    }

    if (state.isEmpty) {
      return const Center(
        child: Text('No results found.', style: AppTextStyles.onboardingHelper),
      );
    }

    return CustomScrollView(
      key: const Key('search_results_scroll'),
      controller: scrollController,
      slivers: [
        if (state.makers.isNotEmpty) ...[
          const _SectionHeader(title: 'Makers'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final maker = state.makers[index];
                return _MakerTile(
                  maker: maker,
                  onTap: onMakerTap == null ? null : () => onMakerTap!(maker),
                );
              }, childCount: state.makers.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.94,
              ),
            ),
          ),
        ],
        if (state.artworks.isNotEmpty) ...[
          const _SectionHeader(title: 'Artwork'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final artwork = state.artworks[index];
                return DiscoveryArtworkTile(
                  artwork: artwork,
                  onTap: onArtworkTap == null
                      ? null
                      : () => onArtworkTap!(artwork),
                );
              }, childCount: state.artworks.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                childAspectRatio: 1,
              ),
            ),
          ),
        ],
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
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: Text(
          title,
          style: AppTextStyles.onboardingHeading.copyWith(fontSize: 20),
        ),
      ),
    );
  }
}

class _MakerTile extends StatelessWidget {
  const _MakerTile({required this.maker, required this.onTap});

  final DiscoverySearchMaker maker;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      child: InkWell(
        key: Key('search_maker_${maker.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: maker.profileImageUrl == null
                  ? const ColoredBox(
                      color: Color(0xFF13271D),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 46,
                        color: AppColors.primary,
                      ),
                    )
                  : Image.network(
                      maker.profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFF13271D),
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 46,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 4),
              child: Text(
                maker.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.onboardingHelper.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 9),
              child: Text(
                '${maker.statistics.savedCount} saves · '
                '${maker.statistics.artworkCount} works',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.onboardingHelper.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

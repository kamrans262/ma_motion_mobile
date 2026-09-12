import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/pagination_meta.dart';
import '../data/artwork_discovery_repository.dart';
import '../domain/discovery_artwork.dart';
import '../domain/discovery_query.dart';

final artworkDiscoveryControllerProvider =
    NotifierProvider<ArtworkDiscoveryController, ArtworkDiscoveryState>(
      ArtworkDiscoveryController.new,
    );

class ArtworkDiscoveryState {
  const ArtworkDiscoveryState({
    this.items = const <DiscoveryArtwork>[],
    this.meta = const PaginationMeta(),
    this.query = const DiscoveryQuery(),
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<DiscoveryArtwork> items;
  final PaginationMeta meta;
  final DiscoveryQuery query;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isEmpty =>
      items.isEmpty && !isLoadingInitial && errorMessage == null;

  ArtworkDiscoveryState copyWith({
    List<DiscoveryArtwork>? items,
    PaginationMeta? meta,
    DiscoveryQuery? query,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ArtworkDiscoveryState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ArtworkDiscoveryController extends Notifier<ArtworkDiscoveryState> {
  @override
  ArtworkDiscoveryState build() => const ArtworkDiscoveryState();

  ArtworkDiscoveryRepositoryContract get _repository =>
      ref.read(artworkDiscoveryRepositoryProvider);

  Future<void> loadInitial({DiscoveryQuery? query}) async {
    if (state.isLoadingInitial) {
      return;
    }

    final effectiveQuery = query ?? state.query;

    state = ArtworkDiscoveryState(
      query: effectiveQuery,
      isLoadingInitial: true,
    );

    try {
      final page = await _repository.fetchPage(page: 1, query: effectiveQuery);

      state = ArtworkDiscoveryState(
        items: page.items,
        meta: page.meta,
        query: effectiveQuery,
      );
    } catch (error) {
      state = ArtworkDiscoveryState(
        query: effectiveQuery,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> applyQuery(DiscoveryQuery query) {
    return loadInitial(query: query.withoutSearch());
  }

  Future<void> refresh() {
    return loadInitial(query: state.query);
  }


  Future<void> goToPage(int page) async {
    if (page < 1 || state.isLoadingInitial || state.isLoadingMore) {
      return;
    }

    state = ArtworkDiscoveryState(
      query: state.query,
      isLoadingInitial: true,
    );

    try {
      final result = await _repository.fetchPage(
        page: page,
        query: state.query,
      );

      state = ArtworkDiscoveryState(
        items: result.items,
        meta: result.meta,
        query: state.query,
      );
    } catch (error) {
      state = ArtworkDiscoveryState(
        query: state.query,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingInitial ||
        state.isLoadingMore ||
        !state.meta.hasNextPage) {
      return;
    }

    final currentPage = state.meta.currentPage ?? 1;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = await _repository.fetchPage(
        page: currentPage + 1,
        query: state.query,
      );

      final existingIds = state.items.map((item) => item.id).toSet();

      state = ArtworkDiscoveryState(
        items: <DiscoveryArtwork>[
          ...state.items,
          ...nextPage.items.where(
            (candidate) => !existingIds.contains(candidate.id),
          ),
        ],
        meta: nextPage.meta,
        query: state.query,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _messageFor(error),
      );
    }
  }

  static String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'We could not load artwork. Please try again.';
  }
}

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
    this.perPage = 24,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<DiscoveryArtwork> items;
  final PaginationMeta meta;
  final DiscoveryQuery query;
  final int perPage;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isEmpty =>
      items.isEmpty && !isLoadingInitial && errorMessage == null;

  ArtworkDiscoveryState copyWith({
    List<DiscoveryArtwork>? items,
    PaginationMeta? meta,
    DiscoveryQuery? query,
    int? perPage,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ArtworkDiscoveryState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      query: query ?? this.query,
      perPage: perPage ?? this.perPage,
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

  Future<void> loadInitial({DiscoveryQuery? query, int? perPage}) async {
    if (state.isLoadingInitial) {
      return;
    }

    final effectiveQuery = query ?? state.query;
    final effectivePerPage = perPage ?? state.perPage;

    state = ArtworkDiscoveryState(
      query: effectiveQuery,
      perPage: effectivePerPage,
      isLoadingInitial: true,
    );

    try {
      final page = await _repository.fetchPage(
        page: 1,
        perPage: effectivePerPage,
        query: effectiveQuery,
      );

      state = ArtworkDiscoveryState(
        items: page.items,
        meta: page.meta,
        query: effectiveQuery,
        perPage: effectivePerPage,
      );
    } catch (error) {
      state = ArtworkDiscoveryState(
        query: effectiveQuery,
        perPage: effectivePerPage,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> applyQuery(DiscoveryQuery query) {
    return loadInitial(query: query.withoutSearch(), perPage: state.perPage);
  }

  Future<void> refresh() {
    return loadInitial(query: state.query, perPage: state.perPage);
  }

  Future<void> goToPage(int page) async {
    final lastPage = state.meta.lastPage;
    final currentPage = state.meta.currentPage;

    if (page < 1 ||
        (lastPage != null && page > lastPage) ||
        page == currentPage ||
        state.isLoadingInitial ||
        state.isLoadingMore) {
      return;
    }

    final query = state.query;
    final perPage = state.perPage;

    state = ArtworkDiscoveryState(
      query: query,
      perPage: perPage,
      isLoadingInitial: true,
    );

    try {
      final result = await _repository.fetchPage(
        page: page,
        perPage: perPage,
        query: query,
      );

      state = ArtworkDiscoveryState(
        items: result.items,
        meta: result.meta,
        query: query,
        perPage: perPage,
      );
    } catch (error) {
      state = ArtworkDiscoveryState(
        query: query,
        perPage: perPage,
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
        perPage: state.perPage,
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
        perPage: state.perPage,
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/pagination_meta.dart';
import '../data/artwork_discovery_repository.dart';
import '../domain/discovery_artwork.dart';

final artworkDiscoveryControllerProvider =
    NotifierProvider<ArtworkDiscoveryController, ArtworkDiscoveryState>(
      ArtworkDiscoveryController.new,
    );

class ArtworkDiscoveryState {
  const ArtworkDiscoveryState({
    this.items = const <DiscoveryArtwork>[],
    this.meta = const PaginationMeta(),
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<DiscoveryArtwork> items;
  final PaginationMeta meta;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isEmpty =>
      items.isEmpty && !isLoadingInitial && errorMessage == null;

  ArtworkDiscoveryState copyWith({
    List<DiscoveryArtwork>? items,
    PaginationMeta? meta,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ArtworkDiscoveryState(
      items: items ?? this.items,
      meta: meta ?? this.meta,
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

  Future<void> loadInitial() async {
    if (state.isLoadingInitial) {
      return;
    }

    state = state.copyWith(
      isLoadingInitial: true,
      isLoadingMore: false,
      clearError: true,
    );

    try {
      final page = await _repository.fetchPage(page: 1);

      state = ArtworkDiscoveryState(items: page.items, meta: page.meta);
    } catch (error) {
      state = state.copyWith(
        isLoadingInitial: false,
        isLoadingMore: false,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> refresh() => loadInitial();

  Future<void> loadMore() async {
    if (state.isLoadingInitial ||
        state.isLoadingMore ||
        !state.meta.hasNextPage) {
      return;
    }

    final currentPage = state.meta.currentPage ?? 1;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final nextPage = await _repository.fetchPage(page: currentPage + 1);

      final existingIds = state.items.map((item) => item.id).toSet();
      final merged = <DiscoveryArtwork>[
        ...state.items,
        ...nextPage.items.where(
          (candidate) => !existingIds.contains(candidate.id),
        ),
      ];

      state = ArtworkDiscoveryState(items: merged, meta: nextPage.meta);
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _messageFor(error),
      );
    }
  }

  static String _messageFor(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'We could not load artwork. Please try again.';
  }
}

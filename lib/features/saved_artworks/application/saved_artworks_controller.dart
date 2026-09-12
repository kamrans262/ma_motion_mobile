import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/pagination_meta.dart';
import '../../discovery/domain/discovery_artwork.dart';
import '../data/saved_artworks_repository.dart';

final savedArtworksControllerProvider =
    NotifierProvider<SavedArtworksController, SavedArtworksState>(
      SavedArtworksController.new,
    );

class SavedArtworksState {
  const SavedArtworksState({
    this.items = const <DiscoveryArtwork>[],
    this.meta = const PaginationMeta(),
    this.perPage = 24,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<DiscoveryArtwork> items;
  final PaginationMeta meta;
  final int perPage;
  final bool isLoading;
  final String? errorMessage;

  bool get isEmpty => items.isEmpty && !isLoading && errorMessage == null;
}

class SavedArtworksController extends Notifier<SavedArtworksState> {
  @override
  SavedArtworksState build() => const SavedArtworksState();

  SavedArtworksRepositoryContract get _repository =>
      ref.read(savedArtworksRepositoryProvider);

  Future<void> loadInitial({int? perPage}) {
    return _loadPage(
      1,
      perPage: perPage ?? state.perPage,
      append: false,
    );
  }

  Future<void> refresh() => loadInitial(perPage: state.perPage);

  Future<void> loadMore() async {
    if (state.isLoading || !state.meta.hasNextPage) return;

    final currentPage = state.meta.currentPage ?? 1;
    await _loadPage(
      currentPage + 1,
      perPage: state.perPage,
      append: true,
    );
  }

  Future<void> remove(int artworkId) async {
    if (state.isLoading) return;

    try {
      await _repository.unsave(artworkId);
      await loadInitial(perPage: state.perPage);
    } catch (error) {
      state = SavedArtworksState(
        items: state.items,
        meta: state.meta,
        perPage: state.perPage,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> _loadPage(
    int page, {
    required int perPage,
    required bool append,
  }) async {
    if (state.isLoading) return;

    final previous = state;
    state = SavedArtworksState(
      items: previous.items,
      meta: previous.meta,
      perPage: perPage,
      isLoading: true,
    );

    try {
      final result = await _repository.fetchPage(page: page, perPage: perPage);

      if (!append) {
        state = SavedArtworksState(
          items: result.items,
          meta: result.meta,
          perPage: perPage,
        );
        return;
      }

      final existingIds = previous.items.map((item) => item.id).toSet();

      state = SavedArtworksState(
        items: <DiscoveryArtwork>[
          ...previous.items,
          ...result.items.where(
            (candidate) => !existingIds.contains(candidate.id),
          ),
        ],
        meta: result.meta,
        perPage: perPage,
      );
    } catch (error) {
      state = SavedArtworksState(
        items: previous.items,
        meta: previous.meta,
        perPage: perPage,
        errorMessage: _messageFor(error),
      );
    }
  }

  static String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'We could not load saved artwork. Please try again.';
  }
}

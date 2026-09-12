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
    return _loadPage(1, perPage: perPage ?? state.perPage);
  }

  Future<void> refresh() {
    return _loadPage(state.meta.currentPage ?? 1, perPage: state.perPage);
  }

  Future<void> goToPage(int page) async {
    final lastPage = state.meta.lastPage;

    if (page < 1 ||
        (lastPage != null && page > lastPage) ||
        page == state.meta.currentPage ||
        state.isLoading) {
      return;
    }

    await _loadPage(page, perPage: state.perPage);
  }

  Future<void> remove(int artworkId) async {
    if (state.isLoading) return;

    try {
      await _repository.unsave(artworkId);

      final currentPage = state.meta.currentPage ?? 1;
      final targetPage = state.items.length == 1 && currentPage > 1
          ? currentPage - 1
          : currentPage;

      await _loadPage(targetPage, perPage: state.perPage);
    } catch (error) {
      state = SavedArtworksState(
        items: state.items,
        meta: state.meta,
        perPage: state.perPage,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> _loadPage(int page, {required int perPage}) async {
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

      state = SavedArtworksState(
        items: result.items,
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

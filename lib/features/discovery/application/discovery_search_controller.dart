import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/pagination_meta.dart';
import '../data/discovery_search_repository.dart';
import '../domain/discovery_artwork.dart';
import '../domain/discovery_query.dart';
import '../domain/discovery_search_result.dart';

final discoverySearchControllerProvider =
    NotifierProvider<DiscoverySearchController, DiscoverySearchState>(
      DiscoverySearchController.new,
    );

class DiscoverySearchState {
  const DiscoverySearchState({
    this.term = '',
    this.query = const DiscoveryQuery(),
    this.artworks = const <DiscoveryArtwork>[],
    this.makers = const <DiscoverySearchMaker>[],
    this.artworkMeta = const PaginationMeta(),
    this.makerMeta = const PaginationMeta(),
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final String term;
  final DiscoveryQuery query;
  final List<DiscoveryArtwork> artworks;
  final List<DiscoverySearchMaker> makers;
  final PaginationMeta artworkMeta;
  final PaginationMeta makerMeta;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isEmpty =>
      term.isNotEmpty &&
      artworks.isEmpty &&
      makers.isEmpty &&
      !isLoadingInitial &&
      errorMessage == null;

  bool get hasNextPage => artworkMeta.hasNextPage || makerMeta.hasNextPage;
}

class DiscoverySearchController extends Notifier<DiscoverySearchState> {
  @override
  DiscoverySearchState build() => const DiscoverySearchState();

  DiscoverySearchRepositoryContract get _repository =>
      ref.read(discoverySearchRepositoryProvider);

  Future<void> search({
    required String term,
    required DiscoveryQuery filters,
  }) async {
    final normalized = term.trim();

    if (normalized.isEmpty) {
      state = const DiscoverySearchState();
      return;
    }

    final query = filters.withSearch(normalized);

    state = DiscoverySearchState(
      term: normalized,
      query: query,
      isLoadingInitial: true,
    );

    try {
      final page = await _repository.search(query: query, page: 1);

      state = DiscoverySearchState(
        term: normalized,
        query: query,
        artworks: page.artworks,
        makers: page.makers,
        artworkMeta: page.artworkMeta,
        makerMeta: page.makerMeta,
      );
    } catch (error) {
      state = DiscoverySearchState(
        term: normalized,
        query: query,
        errorMessage: _messageFor(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.term.isEmpty ||
        state.isLoadingInitial ||
        state.isLoadingMore ||
        !state.hasNextPage) {
      return;
    }

    final currentPage = math.max(
      state.artworkMeta.currentPage ?? 1,
      state.makerMeta.currentPage ?? 1,
    );
    final oldState = state;

    state = DiscoverySearchState(
      term: oldState.term,
      query: oldState.query,
      artworks: oldState.artworks,
      makers: oldState.makers,
      artworkMeta: oldState.artworkMeta,
      makerMeta: oldState.makerMeta,
      isLoadingMore: true,
    );

    try {
      final page = await _repository.search(
        query: oldState.query,
        page: currentPage + 1,
      );

      final artworkIds = oldState.artworks.map((item) => item.id).toSet();
      final makerIds = oldState.makers.map((item) => item.id).toSet();

      state = DiscoverySearchState(
        term: oldState.term,
        query: oldState.query,
        artworks: <DiscoveryArtwork>[
          ...oldState.artworks,
          ...page.artworks.where((item) => !artworkIds.contains(item.id)),
        ],
        makers: <DiscoverySearchMaker>[
          ...oldState.makers,
          ...page.makers.where((item) => !makerIds.contains(item.id)),
        ],
        artworkMeta: page.artworkMeta,
        makerMeta: page.makerMeta,
      );
    } catch (error) {
      state = DiscoverySearchState(
        term: oldState.term,
        query: oldState.query,
        artworks: oldState.artworks,
        makers: oldState.makers,
        artworkMeta: oldState.artworkMeta,
        makerMeta: oldState.makerMeta,
        errorMessage: _messageFor(error),
      );
    }
  }

  static String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    return 'Search could not be completed. Please try again.';
  }
}

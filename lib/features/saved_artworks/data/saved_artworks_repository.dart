import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/pagination_meta.dart';
import '../../../core/providers/core_providers.dart';
import '../../discovery/domain/discovery_artwork.dart';
import '../../discovery/domain/discovery_artwork_page.dart';

final savedArtworksRepositoryProvider =
    Provider<SavedArtworksRepositoryContract>((ref) {
      return SavedArtworksRepository(api: ref.watch(apiGatewayProvider));
    });

abstract interface class SavedArtworksRepositoryContract {
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage,
  });

  Future<bool> isSaved(int artworkId);

  Future<void> save(int artworkId);

  Future<void> unsave(int artworkId);
}

class SavedArtworksRepository implements SavedArtworksRepositoryContract {
  const SavedArtworksRepository({required this.api});

  final ApiGateway api;

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
  }) async {
    final response = await api.get(
      ApiPaths.savedArtworks,
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
      },
    );

    final envelope = ApiEnvelope(raw: response);
    final items = envelope.dataList
        .whereType<Map>()
        .map(
          (item) =>
              DiscoveryArtwork.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return DiscoveryArtworkPage(
      items: items,
      meta: PaginationMeta.fromMap(envelope.meta),
    );
  }

  @override
  Future<bool> isSaved(int artworkId) async {
    final response = await api.get(ApiPaths.savedArtwork(artworkId));
    final value = ApiEnvelope(raw: response).dataMap['saved'];

    return value == true || value == 1 || value == '1' || value == 'true';
  }

  @override
  Future<void> save(int artworkId) async {
    await api.post(ApiPaths.savedArtwork(artworkId));
  }

  @override
  Future<void> unsave(int artworkId) async {
    await api.delete(ApiPaths.savedArtwork(artworkId));
  }
}

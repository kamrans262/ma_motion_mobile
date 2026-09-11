import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/pagination_meta.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/discovery_artwork.dart';
import '../domain/discovery_query.dart';
import '../domain/discovery_search_result.dart';

final discoverySearchRepositoryProvider =
    Provider<DiscoverySearchRepositoryContract>((ref) {
      return DiscoverySearchRepository(api: ref.watch(apiGatewayProvider));
    });

abstract interface class DiscoverySearchRepositoryContract {
  Future<DiscoverySearchResultPage> search({
    required DiscoveryQuery query,
    required int page,
    int perPage,
  });
}

class DiscoverySearchRepository implements DiscoverySearchRepositoryContract {
  const DiscoverySearchRepository({required this.api});

  final ApiGateway api;

  @override
  Future<DiscoverySearchResultPage> search({
    required DiscoveryQuery query,
    required int page,
    int perPage = 20,
  }) async {
    final response = await api.get(
      ApiPaths.discoverySearch,
      requiresAuth: false,
      queryParameters: query.toQueryParameters(page: page, perPage: perPage),
    );

    final envelope = ApiEnvelope(raw: response);
    final data = envelope.dataMap;
    final meta = envelope.meta;

    final artworks = listOrEmpty(data['artworks'])
        .whereType<Map>()
        .map(
          (item) => DiscoveryArtwork.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    final makers = listOrEmpty(data['makers'])
        .whereType<Map>()
        .map(
          (item) =>
              DiscoverySearchMaker.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return DiscoverySearchResultPage(
      artworks: artworks,
      makers: makers,
      artworkMeta: PaginationMeta.fromMap(
        mapOrNull(meta['artworks']) ?? const <String, dynamic>{},
      ),
      makerMeta: PaginationMeta.fromMap(
        mapOrNull(meta['makers']) ?? const <String, dynamic>{},
      ),
    );
  }
}

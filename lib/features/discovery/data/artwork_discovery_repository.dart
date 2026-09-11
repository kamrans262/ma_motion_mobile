import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/pagination_meta.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/discovery_artwork.dart';
import '../domain/discovery_artwork_page.dart';

final artworkDiscoveryRepositoryProvider =
    Provider<ArtworkDiscoveryRepositoryContract>((ref) {
      return ArtworkDiscoveryRepository(api: ref.watch(apiGatewayProvider));
    });

abstract interface class ArtworkDiscoveryRepositoryContract {
  Future<DiscoveryArtworkPage> fetchPage({required int page, int perPage});
}

class ArtworkDiscoveryRepository implements ArtworkDiscoveryRepositoryContract {
  const ArtworkDiscoveryRepository({required this.api});

  final ApiGateway api;

  @override
  Future<DiscoveryArtworkPage> fetchPage({
    required int page,
    int perPage = 24,
  }) async {
    final response = await api.get(
      ApiPaths.discoveryArtworks,
      requiresAuth: false,
      queryParameters: <String, dynamic>{'page': page, 'per_page': perPage},
    );

    final envelope = ApiEnvelope(raw: response);
    final items = envelope.dataList
        .whereType<Map>()
        .map(
          (item) => DiscoveryArtwork.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return DiscoveryArtworkPage(
      items: items,
      meta: PaginationMeta.fromMap(envelope.meta),
    );
  }
}

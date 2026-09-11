import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/artwork_detail.dart';

final artworkDetailRepositoryProvider =
    Provider<ArtworkDetailRepositoryContract>((ref) {
      return ArtworkDetailRepository(api: ref.watch(apiGatewayProvider));
    });

abstract interface class ArtworkDetailRepositoryContract {
  Future<ArtworkDetail> fetch(int artworkId);
}

class ArtworkDetailRepository implements ArtworkDetailRepositoryContract {
  const ArtworkDetailRepository({required this.api});

  final ApiGateway api;

  @override
  Future<ArtworkDetail> fetch(int artworkId) async {
    final response = await api.get(
      '${ApiPaths.discoveryArtworks}/$artworkId',
      requiresAuth: false,
    );

    return ArtworkDetail.fromMap(ApiEnvelope(raw: response).dataMap);
  }
}

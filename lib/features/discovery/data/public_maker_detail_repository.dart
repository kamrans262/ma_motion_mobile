import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/public_maker_detail.dart';

final publicMakerDetailRepositoryProvider =
    Provider<PublicMakerDetailRepository>((ref) {
      return PublicMakerDetailRepository(api: ref.watch(apiGatewayProvider));
    });

final publicMakerDetailProvider = FutureProvider.family<PublicMakerDetail, int>(
  (ref, makerId) {
    return ref.watch(publicMakerDetailRepositoryProvider).fetch(makerId);
  },
);

class PublicMakerDetailRepository {
  const PublicMakerDetailRepository({required this.api});

  final ApiGateway api;

  Future<PublicMakerDetail> fetch(int makerId) async {
    final response = await api.get(
      ApiPaths.maker(makerId),
      requiresAuth: false,
    );
    return PublicMakerDetail.fromMap(ApiEnvelope(raw: response).dataMap);
  }
}

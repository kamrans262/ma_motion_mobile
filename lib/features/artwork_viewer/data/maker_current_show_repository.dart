import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/maker_current_show.dart';

final makerCurrentShowRepositoryProvider = Provider<MakerCurrentShowRepository>((ref) {
  return MakerCurrentShowRepository(api: ref.watch(apiGatewayProvider));
});

final makerCurrentShowProvider = FutureProvider.family<MakerCurrentShow?, int>((ref, makerId) {
  return ref.watch(makerCurrentShowRepositoryProvider).fetch(makerId);
});

class MakerCurrentShowRepository {
  const MakerCurrentShowRepository({required this.api});

  final ApiGateway api;

  Future<MakerCurrentShow?> fetch(int makerId) async {
    try {
      final response = await api.get(
      ApiPaths.makerShows(makerId),
      requiresAuth: false,
      queryParameters: const <String, dynamic>{
        'status': 'current',
        'per_page': 1,
        'page': 1,
      },
    );

      final data = ApiEnvelope(raw: response).dataList;
      if (data.isEmpty || data.first is! Map) return null;

      return MakerCurrentShow.fromMap(
        Map<String, dynamic>.from(data.first as Map),
      );
    } catch (_) {
      return null;
    }
  }
}

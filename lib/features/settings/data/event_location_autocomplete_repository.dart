import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';

final eventLocationAutocompleteRepositoryProvider =
    Provider<EventLocationAutocompleteRepositoryContract>((ref) {
  return EventLocationAutocompleteRepository(api: ref.watch(apiGatewayProvider));
});

abstract interface class EventLocationAutocompleteRepositoryContract {
  Future<List<String>> search(String input);
}

class EventLocationAutocompleteRepository
    implements EventLocationAutocompleteRepositoryContract {
  const EventLocationAutocompleteRepository({required this.api});

  final ApiGateway api;

  @override
  Future<List<String>> search(String input) async {
    final trimmed = input.trim();
    if (trimmed.length < 2 || trimmed.length > 120) {
      return const <String>[];
    }

    final response = await api.get(
      ApiPaths.eventLocationSuggestions,
      queryParameters: <String, dynamic>{'input': trimmed},
    );

    return ApiEnvelope(raw: response).dataList
        .whereType<Map>()
        .map((item) => item['description']?.toString().trim() ?? '')
        .where((description) => description.isNotEmpty)
        .toList(growable: false);
  }
}

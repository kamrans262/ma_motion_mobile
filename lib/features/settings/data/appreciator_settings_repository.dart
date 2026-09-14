import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/appreciator_settings_models.dart';

final appreciatorSettingsRepositoryProvider =
    Provider<AppreciatorSettingsRepositoryContract>((ref) {
      return AppreciatorSettingsRepository(api: ref.watch(apiGatewayProvider));
    });

abstract interface class AppreciatorSettingsRepositoryContract {
  Future<AppreciatorSettingsData> load();

  Future<AppreciatorSettingsData> save(AppreciatorSettingsDraft draft);

  Future<int?> resolveLocationId(String query);
}

class AppreciatorSettingsRepository
    implements AppreciatorSettingsRepositoryContract {
  const AppreciatorSettingsRepository({required this.api});

  final ApiGateway api;

  @override
  Future<AppreciatorSettingsData> load() async {
    final response = await api.get(ApiPaths.appreciatorProfile);
    final data = ApiEnvelope(raw: response).dataMap;

    if (data.isEmpty) {
      throw const ApiException(
        message: 'The server did not return your Appreciator settings.',
        code: 'appreciator_settings_missing',
      );
    }

    return AppreciatorSettingsData.fromMap(data);
  }

  @override
  Future<AppreciatorSettingsData> save(AppreciatorSettingsDraft draft) async {
    final response = await api.patch(
      ApiPaths.appreciatorProfile,
      data: <String, dynamic>{
        'name': draft.name.trim(),
        'email': draft.email.trim().toLowerCase(),
        'location_text': draft.locationText.trim(),
        'location_id': draft.locationId,
      },
    );

    final data = ApiEnvelope(raw: response).dataMap;

    if (data.isEmpty) {
      throw const ApiException(
        message: 'The server did not return the saved Appreciator settings.',
        code: 'appreciator_settings_save_missing',
      );
    }

    return AppreciatorSettingsData.fromMap(data);
  }

  @override
  Future<int?> resolveLocationId(String query) async {
    final value = query.trim();

    if (value.isEmpty) {
      return null;
    }

    final response = await api.get(
      ApiPaths.discoveryLocations,
      requiresAuth: false,
      queryParameters: <String, dynamic>{'search': value, 'per_page': 1},
    );
    final locations = ApiEnvelope(raw: response).dataList;

    if (locations.isEmpty || locations.first is! Map) {
      return null;
    }

    final first = Map<String, dynamic>.from(locations.first as Map);
    return _asInt(first['id']);
  }
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

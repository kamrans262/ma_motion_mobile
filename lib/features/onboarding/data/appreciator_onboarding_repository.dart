import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/auth_token_store.dart';
import '../../auth/domain/current_user.dart';
import '../domain/appreciator_registration_draft.dart';

final appreciatorOnboardingRepositoryProvider =
    Provider<AppreciatorOnboardingRepository>(
      (ref) => AppreciatorOnboardingRepository(
        api: ref.watch(apiGatewayProvider),
        tokenStore: ref.watch(authTokenStoreProvider),
      ),
    );

class AppreciatorOnboardingRepository {
  const AppreciatorOnboardingRepository({
    required this.api,
    required this.tokenStore,
  });

  final ApiGateway api;
  final AuthTokenStore tokenStore;

  Future<void> completeAppreciatorOnboarding(
    AppreciatorRegistrationDraft draft,
  ) async {
    final locationId = await resolveLocationId(draft.location);

    final response = await api.post(
      ApiPaths.appreciatorOnboarding,
      requiresAuth: false,
      data: <String, dynamic>{
        'name': draft.name.trim(),
        'location_text': draft.location.trim(),
        'location_id': locationId,
        'email': draft.email.trim(),
        'device_name': 'MA Motion Mobile',
      },
    );

    final data = ApiEnvelope(raw: response).dataMap;
    final token = data['token']?.toString().trim() ?? '';
    final userData = data['user'];

    if (token.isEmpty) {
      throw const ApiException(
        message: 'The server did not return an Appreciator session token.',
        code: 'appreciator_onboarding_token_missing',
      );
    }

    if (userData is! Map) {
      throw const ApiException(
        message: 'The server did not return the Appreciator account.',
        code: 'appreciator_onboarding_user_missing',
      );
    }

    final user = CurrentUser.fromMap(Map<String, dynamic>.from(userData));

    if (!user.isAppreciator) {
      throw const ApiException(
        message: 'The created account is not an Appreciator account.',
        statusCode: 403,
        code: 'appreciator_role_required',
      );
    }

    await tokenStore.write(token);
  }

  Future<int?> resolveLocationId(String query) async {
    final value = query.trim();

    if (value.isEmpty) {
      return null;
    }

    final response = await api.get(
      ApiPaths.discoveryLocations,
      requiresAuth: false,
      queryParameters: <String, dynamic>{
        'search': value,
        'per_page': 1,
      },
    );

    final locations = ApiEnvelope(raw: response).dataList;

    if (locations.isEmpty || locations.first is! Map) {
      return null;
    }

    final first = Map<String, dynamic>.from(locations.first as Map);
    final id = first['id'];

    if (id is int) {
      return id;
    }

    return int.tryParse(id?.toString() ?? '');
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/current_user.dart';

final onboardingPrefillRepositoryProvider =
    Provider<OnboardingPrefillRepository>(
      (ref) => OnboardingPrefillRepository(
        auth: ref.watch(authRepositoryProvider),
        api: ref.watch(apiGatewayProvider),
      ),
    );

/// Loads only the signed-in user's persisted profile data. Never creates an
/// account or switches experiences when prefilling an onboarding screen.
class OnboardingPrefillRepository {
  const OnboardingPrefillRepository({required this.auth, required this.api});

  final AuthRepository auth;
  final ApiGateway api;

  Future<CurrentUser?> account() async => (await auth.restoreSession())?.user;

  Future<Map<String, dynamic>> incompleteMakerProfile() async {
    final response = await api.get(ApiPaths.makerProfile);
    return ApiEnvelope(raw: response).dataMap;
  }
}

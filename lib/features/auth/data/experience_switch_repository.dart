import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import 'auth_repository.dart';
import '../domain/maker_entry_destination.dart';

final experienceSwitchRepositoryProvider =
    Provider<ExperienceSwitchRepositoryContract>((ref) {
      return ExperienceSwitchRepository(
        auth: ref.watch(authRepositoryProvider),
        api: ref.watch(apiGatewayProvider),
      );
    });

abstract interface class ExperienceSwitchRepositoryContract {
  Future<MakerEntryDestination> switchToMaker();
}

class ExperienceSwitchRepository implements ExperienceSwitchRepositoryContract {
  const ExperienceSwitchRepository({required this.auth, required this.api});

  final AuthRepository auth;
  final ApiGateway api;

  @override
  Future<MakerEntryDestination> switchToMaker() async {
    final session = await auth.restoreSession();

    if (session == null) {
      throw const ApiException(
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }

    if (!session.user.isAppreciator) {
      throw const ApiException(
        message: 'Only Appreciator accounts can convert to Maker.',
        statusCode: 403,
        code: 'appreciator_role_required',
      );
    }

    // This is a one-way account conversion, not a second profile. The backend
    // removes the Appreciator profile, activates Maker, and starts fresh Maker
    // onboarding while preserving shared account data such as name/email.
    await api.post(ApiPaths.makerExperienceOnboarding);

    return MakerEntryDestination.profileSetup;
  }
}

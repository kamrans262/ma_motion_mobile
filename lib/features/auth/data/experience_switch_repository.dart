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
  Future<MakerEntryDestination> switchToAppreciator();

  Future<MakerEntryDestination> switchToMaker();
}

class ExperienceSwitchRepository implements ExperienceSwitchRepositoryContract {
  const ExperienceSwitchRepository({required this.auth, required this.api});

  final AuthRepository auth;
  final ApiGateway api;

  @override
  Future<MakerEntryDestination> switchToAppreciator() async {
    final session = await auth.restoreSession();

    if (session == null) {
      throw const ApiException(
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }

    if (!session.user.appreciatorOnboardingCompleted) {
      return MakerEntryDestination.appreciatorProfileSetup;
    }

    if (!session.user.isAppreciator) {
      await api.patch(
        ApiPaths.experience,
        data: const <String, dynamic>{'experience': 'appreciator'},
      );
    }

    return MakerEntryDestination.appreciatorDiscovery;
  }

  @override
  Future<MakerEntryDestination> switchToMaker() async {
    final session = await auth.restoreSession();

    if (session == null) {
      throw const ApiException(
        message: 'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }

    if (session.user.makerOnboardingCompleted) {
      if (!session.user.isMaker) {
        await api.patch(
          ApiPaths.experience,
          data: const <String, dynamic>{'experience': 'maker'},
        );
      }

      return MakerEntryDestination.discovery;
    }

    if (!session.user.isMaker) {
      await api.post(ApiPaths.makerExperienceOnboarding);
    }

    return MakerEntryDestination.profileSetup;
  }
}

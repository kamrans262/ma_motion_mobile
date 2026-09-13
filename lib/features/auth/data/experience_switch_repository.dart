import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      return MakerEntryDestination.appreciatorProfileSetup;
    }

    if (!session.user.appreciatorOnboardingCompleted) {
      return MakerEntryDestination.appreciatorProfileSetup;
    }

    await api.patch(
      ApiPaths.experience,
      data: const <String, dynamic>{'experience': 'appreciator'},
    );

    return MakerEntryDestination.appreciatorDiscovery;
  }

  @override
  Future<MakerEntryDestination> switchToMaker() async {
    final session = await auth.restoreSession();

    if (session == null) {
      return MakerEntryDestination.profileSetup;
    }

    if (session.user.makerOnboardingCompleted) {
      await api.patch(
        ApiPaths.experience,
        data: const <String, dynamic>{'experience': 'maker'},
      );

      return MakerEntryDestination.discovery;
    }

    await api.post(ApiPaths.makerExperienceOnboarding);

    return MakerEntryDestination.profileSetup;
  }
}

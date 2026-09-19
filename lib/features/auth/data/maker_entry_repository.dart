import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/maker_entry_destination.dart';
import 'auth_repository.dart';

final makerEntryRepositoryProvider = Provider<MakerEntryRepositoryContract>(
  (ref) => MakerEntryRepository(
    auth: ref.watch(authRepositoryProvider),
    api: ref.watch(apiGatewayProvider),
  ),
);

abstract interface class MakerEntryRepositoryContract {
  Future<MakerEntryDestination> restoreAppEntry();

  Future<MakerEntryDestination> registerMaker({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });

  Future<MakerEntryDestination> loginMaker({
    required String email,
    required String password,
  });

  Future<String> requestPasswordReset(String email);
}

class MakerEntryRepository implements MakerEntryRepositoryContract {
  const MakerEntryRepository({required this.auth, required this.api});

  final AuthRepository auth;
  final ApiGateway api;

  @override
  Future<MakerEntryDestination> restoreAppEntry() async {
    final session = await auth.restoreSession();

    if (session == null) {
      return MakerEntryDestination.join;
    }

    if (session.user.isAppreciator) {
      return session.user.appreciatorOnboardingCompleted
          ? MakerEntryDestination.appreciatorDiscovery
          : MakerEntryDestination.appreciatorProfileSetup;
    }

    if (!session.user.isMaker) {
      return MakerEntryDestination.join;
    }

    // /me is authoritative for both completion flags and the active role.
    // Keep the legacy Maker profile fallback for previously issued sessions.
    if (session.user.makerOnboardingCompleted) {
      return MakerEntryDestination.discovery;
    }

    return _makerProfileDestination();
  }

  @override
  Future<MakerEntryDestination> registerMaker({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final session = await auth.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      role: 'maker',
    );

    if (!session.user.isMaker) {
      await auth.logout();
      throw const ApiException(
        message: 'This account is not a Maker account.',
        statusCode: 403,
        code: 'maker_role_required',
      );
    }

    // Registration creates a Maker profile record, but the seven supplied
    // Maker profile screens still need to be completed.
    return MakerEntryDestination.profileSetup;
  }

  @override
  Future<MakerEntryDestination> loginMaker({
    required String email,
    required String password,
  }) async {
    final session = await auth.login(email: email, password: password);

    if (!session.user.isMaker) {
      await auth.logout();
      throw const ApiException(
        message: 'Please sign in with a Maker account.',
        statusCode: 403,
        code: 'maker_role_required',
      );
    }

    return _makerProfileDestination();
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    final response = await api.post(
      ApiPaths.forgotPassword,
      requiresAuth: false,
      data: <String, dynamic>{'email': email.trim()},
    );

    return ApiEnvelope(raw: response).message ??
        'If an account exists for that email, password reset instructions have been sent.';
  }

  Future<MakerEntryDestination> _makerProfileDestination() async {
    final response = await api.get(ApiPaths.makerProfile);
    final data = ApiEnvelope(raw: response).dataMap;

    final completed = _asBool(data['onboarding_completed']);

    return completed
        ? MakerEntryDestination.discovery
        : MakerEntryDestination.profileSetup;
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }

    return value == 1 || value == '1' || value == 'true';
  }
}

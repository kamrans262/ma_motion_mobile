import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/auth_token_store.dart';
import '../domain/auth_session.dart';

final emailOtpRepositoryProvider = Provider<EmailOtpRepository>(
  (ref) => EmailOtpRepository(
    api: ref.watch(apiGatewayProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
  ),
);

enum EmailOtpPurpose {
  login('login'),
  register('register'),
  confirm('confirm');

  const EmailOtpPurpose(this.apiValue);

  final String apiValue;
}

class EmailOtpChallenge {
  const EmailOtpChallenge({
    required this.id,
    required this.email,
    required this.purpose,
    required this.requiresAuth,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });

  final String id;
  final String email;
  final EmailOtpPurpose purpose;
  final bool requiresAuth;
  final int expiresInSeconds;
  final int resendAfterSeconds;
}

class EmailOtpVerificationResult {
  const EmailOtpVerificationResult({this.session});

  final AuthSession? session;

  bool get isAuthenticated => session != null;
}

class EmailOtpRepository {
  const EmailOtpRepository({required this.api, required this.tokenStore});

  final ApiGateway api;
  final AuthTokenStore tokenStore;

  Future<EmailOtpChallenge> requestLogin(String email) {
    return _request(
      email: email,
      purpose: EmailOtpPurpose.login,
      requiresAuth: false,
    );
  }

  Future<EmailOtpChallenge> requestOnboarding(String email) async {
    final token = await tokenStore.read();
    final hasSession = token != null && token.trim().isNotEmpty;

    return _request(
      email: email,
      purpose: hasSession
          ? EmailOtpPurpose.confirm
          : EmailOtpPurpose.register,
      requiresAuth: hasSession,
    );
  }

  Future<EmailOtpChallenge> resend(EmailOtpChallenge challenge) {
    return _request(
      email: challenge.email,
      purpose: challenge.purpose,
      requiresAuth: challenge.requiresAuth,
    );
  }

  Future<EmailOtpVerificationResult> verify({
    required EmailOtpChallenge challenge,
    required String code,
  }) async {
    final response = await api.post(
      ApiPaths.verifyEmailOtp,
      requiresAuth: challenge.requiresAuth,
      data: <String, dynamic>{
        'challenge_id': challenge.id,
        'email': challenge.email,
        'code': code.trim(),
      },
    );

    if (challenge.purpose != EmailOtpPurpose.login) {
      return const EmailOtpVerificationResult();
    }

    final session = AuthSession.fromResponse(response);
    await tokenStore.write(session.token);
    return EmailOtpVerificationResult(session: session);
  }

  Future<EmailOtpChallenge> _request({
    required String email,
    required EmailOtpPurpose purpose,
    required bool requiresAuth,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final response = await api.post(
      ApiPaths.requestEmailOtp,
      requiresAuth: requiresAuth,
      data: <String, dynamic>{
        'email': normalizedEmail,
        'purpose': purpose.apiValue,
      },
    );
    final data = ApiEnvelope(raw: response).dataMap;
    final id = data['challenge_id']?.toString().trim() ?? '';

    if (id.isEmpty) {
      throw const ApiException(
        message: 'The server did not return an email verification request.',
        code: 'email_otp_challenge_missing',
      );
    }

    return EmailOtpChallenge(
      id: id,
      email: normalizedEmail,
      purpose: purpose,
      requiresAuth: requiresAuth,
      expiresInSeconds:
          int.tryParse(data['expires_in_seconds']?.toString() ?? '') ?? 600,
      resendAfterSeconds:
          int.tryParse(data['resend_after_seconds']?.toString() ?? '') ?? 60,
    );
  }
}

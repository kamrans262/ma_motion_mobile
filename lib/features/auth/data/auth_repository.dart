import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/storage/auth_token_store.dart';
import '../domain/auth_session.dart';
import '../domain/current_user.dart';

class AuthRepository {
  const AuthRepository({required this.api, required this.tokenStore});

  final ApiGateway api;
  final AuthTokenStore tokenStore;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
    String deviceName = 'MA Motion Mobile',
  }) async {
    final response = await api.post(
      ApiPaths.register,
      requiresAuth: false,
      data: <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
        'device_name': deviceName.trim(),
      },
    );

    final session = AuthSession.fromResponse(response);
    await tokenStore.write(session.token);
    return session;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    String deviceName = 'MA Motion Mobile',
  }) async {
    final response = await api.post(
      ApiPaths.login,
      requiresAuth: false,
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'device_name': deviceName.trim(),
      },
    );

    final session = AuthSession.fromResponse(response);
    await tokenStore.write(session.token);
    return session;
  }

  Future<CurrentUser> me() async {
    final response = await api.get(ApiPaths.me);
    final envelope = ApiEnvelope(raw: response);

    final candidate = envelope.dataMap.isNotEmpty
        ? (envelope.dataMap['user'] ?? envelope.dataMap)
        : response['user'];

    if (candidate is Map<String, dynamic>) {
      return CurrentUser.fromMap(candidate);
    }

    if (candidate is Map) {
      return CurrentUser.fromMap(Map<String, dynamic>.from(candidate));
    }

    throw const ApiException(
      message: 'Authenticated user response is missing user data.',
    );
  }

  Future<AuthSession?> restoreSession() async {
    final token = await tokenStore.read();

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    try {
      final user = await me();

      return AuthSession(token: token.trim(), user: user);
    } on ApiException catch (error) {
      if (error.isUnauthenticated) {
        await tokenStore.clear();
        return null;
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await api.post(ApiPaths.logout);
    } finally {
      await tokenStore.clear();
    }
  }
}

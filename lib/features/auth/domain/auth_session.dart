import '../../../core/network/api_exception.dart';
import 'current_user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final CurrentUser user;

  factory AuthSession.fromResponse(Map<String, dynamic> response) {
    Map<String, dynamic> asMap(Object? value) {
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return const <String, dynamic>{};
    }

    final data = asMap(response['data']);

    final token =
        data['token']?.toString() ??
        data['access_token']?.toString() ??
        response['token']?.toString() ??
        response['access_token']?.toString();

    final userMap = asMap(data['user'] ?? response['user']);

    if (token == null || token.trim().isEmpty || userMap.isEmpty) {
      throw const ApiException(
        message: 'Authentication response is missing token or user data.',
      );
    }

    return AuthSession(token: token.trim(), user: CurrentUser.fromMap(userMap));
  }
}

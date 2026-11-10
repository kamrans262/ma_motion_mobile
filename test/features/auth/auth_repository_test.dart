import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/auth/data/auth_repository.dart';

void main() {
  test('login stores token and returns parsed Maker session', () async {
    final api = _FakeApiGateway(
      response: <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'token': 'token-123',
          'user': <String, dynamic>{
            'id': 9,
            'name': 'Artist Ken',
            'email': 'artist@example.com',
            'role': 'maker',
            'is_active': true,
          },
        },
      },
    );
    final store = _MemoryTokenStore();

    final repository = AuthRepository(api: api, tokenStore: store);

    final session = await repository.login(
      email: 'artist@example.com',
      password: 'Secure123',
    );

    expect(session.token, 'token-123');
    expect(session.user.isMaker, isTrue);
    expect(store.token, 'token-123');
    expect(api.lastPath, '/auth/login');
    expect(api.lastRequiresAuth, isFalse);
  });

  test('restoreSession returns null without a stored token', () async {
    final repository = AuthRepository(
      api: _FakeApiGateway(response: const <String, dynamic>{}),
      tokenStore: _MemoryTokenStore(),
    );

    expect(await repository.restoreSession(), isNull);
  });
}

class _MemoryTokenStore implements AuthTokenStore {
  String? token;

  @override
  Future<void> clear() async {
    token = null;
  }

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async {
    this.token = token;
  }
}

class _FakeApiGateway implements ApiGateway {
  _FakeApiGateway({required this.response});

  final Map<String, dynamic> response;

  String? lastPath;
  bool? lastRequiresAuth;

  Future<Map<String, dynamic>> _record(String path, bool requiresAuth) async {
    lastPath = path;
    lastRequiresAuth = requiresAuth;
    return response;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => _record(path, requiresAuth);

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => _record(path, requiresAuth);

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => _record(path, requiresAuth);

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => _record(path, requiresAuth);

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => _record(path, requiresAuth);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/auth/data/auth_repository.dart';
import 'package:ma_motion_mobile/features/auth/data/maker_entry_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';

void main() {
  test('Maker registration stores token and goes to profile setup', () async {
    final api = _FakeApiGateway();
    final tokenStore = _MemoryTokenStore();
    final auth = AuthRepository(api: api, tokenStore: tokenStore);
    final repository = MakerEntryRepository(auth: auth, api: api);

    final destination = await repository.registerMaker(
      name: 'MA Studio',
      email: 'maker@example.com',
      password: 'MakerPass1',
      passwordConfirmation: 'MakerPass1',
    );

    expect(destination, MakerEntryDestination.profileSetup);
    expect(tokenStore.value, 'register-token');
    expect(api.lastPostedPath, ApiPaths.register);
    expect(api.lastPostedData?['role'], 'maker');
  });

  test('Maker login with completed onboarding goes to discovery', () async {
    final api = _FakeApiGateway(onboardingCompleted: true);
    final tokenStore = _MemoryTokenStore();
    final auth = AuthRepository(api: api, tokenStore: tokenStore);
    final repository = MakerEntryRepository(auth: auth, api: api);

    final destination = await repository.loginMaker(
      email: 'maker@example.com',
      password: 'MakerPass1',
    );

    expect(destination, MakerEntryDestination.discovery);
    expect(tokenStore.value, 'login-token');
    expect(api.makerProfileReads, 1);
  });

  test('session restore routes incomplete Maker to profile setup', () async {
    final api = _FakeApiGateway(onboardingCompleted: false);
    final tokenStore = _MemoryTokenStore('saved-token');
    final auth = AuthRepository(api: api, tokenStore: tokenStore);
    final repository = MakerEntryRepository(auth: auth, api: api);

    final destination = await repository.restoreAppEntry();

    expect(destination, MakerEntryDestination.profileSetup);
    expect(api.meReads, 1);
    expect(api.makerProfileReads, 1);
  });

  test('session restore routes Appreciator to Appreciator discovery', () async {
    final api = _FakeApiGateway(role: 'appreciator');
    final tokenStore = _MemoryTokenStore('saved-appreciator-token');
    final auth = AuthRepository(api: api, tokenStore: tokenStore);
    final repository = MakerEntryRepository(auth: auth, api: api);

    final destination = await repository.restoreAppEntry();

    expect(destination, MakerEntryDestination.appreciatorDiscovery);
    expect(api.meReads, 1);
    expect(api.makerProfileReads, 0);
  });

  test('session restore routes incomplete Appreciator to onboarding', () async {
    final api = _FakeApiGateway(
      role: 'appreciator',
      appreciatorCompleted: false,
    );
    final repository = MakerEntryRepository(
      auth: AuthRepository(
        api: api,
        tokenStore: _MemoryTokenStore('saved-appreciator-token'),
      ),
      api: api,
    );

    expect(
      await repository.restoreAppEntry(),
      MakerEntryDestination.appreciatorProfileSetup,
    );
    expect(api.meReads, 1);
  });

  test('session restore without token routes to join', () async {
    final api = _FakeApiGateway();
    final tokenStore = _MemoryTokenStore();
    final auth = AuthRepository(api: api, tokenStore: tokenStore);
    final repository = MakerEntryRepository(auth: auth, api: api);

    final destination = await repository.restoreAppEntry();

    expect(destination, MakerEntryDestination.join);
    expect(api.meReads, 0);
  });

  test('forgot password uses public Laravel endpoint', () async {
    final api = _FakeApiGateway();
    final tokenStore = _MemoryTokenStore();
    final auth = AuthRepository(api: api, tokenStore: tokenStore);
    final repository = MakerEntryRepository(auth: auth, api: api);

    final message = await repository.requestPasswordReset('maker@example.com');

    expect(api.lastPostedPath, ApiPaths.forgotPassword);
    expect(api.lastPostedRequiresAuth, isFalse);
    expect(message, contains('password reset'));
  });
}

class _MemoryTokenStore implements AuthTokenStore {
  _MemoryTokenStore([this.value]);

  String? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async {
    value = token;
  }
}

class _FakeApiGateway implements ApiGateway {
  _FakeApiGateway({
    this.onboardingCompleted = false,
    this.role = 'maker',
    this.appreciatorCompleted = true,
  });

  final bool onboardingCompleted;
  final String role;
  final bool appreciatorCompleted;

  String? lastPostedPath;
  Map<String, dynamic>? lastPostedData;
  bool? lastPostedRequiresAuth;
  int meReads = 0;
  int makerProfileReads = 0;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    if (path == ApiPaths.me) {
      meReads++;
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 1,
          'name': role == 'appreciator' ? 'Art Lover' : 'MA Studio',
          'email': role == 'appreciator'
              ? 'lover@example.com'
              : 'maker@example.com',
          'role': role,
          'is_active': true,
          'maker_onboarding_completed': onboardingCompleted,
          'appreciator_onboarding_completed': appreciatorCompleted,
        },
      };
    }

    if (path == ApiPaths.makerProfile) {
      makerProfileReads++;
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 1,
          'name': 'MA Studio',
          'onboarding_completed': onboardingCompleted,
        },
      };
    }

    throw StateError('Unexpected GET $path');
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPostedPath = path;
    lastPostedRequiresAuth = requiresAuth;

    if (data is Map) {
      lastPostedData = Map<String, dynamic>.from(data);
    }

    if (path == ApiPaths.register) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'token': 'register-token',
          'user': <String, dynamic>{
            'id': 1,
            'name': 'MA Studio',
            'email': 'maker@example.com',
            'role': 'maker',
            'is_active': true,
          },
        },
      };
    }

    if (path == ApiPaths.login) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'token': 'login-token',
          'user': <String, dynamic>{
            'id': 1,
            'name': 'MA Studio',
            'email': 'maker@example.com',
            'role': 'maker',
            'is_active': true,
          },
        },
      };
    }

    if (path == ApiPaths.forgotPassword) {
      return <String, dynamic>{
        'success': true,
        'message': 'If an account exists for that email, password reset instructions have been sent.',
        'data': null,
      };
    }

    if (path == ApiPaths.logout) {
      return <String, dynamic>{'success': true, 'data': null};
    }

    throw StateError('Unexpected POST $path');
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    throw UnimplementedError();
  }
}

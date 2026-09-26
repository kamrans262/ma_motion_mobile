import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_exception.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/auth/data/auth_repository.dart';
import 'package:ma_motion_mobile/features/auth/data/experience_switch_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';

void main() {
  test('Appreciator to Maker always starts Maker onboarding', () async {
    final api = _ExperienceGateway(role: 'appreciator');
    final tokenStore = _MemoryTokenStore('same-account-token');
    final repository = ExperienceSwitchRepository(
      auth: AuthRepository(api: api, tokenStore: tokenStore),
      api: api,
    );

    final destination = await repository.switchToMaker();

    expect(destination, MakerEntryDestination.profileSetup);
    expect(api.lastPostPath, ApiPaths.makerExperienceOnboarding);
    expect(tokenStore.value, 'same-account-token');
  });

  test('Maker cannot use the Appreciator to Maker conversion flow', () async {
    final api = _ExperienceGateway(role: 'maker');
    final tokenStore = _MemoryTokenStore('same-account-token');
    final repository = ExperienceSwitchRepository(
      auth: AuthRepository(api: api, tokenStore: tokenStore),
      api: api,
    );

    await expectLater(
      repository.switchToMaker(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.code,
              'code',
              'appreciator_role_required',
            ),
      ),
    );

    expect(api.lastPostPath, isNull);
    expect(tokenStore.value, 'same-account-token');
  });
}

class _MemoryTokenStore implements AuthTokenStore {
  _MemoryTokenStore([this.value]);

  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;
}

class _ExperienceGateway implements ApiGateway {
  _ExperienceGateway({required this.role});

  final String role;
  String? lastPostPath;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    if (path != ApiPaths.me) {
      throw StateError('Unexpected GET $path');
    }

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'id': 7,
        'name': 'Account User',
        'email': 'account@example.com',
        'role': role,
        'status': 'active',
        'maker_registered': role == 'maker',
        'maker_onboarding_completed': false,
        'appreciator_registered': role == 'appreciator',
        'appreciator_onboarding_completed': role == 'appreciator',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPostPath = path;
    return <String, dynamic>{'success': true, 'data': <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();
}

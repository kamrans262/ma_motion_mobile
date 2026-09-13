import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/auth/data/auth_repository.dart';
import 'package:ma_motion_mobile/features/auth/data/experience_switch_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';

void main() {
  test('completed Appreciator profile switches directly without logout', () async {
    final api = _ExperienceGateway(
      role: 'maker',
      makerCompleted: true,
      appreciatorCompleted: true,
    );
    final tokenStore = _MemoryTokenStore('same-account-token');
    final repository = ExperienceSwitchRepository(
      auth: AuthRepository(api: api, tokenStore: tokenStore),
      api: api,
    );

    final destination = await repository.switchToAppreciator();

    expect(destination, MakerEntryDestination.appreciatorDiscovery);
    expect(api.lastPatchPath, ApiPaths.experience);
    expect(api.lastPatchData, <String, dynamic>{'experience': 'appreciator'});
    expect(tokenStore.value, 'same-account-token');
  });

  test('missing Appreciator profile routes to Appreciator registration', () async {
    final api = _ExperienceGateway(
      role: 'maker',
      makerCompleted: true,
      appreciatorCompleted: false,
    );
    final tokenStore = _MemoryTokenStore('same-account-token');
    final repository = ExperienceSwitchRepository(
      auth: AuthRepository(api: api, tokenStore: tokenStore),
      api: api,
    );

    final destination = await repository.switchToAppreciator();

    expect(destination, MakerEntryDestination.appreciatorProfileSetup);
    expect(api.lastPatchPath, isNull);
    expect(tokenStore.value, 'same-account-token');
  });

  test('completed Maker profile switches directly to Maker discovery', () async {
    final api = _ExperienceGateway(
      role: 'appreciator',
      makerCompleted: true,
      appreciatorCompleted: true,
    );
    final tokenStore = _MemoryTokenStore('same-account-token');
    final repository = ExperienceSwitchRepository(
      auth: AuthRepository(api: api, tokenStore: tokenStore),
      api: api,
    );

    final destination = await repository.switchToMaker();

    expect(destination, MakerEntryDestination.discovery);
    expect(api.lastPatchPath, ApiPaths.experience);
    expect(api.lastPatchData, <String, dynamic>{'experience': 'maker'});
    expect(api.lastPostPath, isNull);
    expect(tokenStore.value, 'same-account-token');
  });

  test('missing Maker profile starts same-account Maker onboarding', () async {
    final api = _ExperienceGateway(
      role: 'appreciator',
      makerCompleted: false,
      appreciatorCompleted: true,
    );
    final tokenStore = _MemoryTokenStore('same-account-token');
    final repository = ExperienceSwitchRepository(
      auth: AuthRepository(api: api, tokenStore: tokenStore),
      api: api,
    );

    final destination = await repository.switchToMaker();

    expect(destination, MakerEntryDestination.profileSetup);
    expect(api.lastPostPath, ApiPaths.makerExperienceOnboarding);
    expect(api.lastPatchPath, isNull);
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
  _ExperienceGateway({
    required this.role,
    required this.makerCompleted,
    required this.appreciatorCompleted,
  });

  final String role;
  final bool makerCompleted;
  final bool appreciatorCompleted;

  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;
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
        'name': 'Dual User',
        'email': 'dual@example.com',
        'role': role,
        'status': 'active',
        'maker_registered': makerCompleted,
        'maker_onboarding_completed': makerCompleted,
        'appreciator_registered': appreciatorCompleted,
        'appreciator_onboarding_completed': appreciatorCompleted,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPatchPath = path;
    lastPatchData = Map<String, dynamic>.from(data! as Map);

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'role': lastPatchData!['experience']},
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

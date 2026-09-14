import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/settings/data/appreciator_settings_repository.dart';
import 'package:ma_motion_mobile/features/settings/domain/appreciator_settings_models.dart';

void main() {
  test('loads current Appreciator settings from protected profile API', () async {
    final api = _FakeGateway();
    final repository = AppreciatorSettingsRepository(api: api);

    final data = await repository.load();

    expect(api.lastGetPath, ApiPaths.appreciatorProfile);
    expect(data.name, 'Ari Viewer');
    expect(data.locationText, 'New York, NY');
    expect(data.locationId, 8);
    expect(data.email, 'ari@example.com');
  });

  test('resolves changed location and saves normalized account data', () async {
    final api = _FakeGateway();
    final repository = AppreciatorSettingsRepository(api: api);

    final locationId = await repository.resolveLocationId('Brooklyn, NY');
    final saved = await repository.save(
      AppreciatorSettingsDraft(
        name: '  Ari Updated  ',
        locationText: '  Brooklyn, NY  ',
        locationId: locationId,
        email: '  ARI@EXAMPLE.COM  ',
      ),
    );

    expect(locationId, 12);
    expect(api.lastPatchPath, ApiPaths.appreciatorProfile);
    expect(api.lastPatchData?['name'], 'Ari Updated');
    expect(api.lastPatchData?['location_text'], 'Brooklyn, NY');
    expect(api.lastPatchData?['location_id'], 12);
    expect(api.lastPatchData?['email'], 'ari@example.com');
    expect(saved.locationText, 'Brooklyn, NY');
  });
}

class _FakeGateway implements ApiGateway {
  String? lastGetPath;
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastGetPath = path;

    if (path == ApiPaths.appreciatorProfile) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'name': 'Ari Viewer',
          'email': 'ari@example.com',
          'location_text': 'New York, NY',
          'location_id': 8,
          'onboarding_completed': true,
        },
      };
    }

    if (path == ApiPaths.discoveryLocations) {
      return <String, dynamic>{
        'success': true,
        'data': <dynamic>[
          <String, dynamic>{'id': 12, 'label': 'Brooklyn, NY'},
        ],
      };
    }

    throw StateError('Unexpected GET $path');
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
      'data': <String, dynamic>{
        'name': lastPatchData!['name'],
        'email': lastPatchData!['email'],
        'location_text': lastPatchData!['location_text'],
        'location_id': lastPatchData!['location_id'],
        'onboarding_completed': true,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
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

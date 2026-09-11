import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/auth/data/auth_repository.dart';
import 'package:ma_motion_mobile/features/settings/data/maker_info_settings_repository.dart';
import 'package:ma_motion_mobile/features/settings/domain/maker_info_settings_models.dart';

void main() {
  test('loads private profile, statistics and live taxonomy', () async {
    final api = _FakeApiGateway();
    final auth = AuthRepository(
      api: api,
      tokenStore: _MemoryTokenStore(),
    );
    final repository = MakerInfoSettingsRepository(
      api: api,
      auth: auth,
    );

    final data = await repository.load();

    expect(data.name, 'Artist Ken');
    expect(data.savedCount, 37);
    expect(data.availableTypes.single.name, 'Painting');
    expect(data.availableStyles.single.name, 'Contemporary');
    expect(data.selectedTypeIds, <int>{1});
    expect(data.selectedStyleIds, <int>{2});
    expect(data.managedLocationId, 3);
    expect(data.showWebsite, isTrue);
    expect(data.showEmail, isFalse);
    expect(data.showShows, isTrue);
    expect(data.carousel.single.slot, 1);
  });

  test('saves Figma Maker Info settings to protected profile endpoint', () async {
    final api = _FakeApiGateway();
    final auth = AuthRepository(
      api: api,
      tokenStore: _MemoryTokenStore(),
    );
    final repository = MakerInfoSettingsRepository(
      api: api,
      auth: auth,
    );

    await repository.saveProfile(
      const MakerInfoSettingsDraft(
        name: 'Artist Ken',
        bio: 'Statement',
        locationText: 'Chicago, IL',
        website: 'artist.example',
        email: 'contact@artist.example',
        locationId: 3,
        showWebsite: true,
        showEmail: true,
        showShows: false,
        typeIds: <int>{1},
        styleIds: <int>{2},
      ),
    );

    expect(api.lastPatchPath, ApiPaths.makerProfile);
    expect(api.lastPatchData?['location_id'], 3);
    expect(api.lastPatchData?['show_email_on_info_page'], isTrue);
    expect(api.lastPatchData?['show_shows_on_info_page'], isFalse);
    expect(api.lastPatchData?['type_ids'], <int>[1]);
    expect(api.lastPatchData?['style_ids'], <int>[2]);
  });

  test('uploads carousel slot using multipart data', () async {
    final api = _FakeApiGateway();
    final auth = AuthRepository(
      api: api,
      tokenStore: _MemoryTokenStore(),
    );
    final repository = MakerInfoSettingsRepository(
      api: api,
      auth: auth,
    );

    final item = await repository.saveCarouselSlot(
      slot: 2,
      caption: 'Detail view',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: 'detail.jpg',
    );

    expect(api.lastPostPath, '${ApiPaths.makerProfile}/carousel/2');
    expect(api.lastPostData, isA<FormData>());
    final formData = api.lastPostData! as FormData;
    expect(formData.fields.single.value, 'Detail view');
    expect(formData.files.single.value.filename, 'detail.jpg');
    expect(item.slot, 2);
    expect(item.caption, 'Detail view');

    await repository.deleteCarouselSlot(2);
    expect(api.lastDeletePath, '${ApiPaths.makerProfile}/carousel/2');
  });
}

class _MemoryTokenStore implements AuthTokenStore {
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
  String? lastPatchPath;
  Map<String, dynamic>? lastPatchData;
  String? lastPostPath;
  Object? lastPostData;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    if (path == ApiPaths.makerProfile) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 1,
          'name': 'Artist Ken',
          'bio': 'Statement',
          'location_text': 'Chicago, IL',
          'website_url': 'https://artist.example',
          'contact_email': 'contact@artist.example',
          'profile_image_url': null,
          'managed_location': <String, dynamic>{'id': 3},
          'show_website_on_info_page': true,
          'show_email_on_info_page': false,
          'show_shows_on_info_page': true,
          'types': <dynamic>[
            <String, dynamic>{
              'id': 1,
              'name': 'Painting',
              'slug': 'painting',
            },
          ],
          'styles': <dynamic>[
            <String, dynamic>{
              'id': 2,
              'name': 'Contemporary',
              'slug': 'contemporary',
            },
          ],
          'carousel_content': <dynamic>[
            <String, dynamic>{
              'id': 10,
              'slot': 1,
              'kind': 'image',
              'url': '',
              'caption': 'Salon photo',
            },
          ],
        },
      };
    }

    if (path == ApiPaths.makerStatistics) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'profile_saved_count': 37,
        },
      };
    }

    if (path == ApiPaths.discoveryFilters) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'types': <dynamic>[
            <String, dynamic>{
              'id': 1,
              'name': 'Painting',
              'slug': 'painting',
            },
          ],
          'styles': <dynamic>[
            <String, dynamic>{
              'id': 2,
              'name': 'Contemporary',
              'slug': 'contemporary',
            },
          ],
        },
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

    if (data is Map) {
      lastPatchData = Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{},
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
    lastPostData = data;

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'id': 20,
        'slot': 2,
        'kind': 'image',
        'url': '',
        'caption': 'Detail view',
      },
    };
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
  }) async {
    lastDeletePath = path;

    return <String, dynamic>{
      'success': true,
      'data': null,
    };
  }
}

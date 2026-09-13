import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/onboarding/data/maker_onboarding_repository.dart';
import 'package:ma_motion_mobile/features/onboarding/domain/maker_registration_draft.dart';

void main() {
  test(
    'completeMakerProfile maps Figma labels to backend IDs and uploads image',
    () async {
      final api = _FakeApiGateway();
      final tokenStore = _MemoryTokenStore();
      final repository = MakerOnboardingRepository(
        api: api,
        tokenStore: tokenStore,
      );

      await repository.completeMakerProfile(
        MakerRegistrationDraft(
          name: 'Artist Ken',
          location: 'Chicago 60601',
          aboutWork: 'Contemporary work.',
          types: const <String>{'Painting', 'Graphic Designer'},
          styles: const <String>{'Contemporary'},
          website: 'www.artist.com',
          email: 'contact@artist.com',
          imageBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          imageName: 'salon image.jpg',
        ),
      );

      expect(api.calls, <String>[
        'POST ${ApiPaths.makerOnboarding}',
        'GET ${ApiPaths.discoveryFilters}',
        'GET ${ApiPaths.discoveryLocations}',
        'PATCH ${ApiPaths.makerProfile}',
        'POST ${ApiPaths.profileImage}',
        'PATCH ${ApiPaths.makerProfile}',
      ]);

      final firstPatch = api.patchBodies.first;
      expect(firstPatch['type_ids'], <int>[10, 20]);
      expect(firstPatch['style_ids'], <int>[30]);
      expect(firstPatch['location_id'], 99);
      expect(firstPatch['website_url'], 'https://www.artist.com');
      expect(firstPatch['contact_email'], 'contact@artist.com');

      expect(api.lastPostData, isA<FormData>());
      expect(api.patchBodies.last, <String, dynamic>{
        'complete_onboarding': true,
      });
    },
  );

  test('missing backend taxonomy fails before profile mutation', () async {
    final api = _FakeApiGateway(includeGraphicDesign: false);
    final tokenStore = _MemoryTokenStore();
    final repository = MakerOnboardingRepository(
      api: api,
      tokenStore: tokenStore,
    );

    await expectLater(
      repository.completeMakerProfile(
        MakerRegistrationDraft(
          name: 'Artist Ken',
          location: 'Chicago',
          aboutWork: 'Work',
          types: const <String>{'Graphic Designer'},
          styles: const <String>{'Contemporary'},
          email: 'contact@artist.com',
          imageBytes: Uint8List.fromList(<int>[1]),
          imageName: 'profile.jpg',
        ),
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Graphic Designer'),
        ),
      ),
    );

    expect(api.patchBodies, isEmpty);
  });

  test(
    'authenticated Appreciator starts Maker onboarding on same token',
    () async {
      final api = _FakeApiGateway();
      final tokenStore = _MemoryTokenStore()..value = 'existing-token';
      final repository = MakerOnboardingRepository(
        api: api,
        tokenStore: tokenStore,
      );

      await repository.completeMakerProfile(
        MakerRegistrationDraft(
          name: 'Dual User',
          location: 'Chicago 60601',
          aboutWork: 'Contemporary work.',
          types: const <String>{'Painting'},
          styles: const <String>{'Contemporary'},
          website: 'www.artist.com',
          email: 'dual@example.com',
          imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
          imageName: 'salon.jpg',
        ),
      );

      expect(api.calls.first, 'POST ${ApiPaths.makerExperienceOnboarding}');
      expect(api.calls, isNot(contains('POST ${ApiPaths.makerOnboarding}')));
      expect(tokenStore.value, 'existing-token');
    },
  );
}

class _FakeApiGateway implements ApiGateway {
  _FakeApiGateway({this.includeGraphicDesign = true});

  final bool includeGraphicDesign;
  final List<String> calls = <String>[];
  final List<Map<String, dynamic>> patchBodies = <Map<String, dynamic>>[];
  Object? lastPostData;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    calls.add('GET $path');

    if (path == ApiPaths.discoveryFilters) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'types': <Map<String, dynamic>>[
            <String, dynamic>{'id': 10, 'name': 'Painting', 'slug': 'painting'},
            if (includeGraphicDesign)
              <String, dynamic>{
                'id': 20,
                'name': 'Graphic Design',
                'slug': 'graphic-design',
              },
          ],
          'styles': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 30,
              'name': 'Contemporary',
              'slug': 'contemporary',
            },
          ],
        },
      };
    }

    if (path == ApiPaths.discoveryLocations) {
      return <String, dynamic>{
        'success': true,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 99, 'label': 'Chicago, IL, 60601, US'},
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
    calls.add('PATCH $path');
    patchBodies.add(Map<String, dynamic>.from(data! as Map));
    return <String, dynamic>{'success': true, 'data': <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    calls.add('POST $path');
    lastPostData = data;

    if (path == ApiPaths.makerOnboarding) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'token': 'maker-onboarding-token'},
      };
    }

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

class _MemoryTokenStore implements AuthTokenStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/providers/core_providers.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/onboarding/application/maker_registration_controller.dart';
import 'package:ma_motion_mobile/features/onboarding/data/maker_onboarding_repository.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/maker_registration_flow_screen.dart';

void main() {
  testWidgets('final Maker step submits backend profile then completes flow', (
    tester,
  ) async {
    final api = _SubmissionGateway();
    final tokenStore = _MemoryTokenStore('maker-test-token');
    final repository = MakerOnboardingRepository(
      api: api,
      tokenStore: tokenStore,
    );
    final container = ProviderContainer(
      overrides: [
        makerOnboardingRepositoryProvider.overrideWithValue(repository),
        authTokenStoreProvider.overrideWithValue(tokenStore),
      ],
    );
    addTearDown(container.dispose);

    final draft = container.read(makerRegistrationProvider.notifier);
    draft.setName('MA Studio');
    draft.setLocation('Chicago 60601');
    draft.setAboutWork('About the work');
    draft.toggleType('Painting');
    draft.toggleStyle('Contemporary');
    draft.setWebsite('www.artist.com');
    draft.setEmail('artist@example.com');
    draft.setImage(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
        'YAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      ),
      name: 'salon.png',
    );

    var completed = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MakerRegistrationFlowScreen(
            initialStep: 6,
            onExit: () {},
            onCompleted: () => completed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pump();
    expect(find.text('Saving...'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(api.profilePatchCount, 2);
    expect(api.profileImageUploadCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'signed-out Maker completes onboarding directly into discovery without auth UI',
    (tester) async {
      final api = _SubmissionGateway();
      final tokenStore = _MemoryTokenStore();
      final repository = MakerOnboardingRepository(
        api: api,
        tokenStore: tokenStore,
      );
      final container = ProviderContainer(
        overrides: [
          makerOnboardingRepositoryProvider.overrideWithValue(repository),
          authTokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      final draft = container.read(makerRegistrationProvider.notifier);
      draft.setName('MA Studio');
      draft.setLocation('Chicago 60601');
      draft.setAboutWork('About the work');
      draft.toggleType('Painting');
      draft.toggleStyle('Contemporary');
      draft.setWebsite('www.artist.com');
      draft.setEmail('artist@example.com');
      draft.setImage(
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
          'YAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
        ),
        name: 'salon.png',
      );

      var completed = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MakerRegistrationFlowScreen(
              initialStep: 6,
              onExit: () {},
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('maker_next_button')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(api.makerOnboardingCount, 1);
      expect(api.profilePatchCount, 2);
      expect(api.profileImageUploadCount, 1);
      expect(tokenStore.value, 'maker-onboarding-token');
      expect(find.textContaining('Sign in'), findsNothing);
      expect(find.textContaining('Create account'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
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

class _SubmissionGateway implements ApiGateway {
  int makerOnboardingCount = 0;
  int profilePatchCount = 0;
  int profileImageUploadCount = 0;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));

    if (path == ApiPaths.discoveryFilters) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'types': <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'name': 'Painting', 'slug': 'painting'},
          ],
          'styles': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 2,
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
          <String, dynamic>{'id': 3, 'label': 'Chicago'},
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
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (path == ApiPaths.makerProfile) {
      profilePatchCount++;
    }
    return <String, dynamic>{'success': true, 'data': <String, dynamic>{}};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (path == ApiPaths.makerOnboarding) {
      makerOnboardingCount++;
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'token': 'maker-onboarding-token'},
      };
    }

    if (path == ApiPaths.profileImage) {
      profileImageUploadCount++;
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

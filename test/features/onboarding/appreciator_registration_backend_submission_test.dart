import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_exception.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/providers/core_providers.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/onboarding/application/appreciator_registration_controller.dart';
import 'package:ma_motion_mobile/features/onboarding/data/appreciator_onboarding_repository.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/appreciator_registration_flow_screen.dart';

void main() {
  testWidgets(
    'final Appreciator step creates backend session and completes flow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = _AppreciatorGateway();
      final tokenStore = _MemoryTokenStore();
      final repository = AppreciatorOnboardingRepository(
        api: api,
        tokenStore: tokenStore,
      );
      final container = ProviderContainer(
        overrides: [
          appreciatorOnboardingRepositoryProvider.overrideWithValue(repository),
          apiGatewayProvider.overrideWithValue(api),
          authTokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      final draft = container.read(appreciatorRegistrationProvider.notifier);
      draft.setName('Art Lover');
      draft.setLocation('Chicago 60601');
      draft.setEmail('lover@example.com');

      var completed = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppreciatorRegistrationFlowScreen(
              initialStep: 2,
              onExit: () {},
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('maker_next_button')));
      await tester.pump();

      expect(find.byKey(const Key('email_otp_screen')), findsOneWidget);
      // A complete pasted OTP distributes across all six inputs and
      // automatically verifies without tapping the Verify OTP button.
      await tester.enterText(
        find.byKey(const Key('email_otp_code_field')),
        '123456',
      );
      await tester.pump();
      expect(find.byKey(const Key('email_otp_six_digit_row')), findsOneWidget);
      expect(find.byKey(const Key('email_otp_resend_button')), findsOneWidget);
      expect(find.byKey(const Key('email_otp_success_continue')), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 850));
      expect(find.text('Email Verified.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));

      expect(completed, isTrue);
      expect(api.lastPostedPath, ApiPaths.appreciatorOnboarding);
      expect(api.lastPostRequiresAuth, isFalse);
      expect(api.lastPostedData?['name'], 'Art Lover');
      expect(api.lastPostedData?['location_text'], 'Chicago 60601');
      expect(api.lastPostedData?['location_id'], 7);
      expect(api.lastPostedData?['email'], 'lover@example.com');
      expect(tokenStore.value, 'appreciator-token');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'authenticated Maker completes Appreciator onboarding on same token',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = _AppreciatorGateway();
      final tokenStore = _MemoryTokenStore()..value = 'existing-token';
      final repository = AppreciatorOnboardingRepository(
        api: api,
        tokenStore: tokenStore,
      );
      final container = ProviderContainer(
        overrides: [
          appreciatorOnboardingRepositoryProvider.overrideWithValue(repository),
          apiGatewayProvider.overrideWithValue(api),
          authTokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      final draft = container.read(appreciatorRegistrationProvider.notifier);
      draft.setName('Existing Maker');
      draft.setLocation('Chicago 60601');
      draft.setEmail('maker@example.com');

      var completed = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppreciatorRegistrationFlowScreen(
              initialStep: 2,
              onExit: () {},
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('maker_next_button')));
      await tester.pump();

      expect(find.byKey(const Key('email_otp_screen')), findsOneWidget);
      // A complete pasted OTP distributes across all six inputs and
      // automatically verifies without tapping the Verify OTP button.
      await tester.enterText(
        find.byKey(const Key('email_otp_code_field')),
        '123456',
      );
      await tester.pump();
      expect(find.byKey(const Key('email_otp_six_digit_row')), findsOneWidget);
      expect(find.byKey(const Key('email_otp_resend_button')), findsOneWidget);
      expect(find.byKey(const Key('email_otp_success_continue')), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 850));
      expect(find.text('Email Verified.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));

      expect(completed, isTrue);
      expect(api.lastPostedPath, ApiPaths.appreciatorExperienceOnboarding);
      expect(api.lastPostRequiresAuth, isTrue);
      expect(tokenStore.value, 'existing-token');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'incorrect OTP shows an animated failure result and stays on OTP screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = _AppreciatorGateway()..rejectOtp = true;
      final tokenStore = _MemoryTokenStore();
      final container = ProviderContainer(
        overrides: [
          appreciatorOnboardingRepositoryProvider.overrideWithValue(
            AppreciatorOnboardingRepository(
              api: api,
              tokenStore: tokenStore,
            ),
          ),
          apiGatewayProvider.overrideWithValue(api),
          authTokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      final draft = container.read(appreciatorRegistrationProvider.notifier);
      draft.setName('Art Lover');
      draft.setLocation('Chicago 60601');
      draft.setEmail('lover@example.com');

      var completed = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AppreciatorRegistrationFlowScreen(
              initialStep: 2,
              onExit: () {},
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('maker_next_button')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('email_otp_code_field')),
        '123456',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 850));
      expect(find.text('Verification Failed.'), findsOneWidget);
      expect(
        find.byKey(const Key('email_otp_failure_reason')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('email_otp_success_continue')), findsNothing);

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      expect(find.byKey(const Key('email_otp_screen')), findsOneWidget);
      expect(find.byKey(const Key('email_otp_result_dialog')), findsNothing);
      expect(completed, isFalse);
      expect(tokenStore.value, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
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

class _AppreciatorGateway implements ApiGateway {
  bool rejectOtp = false;
  String? lastPostedPath;
  Map<String, dynamic>? lastPostedData;
  bool? lastPostRequiresAuth;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    if (path == ApiPaths.discoveryLocations) {
      return <String, dynamic>{
        'success': true,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 7, 'label': 'Chicago 60601'},
        ],
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
    lastPostRequiresAuth = requiresAuth;

    if (data is Map) {
      lastPostedData = Map<String, dynamic>.from(data);
    }

    if (path == ApiPaths.requestEmailOtp) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'challenge_id': '11111111-1111-4111-8111-111111111111',
          'expires_in_seconds': 600,
          'resend_after_seconds': 60,
        },
      };
    }

    if (path == ApiPaths.verifyEmailOtp) {
      if (rejectOtp) {
        throw const ApiException(
          message: 'The code is incorrect or expired.',
          fieldErrors: <String, List<String>>{
            'code': <String>['The code is incorrect or expired.'],
          },
        );
      }
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'verified': true},
        'message': 'Email verified successfully.',
      };
    }

    if (path == ApiPaths.appreciatorOnboarding) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'token': 'appreciator-token',
          'user': <String, dynamic>{
            'id': 9,
            'name': 'Art Lover',
            'email': 'lover@example.com',
            'role': 'appreciator',
            'is_active': true,
          },
        },
      };
    }

    if (path == ApiPaths.appreciatorExperienceOnboarding) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 9,
          'name': 'Existing Maker',
          'email': 'maker@example.com',
          'role': 'appreciator',
          'is_active': true,
          'maker_registered': true,
          'maker_onboarding_completed': true,
          'appreciator_registered': true,
          'appreciator_onboarding_completed': true,
        },
      };
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

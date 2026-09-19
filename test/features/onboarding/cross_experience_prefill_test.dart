import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/providers/core_providers.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/onboarding/application/maker_registration_controller.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/appreciator_registration_flow_screen.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/maker_registration_flow_screen.dart';

void main() {
  testWidgets('Maker onboarding prefills account fields and persisted Maker work', (tester) async {
    final gateway = _PrefillGateway(makerIsActive: true);
    final container = ProviderContainer(overrides: [
      apiGatewayProvider.overrideWithValue(gateway),
      authTokenStoreProvider.overrideWithValue(_TokenStore()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: MakerRegistrationFlowScreen(
        prefillFromAccount: true,
        onExit: () {},
      )),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byKey(const Key('maker_name_field'))).controller?.text, 'Existing User');
    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('maker_location_field'))).controller?.text, 'Chicago 60601');

    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('maker_about_field'))).controller?.text, 'Previously saved statement');
    expect(container.read(makerRegistrationProvider).email, 'same@example.com');
    expect(container.read(makerRegistrationProvider).types, contains('Painting'));
    expect(container.read(makerRegistrationProvider).styles, contains('Contemporary'));
    expect(container.read(makerRegistrationProvider).existingImageUrl, 'https://example.test/salon.jpg');
    expect(gateway.makerProfileReads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appreciator onboarding prefills shared data from existing Maker', (tester) async {
    final gateway = _PrefillGateway(makerIsActive: true);
    final container = ProviderContainer(overrides: [
      apiGatewayProvider.overrideWithValue(gateway),
      authTokenStoreProvider.overrideWithValue(_TokenStore()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: AppreciatorRegistrationFlowScreen(
        prefillFromAccount: true,
        onExit: () {},
      )),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(find.byKey(const Key('appreciator_name_field'))).controller?.text, 'Existing User');
    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('appreciator_location_field'))).controller?.text, 'Brooklyn 11201');

    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('appreciator_email_field'))).controller?.text, 'same@example.com');
    expect(gateway.makerProfileReads, 0);
    expect(tester.takeException(), isNull);
  });
}

class _TokenStore implements AuthTokenStore {
  @override
  Future<String?> read() async => 'existing-token';

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> clear() async {}
}

class _PrefillGateway implements ApiGateway {
  _PrefillGateway({required this.makerIsActive});

  final bool makerIsActive;
  int makerProfileReads = 0;

  @override
  Future<Map<String, dynamic>> get(String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    if (path == ApiPaths.me) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 1,
          'name': 'Existing User',
          'email': 'same@example.com',
          'role': 'maker',
          'maker_registered': true,
          'maker_onboarding_completed': false,
          'appreciator_registered': true,
          'appreciator_onboarding_completed': true,
          'maker_profile': <String, dynamic>{
            'location_text': makerIsActive ? 'Brooklyn 11201' : null,
          },
          'appreciator_profile': <String, dynamic>{
            'location_text': 'Chicago 60601',
          },
        },
      };
    }
    if (path == ApiPaths.makerProfile) {
      makerProfileReads++;
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'location_text': null,
          'bio': 'Previously saved statement',
          'website_url': 'https://studio.example',
          'profile_image_url': 'https://example.test/salon.jpg',
          'types': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'Painting'},
          ],
          'styles': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'Contemporary'},
          ],
        },
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<Map<String, dynamic>> post(String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> patch(String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> put(String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> delete(String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();
}

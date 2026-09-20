import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_exception.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/core/providers/core_providers.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/features/auth/data/auth_repository.dart';
import 'package:ma_motion_mobile/features/settings/presentation/widgets/ma_settings_dialogs.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('Video longer than five seconds opens styled warning and closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showMaVideoTooLongDialog(context),
              child: const Text('Choose video'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose video'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ma_video_duration_dialog')), findsOneWidget);
    expect(find.text('Video must be 5 seconds or less.'), findsOneWidget);
    expect(find.byKey(const Key('ma_video_duration_close')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ma_video_duration_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ma_video_duration_dialog')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Passwordless confirmation cancels safely and deletes only on Confirm', (
    tester,
  ) async {
    final api = _AccountApi(hasPassword: false);
    final tokens = _Tokens();
    final auth = AuthRepository(api: api, tokenStore: tokens);
    var confirmed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiGatewayProvider.overrideWithValue(api),
          authTokenStoreProvider.overrideWithValue(tokens),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  confirmed = await showMaDeleteAccountDialog(context);
                },
                child: const Text('Delete Your Account'),
              ),
            ),
          ),
        ),
      ),
    );

    Future<void> open() async {
      await tester.tap(find.text('Delete Your Account'));
      await tester.pumpAndSettle();
    }

    await open();
    expect(
      find.text('Please confirm to delete your account'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ma_delete_account_password')), findsNothing);
    await tester.tap(find.byKey(const Key('ma_delete_account_close')));
    await tester.pumpAndSettle();
    expect(api.deletions, 0);
    expect(tokens.clears, 0);
    expect(confirmed, isFalse);

    await open();
    await tester.tap(find.byKey(const Key('ma_delete_account_confirm')));
    await tester.pumpAndSettle();
    expect(api.deletions, 1);
    expect(api.lastDeleteData?['confirmation'], 'DELETE');
    expect(api.lastDeleteData?.containsKey('current_password'), isFalse);
    expect(tokens.clears, 1);
    expect(confirmed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password-based account still requires password and does not close on API failure', (
    tester,
  ) async {
    final api = _AccountApi(hasPassword: true);
    final tokens = _Tokens();
    final auth = AuthRepository(api: api, tokenStore: tokens);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiGatewayProvider.overrideWithValue(api),
          authTokenStoreProvider.overrideWithValue(tokens),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showMaDeleteAccountDialog(context),
                child: const Text('Delete Your Account'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete Your Account'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ma_delete_account_password')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ma_delete_account_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ma_delete_account_error')), findsOneWidget);
    expect(tokens.clears, 0);
    expect(find.byKey(const Key('ma_delete_account_dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('ma_delete_account_password')),
      'correct-password',
    );
    await tester.tap(find.byKey(const Key('ma_delete_account_confirm')));
    await tester.pumpAndSettle();
    expect(tokens.clears, 1);
    expect(tester.takeException(), isNull);
  });
}

class _Tokens implements AuthTokenStore {
  int clears = 0;

  @override
  Future<String?> read() async => 'authenticated';

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {
    clears++;
  }
}

class _AccountApi implements ApiGateway {
  _AccountApi({required this.hasPassword});

  final bool hasPassword;
  int deletions = 0;
  Map<String, dynamic>? lastDeleteData;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    if (path == ApiPaths.me) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'id': 5,
          'name': 'Member',
          'email': 'member@example.com',
          'role': 'maker',
          'has_password': hasPassword,
        },
      };
    }

    throw StateError('Unexpected GET: $path');
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    expect(path, ApiPaths.account);
    lastDeleteData = Map<String, dynamic>.from(data! as Map);
    if (hasPassword && lastDeleteData?['current_password'] != 'correct-password') {
      throw const ApiException(
        message: 'The current password is incorrect.',
        statusCode: 422,
        fieldErrors: <String, List<String>>{
          'current_password': <String>['The current password is incorrect.'],
        },
      );
    }

    deletions++;
    return <String, dynamic>{'success': true};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> post(
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
}

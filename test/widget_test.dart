import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/providers/core_providers.dart';
import 'package:ma_motion_mobile/core/storage/auth_token_store.dart';
import 'package:ma_motion_mobile/main.dart';

void main() {
  testWidgets('app first Flutter frame is the custom MA splash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authTokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
        ],
        child: const MaMotionApp(splashAutoPlay: false),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_logo')), findsOneWidget);
    expect(find.byKey(const Key('role_selection_screen')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'completed splash restores session then routes signed-out user to role selection',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
          ],
          child: const MaMotionApp(splashDuration: Duration(milliseconds: 200)),
        ),
      );

      expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 201));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('role_selection_screen')), findsOneWidget);
      expect(find.byKey(const Key('select_maker_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Maker selection opens the supplied name onboarding screen first',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authTokenStoreProvider.overrideWithValue(_MemoryTokenStore()),
          ],
          child: const MaMotionApp(splashDuration: Duration(milliseconds: 1)),
        ),
      );

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('select_maker_button')));
      await tester.pumpAndSettle();

      expect(find.text("What's your name or studio name?"), findsOneWidget);
      expect(find.byKey(const Key('maker_name_field')), findsOneWidget);
      expect(find.byKey(const Key('maker_auth_screen')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
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

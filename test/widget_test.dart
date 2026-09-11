import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/main.dart';

void main() {
  testWidgets('app first Flutter frame is the custom MA splash', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaMotionApp(splashAutoPlay: false)),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_logo')), findsOneWidget);
    expect(find.byKey(const Key('role_selection_screen')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('completed splash routes to Maker/Appreciator selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaMotionApp(splashDuration: Duration(milliseconds: 200)),
      ),
    );

    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 201));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('role_selection_screen')), findsOneWidget);
    expect(find.byKey(const Key('select_maker_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

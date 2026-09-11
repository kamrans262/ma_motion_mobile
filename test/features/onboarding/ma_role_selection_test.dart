import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/ma_role_selection_screen.dart';

void main() {
  testWidgets('Maker selection fires maker callback', (tester) async {
    var makerSelected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MaRoleSelectionScreen(
          onMaker: () => makerSelected = true,
          onAppreciator: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('role_selection_screen')), findsOneWidget);
    expect(find.byKey(const Key('select_maker_button')), findsOneWidget);
    expect(find.byKey(const Key('select_appreciator_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('select_maker_button')));
    await tester.pump();

    expect(makerSelected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role selection does not overflow at 320px width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MaRoleSelectionScreen(onMaker: () {}, onAppreciator: () {}),
      ),
    );

    expect(find.byKey(const Key('role_selection_screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

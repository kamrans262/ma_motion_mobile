import 'package:flutter/material.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';
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
    final heading = tester.widget<Text>(
      find.text('Would you like to\njoin as a Maker or\nAppreciator?'),
    );
    expect(heading.style?.fontFamily, AppTextStyles.fontFamily);
    expect(heading.style?.fontSize, 32);
    expect(heading.style?.fontWeight, FontWeight.w500);
    expect(heading.style?.letterSpacing, -0.3);
    expect(find.byKey(const Key('select_maker_button')), findsOneWidget);
    expect(find.byKey(const Key('select_appreciator_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('select_maker_button')));
    await tester.pump();

    expect(makerSelected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('role choices match the Settings and Filter title typography '
      'and have equal opaque nonselected boxes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MaRoleSelectionScreen(onMaker: () {}, onAppreciator: () {}),
      ),
    );

    final maker = tester.widget<OutlinedButton>(
      find.byKey(const Key('select_maker_button')),
    );
    final appreciator = tester.widget<OutlinedButton>(
      find.byKey(const Key('select_appreciator_button')),
    );

    expect(
      maker.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.splashBackground,
    );
    expect(
      appreciator.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.splashBackground,
    );
    expect(
      maker.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.primary,
    );
    expect(
      appreciator.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.primary,
    );
    expect(
      tester.getSize(find.byKey(const Key('select_maker_button'))),
      tester.getSize(find.byKey(const Key('select_appreciator_button'))),
    );
    expect(
      tester.getSize(find.byKey(const Key('select_maker_button'))).height,
      76,
    );
    expect(
      tester.getSize(find.byKey(const Key('select_maker_button'))).width,
      lessThan(170),
    );

    for (final label in <String>['Maker', 'Appreciator']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.fontFamily, AppTextStyles.fontFamily);
      expect(text.style?.fontSize, 22);
      expect(text.style?.fontWeight, FontWeight.w500);
    }

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
    for (final label in <String>['Maker', 'Appreciator']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.fontSize, 22);
      expect(text.style?.fontWeight, FontWeight.w500);
    }
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';
import 'package:ma_motion_mobile/core/widgets/ma_dotted_background.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_role_selection_wandering_dots.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/ma_role_selection_screen.dart';

void main() {
  test('Role Selection dots independently wander and return exactly', () {
    expect(MaDotGridMetrics.columns, 18);
    expect(MaDotGridMetrics.rows, 36);
    expect(MaDotGridMetrics.dotRadius, 0.8);

    for (final seconds in <double>[0, 6, 7]) {
      expect(
        MaRoleSelectionDotMotion.displacement(
          row: 0,
          column: 0,
          animationSeconds: seconds,
        ),
        Offset.zero,
      );
      expect(
        MaRoleSelectionDotMotion.displacement(
          row: 20,
          column: 10,
          animationSeconds: seconds,
        ),
        Offset.zero,
      );
    }

    final first = MaRoleSelectionDotMotion.displacement(
      row: 0,
      column: 0,
      animationSeconds: 2.2,
    );
    final second = MaRoleSelectionDotMotion.displacement(
      row: 0,
      column: 1,
      animationSeconds: 2.2,
    );
    final third = MaRoleSelectionDotMotion.displacement(
      row: 1,
      column: 0,
      animationSeconds: 2.2,
    );
    expect(first.distance, greaterThan(3));
    expect(second.distance, greaterThan(3));
    expect(first, isNot(second));
    expect(first, isNot(third));

    // Each dot travels to one point, turns once toward a second point, and
    // returns to origin; neighboring dots do not share the same direction.
    final secondPoint = MaRoleSelectionDotMotion.displacement(
      row: 0,
      column: 0,
      animationSeconds: 4.2,
    );
    final nextLeg = secondPoint - first;
    expect(nextLeg.distance, greaterThan(1));
    expect(
      (first.dx * nextLeg.dx + first.dy * nextLeg.dy).abs(),
      lessThan(first.distance * nextLeg.distance * 0.75),
    );
    expect(
      MaRoleSelectionDotMotion.displacement(
        row: 0,
        column: 0,
        animationSeconds: 0.5,
      ).distance,
      lessThan(first.distance),
    );
    expect(
      MaRoleSelectionDotMotion.displacement(
        row: 0,
        column: 0,
        animationSeconds: 5.9,
      ).distance,
      lessThan(first.distance),
    );
  });

  testWidgets(
    'Role Selection waits 1s, moves in two directions, returns by 7s without moving UI',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MaRoleSelectionScreen(onMaker: () {}, onAppreciator: () {}),
        ),
      );

      final dots = find.byKey(const Key('role_selection_wandering_dots'));
      final heading = find.text(
        'Would you like to\njoin as a Maker or\nAppreciator?',
      );
      final maker = find.byKey(const Key('select_maker_button'));
      final appreciator = find.byKey(
        const Key('select_appreciator_button'),
      );

      expect(dots, findsOneWidget);
      expect(find.byType(MaDottedBackground), findsNothing);
      final originalHeading = tester.getRect(heading);
      final originalMaker = tester.getRect(maker);
      final originalAppreciator = tester.getRect(appreciator);

      double animationSeconds() =>
          (tester.widget<CustomPaint>(dots).painter!
                  as MaRoleSelectionWanderingDotsPainter)
              .animationSeconds;

      expect(animationSeconds(), 0);
      await tester.pump(const Duration(milliseconds: 999));
      expect(animationSeconds(), 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(animationSeconds(), 0);

      await tester.pump(const Duration(seconds: 1));
      expect(animationSeconds(), closeTo(1, 0.02));
      await tester.pump(const Duration(seconds: 2));
      expect(animationSeconds(), closeTo(3, 0.02));
      await tester.pump(const Duration(seconds: 3));
      expect(animationSeconds(), closeTo(6, 0.02));
      expect(
        MaRoleSelectionDotMotion.displacement(
          row: 7,
          column: 5,
          animationSeconds: animationSeconds(),
        ),
        Offset.zero,
      );

      expect(tester.getRect(heading), originalHeading);
      expect(tester.getRect(maker), originalMaker);
      expect(tester.getRect(appreciator), originalAppreciator);
      expect(tester.takeException(), isNull);
    },
  );

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

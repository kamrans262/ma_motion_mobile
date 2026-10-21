import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_choice_chip.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/maker_registration_flow_screen.dart';

void main() {
  Widget app({int initialStep = 0}) {
    return ProviderScope(
      child: MaterialApp(
        home: MakerRegistrationFlowScreen(
          initialStep: initialStep,
          onExit: () {},
        ),
      ),
    );
  }

  testWidgets('each visible registration dot is exactly 8 by 8', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    for (var index = 0; index < 7; index++) {
      final finder = find.byKey(Key('maker_step_dot_$index'));

      expect(finder, findsOneWidget);
      expect(
        tester.getSize(finder),
        const Size(8, 8),
        reason: 'Progress dot $index must render at exactly 8x8.',
      );
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('dot spacing stays separate from the 8 by 8 dot size', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    final first = tester.getTopLeft(find.byKey(const Key('maker_step_dot_0')));
    final second = tester.getTopLeft(find.byKey(const Key('maker_step_dot_1')));

    // 8px dot + 4px right padding + 4px left padding = 16px center-to-start.
    expect(second.dx - first.dx, 16);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Type Style step follows Figma centered content and vertical gaps', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(initialStep: 3));

    final heading = find.byKey(const Key('maker_step_heading'));
    final subtitle = find.byKey(const Key('maker_step_subtitle'));
    final typeLabel = find.text('Type');
    final styleChips = find.byKey(const Key('maker_style_options'));
    final scroll = find.byKey(const Key('maker_onboarding_scroll'));

    expect(
      tester.getTopLeft(subtitle).dy - tester.getBottomLeft(heading).dy,
      closeTo(8, 0.1),
    );
    expect(
      tester.getTopLeft(typeLabel).dy - tester.getBottomLeft(subtitle).dy,
      closeTo(24, 0.1),
    );

    final blockCenter = (
      tester.getTopLeft(heading).dy + tester.getBottomLeft(styleChips).dy
    ) / 2;
    // Top inset 32 and bottom inset 30 center the content one pixel
    // below the viewport midpoint when sufficient vertical room exists.
    expect(blockCenter, closeTo(tester.getCenter(scroll).dy + 1, 2));
    expect(tester.getTopLeft(heading).dy, greaterThan(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Type Style typography matches the Filter popup', (tester) async {
    await tester.pumpWidget(app(initialStep: 3));

    final typeText = tester.widget<Text>(find.text('Type'));
    final styleText = tester.widget<Text>(find.text('Style'));
    final paintingText = tester.widget<Text>(find.text('Painting'));
    final abstractText = tester.widget<Text>(find.text('Abstract'));

    for (final label in <Text>[typeText, styleText]) {
      expect(label.style?.fontFamily, AppTextStyles.bodyFontFamily);
      expect(label.style?.fontSize, 12);
      expect(label.style?.fontWeight, FontWeight.w400);
      expect(label.style?.height, 1.4);
    }

    for (final label in <Text>[paintingText, abstractText]) {
      expect(label.style?.fontFamily, AppTextStyles.bodyFontFamily);
      expect(label.style?.fontSize, 12);
      expect(label.style?.fontWeight, FontWeight.w500);
      expect(label.style?.letterSpacing, 0);
      expect(label.style?.height, 16 / 12);
    }

    for (final wrapKey in <String>['maker_type_options', 'maker_style_options']) {
      final wrap = tester.widget<Wrap>(find.byKey(Key(wrapKey)));
      expect(wrap.spacing, 8);
      expect(wrap.runSpacing, 8);
    }

    for (final pair in <(String, String)>[
      ('Type', 'maker_type_options'),
      ('Style', 'maker_style_options'),
    ]) {
      expect(
        tester.getTopLeft(find.byKey(Key(pair.$2))).dy -
            tester.getBottomLeft(find.text(pair.$1)).dy,
        closeTo(8, 0.1),
      );
    }

    for (final choice in <(String, String)>[
      ('maker_type_Painting', 'Painting'),
      ('maker_style_Abstract', 'Abstract'),
    ]) {
      final buttonCenter = tester.getCenter(find.byKey(Key(choice.$1)));
      final labelCenter = tester.getCenter(find.text(choice.$2));
      expect(labelCenter.dx, closeTo(buttonCenter.dx, 1));
      expect(
        labelCenter.dy,
        closeTo(buttonCenter.dy, 1),
      );
    }

    final choice = tester.widget<MaChoiceChip>(
      find.byKey(const Key('maker_type_Painting')),
    );
    expect(choice.fontSize, 12);
    expect(choice.fontFamily, AppTextStyles.bodyFontFamily);
    expect(choice.selectedFontWeight, FontWeight.w600);
    expect(choice.letterSpacing, 0);
    expect(choice.verticalOffset, 0);
    expect(
      choice.padding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );

    final unselected = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Painting'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(unselected.decoration, isA<BoxDecoration>());
    expect(
      (unselected.decoration! as BoxDecoration).color,
      AppColors.savedBackground,
    );

    final paintingChip = find.byKey(const Key('maker_type_Painting'));
    final sculptureChip = find.byKey(const Key('maker_type_Sculpture'));
    final paintingRect = tester.getRect(paintingChip);
    final sculptureRect = tester.getRect(sculptureChip);

    await tester.tap(paintingChip);
    await tester.pumpAndSettle();
    expect(tester.getRect(paintingChip), paintingRect);
    expect(tester.getRect(sculptureChip), sculptureRect);
    expect(tester.widget<MaChoiceChip>(paintingChip).selected, isTrue);
    expect(
      tester.widget<Text>(find.text('Painting')).style?.fontWeight,
      FontWeight.w600,
    );
    await tester.tap(paintingChip);
    await tester.pumpAndSettle();
    expect(tester.getRect(paintingChip), paintingRect);
    expect(tester.getRect(sculptureChip), sculptureRect);
    expect(tester.widget<MaChoiceChip>(paintingChip).selected, isFalse);
    expect(
      tester.widget<Text>(find.text('Painting')).style?.fontWeight,
      FontWeight.w500,
    );

    expect(tester.takeException(), isNull);
  });
}

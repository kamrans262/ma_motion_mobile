import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';
import 'package:ma_motion_mobile/core/widgets/ma_centered_taxonomy_label.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/maker_registration_flow_screen.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_choice_chip.dart';

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

  testWidgets('Onboarding Type/Style chips match Filter typography', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialStep: 3));

    final typeText = tester.widget<Text>(find.text('Type'));
    final styleText = tester.widget<Text>(find.text('Style'));
    final paintingText = tester.widget<Text>(find.text('Painting'));
    final abstractText = tester.widget<Text>(find.text('Abstract'));

    for (final label in <Text>[typeText, styleText]) {
      expect(label.style?.fontFamily, AppTextStyles.bodyFontFamily);
      expect(label.style?.fontSize, 12);
      expect(label.style?.fontWeight, FontWeight.w400);
      expect(label.style?.color, AppColors.primary);
    }
    for (final text in <Text>[paintingText, abstractText]) {
      expect(text.style?.fontFamily, AppTextStyles.bodyFontFamily);
      expect(text.style?.fontSize, 12);
      expect(text.style?.fontWeight, FontWeight.w400);
      expect(text.style?.fontStyle, isNot(FontStyle.italic));
    }

    for (final choice in <(String, String)>[
      ('maker_type_Painting', 'Painting'),
      ('maker_style_Abstract', 'Abstract'),
    ]) {
      final chipFinder = find.byKey(Key(choice.$1));
      final chip = tester.widget<MaChoiceChip>(chipFinder);
      expect(chip.verticalOffset, 0);
      final label = tester.widget<MaCenteredTaxonomyLabel>(
        find.descendant(
          of: chipFinder,
          matching: find.byType(MaCenteredTaxonomyLabel),
        ),
      );
      expect(label.verticalOffset, 0);
      final buttonCenter = tester.getCenter(chipFinder);
      final labelCenter = tester.getCenter(find.text(choice.$2));
      expect(labelCenter.dx, closeTo(buttonCenter.dx, 1));
      expect(labelCenter.dy, closeTo(buttonCenter.dy, 1));
    }

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

    expect(tester.takeException(), isNull);
  });
}

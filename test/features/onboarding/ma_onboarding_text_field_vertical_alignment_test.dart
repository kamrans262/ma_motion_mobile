import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_onboarding_text_field.dart';

void main() {
  testWidgets('single-line hint and entered text are centered', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaOnboardingTextField(
            controller: controller,
            hintText: 'Your name',
          ),
        ),
      ),
    );

    final fieldFinder = find.byType(TextField);
    final field = tester.widget<TextField>(fieldFinder);
    expect(field.textAlignVertical, TextAlignVertical.center);
    expect(field.decoration?.hintText, 'Your name');
    expect(field.decoration?.hintStyle?.fontFamily, AppTextStyles.bodyFontFamily);
    expect(field.decoration?.hintStyle?.fontSize, 16);
    expect(field.decoration?.hintStyle?.letterSpacing, 0);
    expect(
      field.decoration?.hintStyle?.color,
      AppColors.white.withValues(alpha: 0.40),
    );
    expect(
      field.decoration?.contentPadding,
      const EdgeInsets.fromLTRB(16, 21, 16, 7),
    );
    // Check actual hint layout, not only the TextField's alignment property.
    final fieldBounds = tester.getRect(fieldFinder);
    final hintBounds = tester.getRect(find.text('Your name'));
    expect(hintBounds.center.dy - fieldBounds.center.dy, closeTo(2, 5));

    await tester.enterText(fieldFinder, 'Example Maker');
    await tester.pump();
    expect(controller.text, 'Example Maker');
    expect(
      tester.widget<TextField>(fieldFinder).textAlignVertical,
      TextAlignVertical.center,
    );
    // Entered text remains centered after replacing the placeholder.
    final editableBounds = tester.getRect(find.byType(EditableText));
    expect(editableBounds.center.dy - fieldBounds.center.dy, closeTo(2, 5));
  });

  testWidgets('multiline fields keep text top-aligned', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MaOnboardingTextField(
            controller: controller,
            hintText: 'Tell us about your work',
            maxLines: 3,
          ),
        ),
      ),
    );

    final fieldFinder = find.byType(TextField);
    expect(
      tester.widget<TextField>(fieldFinder).textAlignVertical,
      TextAlignVertical.top,
    );
    expect(
      tester.widget<TextField>(fieldFinder).decoration?.contentPadding,
      const EdgeInsets.fromLTRB(16, 21, 16, 11),
    );
    await tester.enterText(fieldFinder, 'I make colorful work.');
    await tester.pump();
    expect(controller.text, 'I make colorful work.');
    expect(
      tester.widget<TextField>(fieldFinder).textAlignVertical,
      TextAlignVertical.top,
    );
  });
}

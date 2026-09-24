import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_onboarding_text_field.dart';

void main() {
  testWidgets('single-line placeholder and entered text are vertically centered', (
    tester,
  ) async {
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
    expect(
      field.decoration?.contentPadding,
      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    );
    // Check actual hint layout, not only the TextField's alignment property.
    final fieldBounds = tester.getRect(fieldFinder);
    final hintBounds = tester.getRect(find.text('Your name'));
    expect(
      hintBounds.center.dy - fieldBounds.center.dy,
      closeTo(0, 3),
    );

    await tester.enterText(fieldFinder, 'Example Maker');
    await tester.pump();
    expect(controller.text, 'Example Maker');
    expect(
      tester.widget<TextField>(fieldFinder).textAlignVertical,
      TextAlignVertical.center,
    );
    // Entered text remains centered after replacing the placeholder.
    final editableBounds = tester.getRect(find.byType(EditableText));
    expect(editableBounds.center.dy - fieldBounds.center.dy, closeTo(0, 3));
  });

  testWidgets('multiline placeholder and entered text are vertically centered', (
    tester,
  ) async {
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
      const EdgeInsets.fromLTRB(20, 21, 20, 11),
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

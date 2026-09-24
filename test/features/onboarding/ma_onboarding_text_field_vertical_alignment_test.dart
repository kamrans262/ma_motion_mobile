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
    expect(field.textAlignVertical, TextAlignVertical.top);
    expect(field.decoration?.hintText, 'Your name');
    expect(
      field.decoration?.contentPadding,
      const EdgeInsets.fromLTRB(20, 17, 20, 11),
    );
    // Check actual hint layout, not only the TextField's alignment property.
    final fieldBounds = tester.getRect(fieldFinder);
    final hintBounds = tester.getRect(find.text('Your name'));
    expect(
      hintBounds.center.dy - fieldBounds.center.dy,
      inInclusiveRange(0.0, 5.0),
    );

    await tester.enterText(fieldFinder, 'Example Maker');
    await tester.pump();
    expect(controller.text, 'Example Maker');
    expect(
      tester.widget<TextField>(fieldFinder).textAlignVertical,
      TextAlignVertical.top,
    );
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
      const EdgeInsets.fromLTRB(20, 19, 20, 13),
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

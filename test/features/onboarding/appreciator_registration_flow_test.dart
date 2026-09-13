import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/appreciator_registration_flow_screen.dart';

void main() {
  Widget app({int initialStep = 0, VoidCallback? onExit}) {
    return ProviderScope(
      child: MaterialApp(
        home: AppreciatorRegistrationFlowScreen(
          key: ValueKey<int>(initialStep),
          initialStep: initialStep,
          onExit: onExit ?? () {},
        ),
      ),
    );
  }

  testWidgets('Appreciator flow starts with name and three progress dots', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.byKey(const Key('appreciator_name_field')), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      expect(find.byKey(Key('maker_step_dot_$index')), findsOneWidget);
    }

    expect(find.byKey(const Key('maker_step_dot_3')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appreciator name and location validate and advance', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pump();
    expect(find.byKey(const Key('maker_validation_message')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('appreciator_name_field')),
      'Art Lover',
    );
    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('Where are you based?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('appreciator_location_field')),
      'Chicago 60601',
    );
    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.byKey(const Key('appreciator_email_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back from first Appreciator step returns to role selection', (
    tester,
  ) async {
    var exited = false;

    await tester.pumpWidget(app(onExit: () => exited = true));
    await tester.tap(find.byKey(const Key('maker_back_button')));
    await tester.pump();

    expect(exited, isTrue);
    expect(tester.takeException(), isNull);
  });
}

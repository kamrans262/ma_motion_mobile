import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/onboarding/application/maker_registration_controller.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/maker_registration_flow_screen.dart';

void main() {
  Widget app({
    int initialStep = 0,
    VoidCallback? onExit,
    double keyboardInset = 0,
  }) {
    final flow = MakerRegistrationFlowScreen(
      key: ValueKey<int>(initialStep),
      initialStep: initialStep,
      onExit: onExit ?? () {},
    );

    return ProviderScope(
      child: MaterialApp(
        home: keyboardInset > 0
            ? MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 844),
                  viewInsets: EdgeInsets.only(bottom: keyboardInset),
                ),
                child: flow,
              )
            : flow,
      ),
    );
  }

  testWidgets('maker flow starts with name and seven progress dots', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text("What's your name or studio name?"), findsOneWidget);
    expect(find.byKey(const Key('maker_name_field')), findsOneWidget);

    for (var index = 0; index < 7; index++) {
      expect(find.byKey(Key('maker_step_dot_$index')), findsOneWidget);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('Next uses the same outline treatment as Back', (tester) async {
    await tester.pumpWidget(app());

    final nextButton = find.byKey(const Key('maker_next_button'));
    final backButton = find.byKey(const Key('maker_back_button'));

    expect(
      find.descendant(of: nextButton, matching: find.byType(OutlinedButton)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: backButton, matching: find.byType(OutlinedButton)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('name Next validates and then moves to location', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pump();

    expect(find.byKey(const Key('maker_validation_message')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('maker_name_field')),
      'MA Studio',
    );

    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('Where are you based?'), findsOneWidget);
    expect(find.byKey(const Key('maker_location_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back from first maker step exits to role selection', (
    tester,
  ) async {
    var exited = false;

    await tester.pumpWidget(app(onExit: () => exited = true));

    await tester.tap(find.byKey(const Key('maker_back_button')));
    await tester.pump();

    expect(exited, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress dots keep about 50px bottom spacing without an inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pump();

    final gap = tester.widget<SizedBox>(
      find.byKey(const Key('maker_dots_bottom_gap')),
    );

    expect(gap.height, 50);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Maker footer stays outside the scrollable content area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(initialStep: 3));
    await tester.pump();

    final scrollRect = tester.getRect(
      find.byKey(const Key('maker_onboarding_scroll')),
    );
    final footerRect = tester.getRect(
      find.byKey(const Key('maker_onboarding_footer')),
    );

    expect(scrollRect.bottom, lessThanOrEqualTo(footerRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('type and style step is scroll-safe on compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(initialStep: 3));
    await tester.pump();

    expect(find.text('What kind of work do\nyou make?'), findsOneWidget);
    expect(find.byKey(const Key('maker_type_options')), findsOneWidget);
    expect(find.byKey(const Key('maker_style_options')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about-work field stays fully visible above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const keyboardInset = 320.0;

    await tester.pumpWidget(
      app(initialStep: 2, keyboardInset: keyboardInset),
    );
    await tester.pump();

    expect(find.text('Tell us about your work'), findsOneWidget);
    expect(find.byKey(const Key('maker_onboarding_footer')), findsNothing);

    final field = find.byKey(const Key('maker_about_field'));
    expect(field, findsOneWidget);

    final fieldRect = tester.getRect(field);
    expect(fieldRect.bottom, lessThanOrEqualTo(844 - keyboardInset));
    expect(tester.takeException(), isNull);
  });

  testWidgets('type and style content starts higher and clears the footer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(initialStep: 3));
    await tester.pump();

    final headingTop = tester.getTopLeft(
      find.byKey(const Key('maker_step_heading')),
    );
    expect(headingTop.dy, lessThan(120));

    final scrollable = find.descendant(
      of: find.byKey(const Key('maker_onboarding_scroll')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(scrollable, findsOneWidget);

    final lastStyle = find.byKey(const Key('maker_style_Experimental'));
    await tester.scrollUntilVisible(
      lastStyle,
      180,
      scrollable: scrollable,
    );
    await tester.pump();

    final footerTop = tester.getTopLeft(
      find.byKey(const Key('maker_onboarding_footer')),
    ).dy;
    final lastStyleBottom = tester.getBottomLeft(lastStyle).dy;

    expect(lastStyleBottom, lessThanOrEqualTo(footerTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('email step renders responsive reusable email field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(initialStep: 5));

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.byKey(const Key('maker_email_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Maker reference geometry is preserved on a 390x844 phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await tester.pump();

    final headingTop = tester.getTopLeft(
      find.byKey(const Key('maker_step_heading')),
    );
    final fieldRect = tester.getRect(find.byKey(const Key('maker_name_field')));
    final nextSize = tester.getSize(find.byKey(const Key('maker_next_button')));
    final backSize = tester.getSize(find.byKey(const Key('maker_back_button')));

    expect(headingTop.dx, closeTo(20, 0.1));
    expect(headingTop.dy, closeTo(216.45, 1.0));
    expect(fieldRect.left, closeTo(20, 0.1));
    expect(fieldRect.right, closeTo(370, 0.1));
    expect(nextSize.height, 46);
    expect(backSize.height, 46);
    expect(tester.takeException(), isNull);
  });

  testWidgets('salon image picker follows the supplied 88px square', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialStep: 6));

    expect(
      tester.getSize(find.byKey(const Key('maker_salon_image_picker'))),
      const Size(88, 88),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('salon preview uses platform-neutral memory image', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 1x1 transparent PNG.
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      'YAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    );

    container
        .read(makerRegistrationProvider.notifier)
        .setImage(
          bytes: bytes,
          name: 'salon.png',
          path: 'native/path/is/optional.png',
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MakerRegistrationFlowScreen(initialStep: 6, onExit: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('maker_salon_image_preview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('salon image step renders upload control', (tester) async {
    await tester.pumpWidget(app(initialStep: 6));

    expect(find.text('Upload your salon image'), findsOneWidget);
    expect(find.byKey(const Key('maker_salon_image_picker')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

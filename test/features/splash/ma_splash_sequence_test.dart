import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/splash/presentation/screens/ma_splash_sequence_screen.dart';

void main() {
  Widget app({
    bool autoPlay = false,
    VoidCallback? onFinished,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return MaterialApp(
      home: MaSplashSequenceScreen(
        autoPlay: autoPlay,
        onFinished: onFinished,
        duration: duration,
      ),
    );
  }

  Opacity opacityForLine(WidgetTester tester, Key lineKey) {
    final finder = find.descendant(
      of: find.byKey(lineKey),
      matching: find.byType(Opacity),
    );

    expect(
      finder,
      findsOneWidget,
      reason: 'Expected exactly one Opacity descendant for $lineKey',
    );

    return tester.widget<Opacity>(finder);
  }

  testWidgets('is one splash scene and starts with the MA logo visible', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_logo')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_welcome_text')), findsOneWidget);

    final lineOneOpacity = opacityForLine(
      tester,
      const Key('ma_splash_line_1'),
    );
    final lineTwoOpacity = opacityForLine(
      tester,
      const Key('ma_splash_line_2'),
    );
    final lineThreeOpacity = opacityForLine(
      tester,
      const Key('ma_splash_line_3'),
    );

    expect(lineOneOpacity.opacity, 0);
    expect(lineTwoOpacity.opacity, 0);
    expect(lineThreeOpacity.opacity, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome copy animates in after the logo', (tester) async {
    await tester.pumpWidget(
      app(autoPlay: true, duration: const Duration(milliseconds: 1000)),
    );

    await tester.pump(const Duration(milliseconds: 650));

    final lineOneOpacity = opacityForLine(
      tester,
      const Key('ma_splash_line_1'),
    );
    final lineTwoOpacity = opacityForLine(
      tester,
      const Key('ma_splash_line_2'),
    );
    final lineThreeOpacity = opacityForLine(
      tester,
      const Key('ma_splash_line_3'),
    );

    expect(lineOneOpacity.opacity, greaterThan(0));
    expect(lineTwoOpacity.opacity, greaterThan(0));
    expect(lineThreeOpacity.opacity, greaterThanOrEqualTo(0));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('calls onFinished after the animation completes', (tester) async {
    var finished = false;

    await tester.pumpWidget(
      app(
        autoPlay: true,
        onFinished: () => finished = true,
        duration: const Duration(milliseconds: 500),
      ),
    );

    await tester.pump(const Duration(milliseconds: 501));

    expect(finished, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('does not overflow on compact phone width', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(autoPlay: false));
    await tester.pump();

    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_logo')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_welcome_text')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

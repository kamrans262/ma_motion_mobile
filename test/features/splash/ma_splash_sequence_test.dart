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

    expect(finder, findsOneWidget);
    return tester.widget<Opacity>(finder);
  }

  testWidgets('MA splash starts with logo and hidden welcome copy', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_logo')), findsOneWidget);

    expect(opacityForLine(tester, const Key('ma_splash_line_1')).opacity, 0);
    expect(opacityForLine(tester, const Key('ma_splash_line_2')).opacity, 0);
    expect(opacityForLine(tester, const Key('ma_splash_line_3')).opacity, 0);

    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome copy animates after logo', (tester) async {
    await tester.pumpWidget(
      app(autoPlay: true, duration: const Duration(milliseconds: 1000)),
    );

    await tester.pump(const Duration(milliseconds: 650));

    expect(
      opacityForLine(tester, const Key('ma_splash_line_1')).opacity,
      greaterThan(0),
    );
    expect(
      opacityForLine(tester, const Key('ma_splash_line_2')).opacity,
      greaterThan(0),
    );

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('completion callback fires once', (tester) async {
    var completed = 0;

    await tester.pumpWidget(
      app(
        autoPlay: true,
        duration: const Duration(milliseconds: 300),
        onFinished: () => completed++,
      ),
    );

    await tester.pump(const Duration(milliseconds: 301));

    expect(completed, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('splash is safe at compact phone size', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());

    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

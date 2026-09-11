import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/main.dart';

void main() {
  testWidgets('MA Motion app starts in one splash scene with logo first', (
    tester,
  ) async {
    await tester.pumpWidget(const MaMotionApp(splashAutoPlay: false));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_logo')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

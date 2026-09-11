import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/splash/presentation/widgets/ma_full_logo.dart';

void main() {
  testWidgets('full MA logo uses contain and is not cropped by its widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, height: 568, child: MaFullLogo()),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byKey(const Key('ma_splash_logo')));

    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.center);
    expect(tester.takeException(), isNull);
  });
}

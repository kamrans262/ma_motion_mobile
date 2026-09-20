import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/widgets/ma_dotted_background.dart';

void main() {
  test('Splash and onboarding share exactly 18 columns and 36 rows', () {
    expect(MaDotGridMetrics.columns, 18);
    expect(MaDotGridMetrics.rows, 36);
    expect(MaDotGridMetrics.columns * MaDotGridMetrics.rows, 648);

    for (final size in <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      final horizontal = MaDotGridMetrics.horizontalSpacing(size);
      final vertical = MaDotGridMetrics.verticalSpacing(size);
      final radius = MaDotGridMetrics.dotRadius;
      expect(horizontal * MaDotGridMetrics.columns, closeTo(size.width, 0.001));
      expect(vertical * MaDotGridMetrics.rows, closeTo(size.height, 0.001));
      expect(horizontal / 2, greaterThan(radius));
      expect(vertical / 2, greaterThan(radius));
      expect(size.width - horizontal / 2, lessThan(size.width - radius));
      expect(size.height - vertical / 2, lessThan(size.height - radius));
      expect(
        MaDotGridMetrics.solidCircleRadius(size),
        greaterThan(horizontal / 2),
      );
      expect(
        MaDotGridMetrics.solidCircleRadius(size),
        greaterThan(vertical / 2),
      );
    }
  });

  testWidgets('dotted background safely handles a zero-size surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 0, height: 0, child: MaDottedBackground()),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('dotted background renders on a compact phone-sized surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 320, height: 568, child: MaDottedBackground()),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MaDottedBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

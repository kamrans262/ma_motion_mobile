import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/widgets/ma_dotted_background.dart';

void main() {
  test('Splash and onboarding use a full-bleed square dot grid', () {
    expect(MaDotGridMetrics.columns, 18);
    expect(MaDotGridMetrics.minimumRows, 36);
    expect(MaDotGridMetrics.dotRadius, 0.8);
    expect(MaDotGridMetrics.dotRadius * 2, 1.6);
    expect(MaDotGridMetrics.spacingScale, 1.10);

    for (final size in <Size>[
      const Size(320, 568),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      final horizontal = MaDotGridMetrics.horizontalSpacing(size);
      final vertical = MaDotGridMetrics.verticalSpacing(size);
      final origin = MaDotGridMetrics.gridOrigin(size);
      final radius = MaDotGridMetrics.dotRadius;
      final rows = MaDotGridMetrics.rowCount(size);
      final gridWidth = horizontal * MaDotGridMetrics.columns;
      final gridHeight = vertical * rows;

      expect(horizontal, closeTo(vertical, 0.001));
      expect(gridWidth, closeTo(size.width * 1.10, 0.001));
      expect(rows, greaterThanOrEqualTo(MaDotGridMetrics.minimumRows));
      expect(gridHeight, greaterThan(size.height));
      expect(origin.dx, closeTo(-(size.width * 0.05), 0.001));
      expect(origin.dy, lessThanOrEqualTo(0));
      expect(horizontal / 2, greaterThan(radius));
      expect(vertical / 2, greaterThan(radius));
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

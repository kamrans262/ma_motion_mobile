import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/widgets/ma_dotted_background.dart';

void main() {
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

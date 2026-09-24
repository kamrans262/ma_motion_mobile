import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/widgets/maker_bottom_navigation.dart';

void main() {
  testWidgets('all four grid numbers stay 16px and only color changes on selection', (
    tester,
  ) async {
    var selectedColumn = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: MakerBottomNavigation(
              selectedColumnCount: selectedColumn,
              onColumnCountSelected: (value) {
                setState(() => selectedColumn = value);
              },
            ),
          ),
        ),
      ),
    );

    void verifyNumbers(int selected) {
      for (var column = 1; column <= 4; column++) {
        final number = tester.widget<Text>(
          find.byKey(Key('maker_nav_column_text_$column')),
        );
        expect(number.style?.fontSize, 16);
        expect(number.style?.fontWeight, FontWeight.w500);
        expect(
          number.style?.color,
          column == selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.50),
        );
      }
    }

    verifyNumbers(2);
    await tester.tap(find.byKey(const Key('maker_nav_4')));
    await tester.pump();
    verifyNumbers(4);
    expect(tester.takeException(), isNull);
  });
}

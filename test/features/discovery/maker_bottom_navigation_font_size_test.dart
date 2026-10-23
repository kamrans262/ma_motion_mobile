import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/widgets/maker_bottom_navigation.dart';

void main() {
  testWidgets('bottom bar matches Figma V2 number and icon spacing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(bottomNavigationBar: MakerBottomNavigation()),
      ),
    );
    await tester.pump();

    final keys = <Key>[
      const Key('maker_nav_saved_svg'),
      const Key('maker_nav_1'),
      const Key('maker_nav_2'),
      const Key('maker_nav_3'),
      const Key('maker_nav_4'),
      const Key('maker_nav_settings_svg'),
    ];
    final centers = keys
        .map((key) => tester.getCenter(find.byKey(key)).dx)
        .toList();

    // Keep Figma V2's approximately 87.3px number-to-number spacing.
    // The icons shift 6px outward to produce 50px outer center gaps.
    expect(centers[1] - centers[0], closeTo(50, 0.2));
    for (var i = 1; i < 4; i++) {
      expect(centers[i + 1] - centers[i], closeTo(87.33, 0.2));
    }
    expect(centers[5] - centers[4], closeTo(50, 0.2));
    expect(tester.getSize(find.byKey(const Key('maker_nav_saved_svg'))), const Size(22, 22));
    expect(tester.getSize(find.byKey(const Key('maker_nav_settings_svg'))), const Size(24, 24));

    // The number glyphs are shifted down optically while keeping their
    // horizontal centers, touch targets, and font geometry unchanged.
    final heartCenterY = tester
        .getCenter(find.byKey(const Key('maker_nav_saved_svg')))
        .dy;
    final settingsCenterY = tester
        .getCenter(find.byKey(const Key('maker_nav_settings_svg')))
        .dy;
    expect(settingsCenterY, closeTo(heartCenterY, 0.2));
    for (var column = 1; column <= 4; column++) {
      final textCenterY = tester
          .getCenter(find.byKey(Key('maker_nav_column_text_$column')))
          .dy;
      expect(textCenterY - heartCenterY, closeTo(2, 0.2));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom bar stays overflow-free at narrow phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(bottomNavigationBar: MakerBottomNavigation()),
      ),
    );
    await tester.pump();

    for (var column = 1; column <= 4; column++) {
      expect(find.byKey(Key('maker_nav_$column')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('grid numbers stay 16px; selection changes only color', (
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/widgets/ma_svg_asset.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/widgets/maker_bottom_navigation.dart';
import 'package:ma_motion_mobile/features/discovery/presentation/widgets/discovery_layout_metrics.dart';

void main() {
  testWidgets('bottom bar icons match top toolbar edge insets', (
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

    // At 430px, the two outer gaps are exactly 50 logical pixels.
    // The four number positions adapt to preserve the icon edge alignment.
    expect(centers[1] - centers[0], closeTo(50, 0.2));
    for (var i = 1; i < 4; i++) {
      expect(centers[i + 1] - centers[i], closeTo(81.33, 0.2));
    }
    expect(centers[5] - centers[4], closeTo(50, 0.2));
    expect(
      tester.getTopLeft(find.byKey(const Key('maker_nav_saved_svg'))).dx,
      closeTo(32, 0.2),
    );
    expect(
      430 -
          tester.getBottomRight(
            find.byKey(const Key('maker_nav_settings_svg')),
          ).dx,
      closeTo(32, 0.2),
    );
    expect(tester.getSize(find.byKey(const Key('maker_nav_saved_svg'))), const Size(20, 20));
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

    // Heart uses 20px and Settings uses 24px at every screen width;
    // the toolbar and navigation insets remain responsive.
    expect(
      tester.getTopLeft(find.byKey(const Key('maker_nav_saved_svg'))).dx,
      closeTo(29.4, 0.2),
    );
    expect(
      280 -
          tester.getBottomRight(
            find.byKey(const Key('maker_nav_settings_svg')),
          ).dx,
      closeTo(28.4, 0.2),
    );
    // At 280 logical pixels there is not enough room to keep both 50px
    // outer gaps and four 40px-wide number targets, so they adapt evenly.
    final centers = <Key>[
      const Key('maker_nav_saved_svg'),
      const Key('maker_nav_1'),
      const Key('maker_nav_2'),
      const Key('maker_nav_3'),
      const Key('maker_nav_4'),
      const Key('maker_nav_settings_svg'),
    ].map((key) => tester.getCenter(find.byKey(key)).dx).toList();
    expect(centers[1] - centers[0], closeTo(40.1, 0.2));
    for (var i = 1; i < 4; i++) {
      expect(centers[i + 1] - centers[i], closeTo(40, 0.2));
    }
    expect(centers[5] - centers[4], closeTo(40.1, 0.2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('50px icon gaps and toolbar edge alignment adapt across widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in <double>[320, 375, 390, 430, 600]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: MakerBottomNavigation()),
        ),
      );
      await tester.pump();

      final metrics = DiscoveryLayoutMetrics.fromWidth(width);
      final expectedHeartLeft =
          metrics.gridHorizontalPadding + (48 - metrics.toolbarIconSize) / 2;
      final expectedSettingsRight = metrics.gridHorizontalPadding + 12;
      expect(
        tester.getTopLeft(find.byKey(const Key('maker_nav_saved_svg'))).dx,
        closeTo(expectedHeartLeft, 0.2),
      );
      expect(
        width -
            tester.getBottomRight(
              find.byKey(const Key('maker_nav_settings_svg')),
            ).dx,
        closeTo(expectedSettingsRight, 0.2),
      );

      final centers = <Key>[
        const Key('maker_nav_saved_svg'),
        const Key('maker_nav_1'),
        const Key('maker_nav_2'),
        const Key('maker_nav_3'),
        const Key('maker_nav_4'),
        const Key('maker_nav_settings_svg'),
      ].map((key) => tester.getCenter(find.byKey(key)).dx).toList();

      expect(centers[1] - centers[0], closeTo(50, 0.2));
      expect(centers[5] - centers[4], closeTo(50, 0.2));
      final spacing = centers[2] - centers[1];
      for (var i = 2; i < 4; i++) {
        expect(centers[i + 1] - centers[i], closeTo(spacing, 0.2));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('selected Heart uses matching 20px filled SVG geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MakerBottomNavigation(heartSelected: true),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('maker_nav_saved_svg'))),
      const Size(20, 20),
    );
    final selectedHeart = tester.widget<MaSvgAsset>(
      find.byKey(const Key('maker_nav_saved_filled')),
    );
    expect(selectedHeart.assetName, 'assets/heart_filled.svg');
    expect(selectedHeart.fallbackAssetName, 'assets/icons/heart_filled.svg');
    expect(selectedHeart.color, AppColors.primary);
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

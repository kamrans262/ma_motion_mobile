import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/widgets/ma_glass_popup.dart';

void main() {
  testWidgets('glass popup matches overlay, panel and inset contract', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MaGlassPopup(
          onDismiss: () => dismissed++,
          child: const Center(child: Text('Popup content')),
        ),
      ),
    );

    expect(MaGlassPopup.overlayBlurSigma, 4);
    expect(MaGlassPopup.panelBlurSigma, 12);
    expect(find.byType(BackdropFilter), findsNWidgets(2));

    final overlay = find.byKey(const Key('ma_glass_popup_overlay'));
    final panel = find.byKey(const Key('ma_glass_popup_panel'));
    final overlayBox = tester.widget<ColoredBox>(
      find.descendant(of: overlay, matching: find.byType(ColoredBox)).first,
    );
    final panelBox = tester.widget<ColoredBox>(
      find.descendant(of: panel, matching: find.byType(ColoredBox)).first,
    );
    expect(overlayBox.color, const Color(0xCC000000));
    expect(panelBox.color, const Color(0xB3000000));

    final padding = tester.widget<Padding>(
      find.byKey(const Key('ma_glass_popup_padding')),
    );
    expect(padding.padding, const EdgeInsets.all(24));
    expect(tester.getSize(panel).height, closeTo(720, 1));
    expect(tester.getTopLeft(panel).dx, greaterThanOrEqualTo(16));
    expect(tester.getTopRight(panel).dx, lessThanOrEqualTo(384));

    await tester.tapAt(const Offset(4, 4));
    expect(dismissed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('popup panel is capped at 448px on wide displays', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MaGlassPopup(
          onDismiss: () {},
          child: const Center(child: Text('Settings')),
        ),
      ),
    );

    final panel = find.byKey(const Key('ma_glass_popup_panel'));
    expect(tester.getSize(panel).width, closeTo(448, 1));
    expect(tester.getSize(panel).height, closeTo(900, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard reduces available popup height without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: MaGlassPopup(
            onDismiss: () {},
            child: const Center(child: Text('Keyboard-safe popup')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('ma_glass_popup_panel'))).height,
      closeTo(450, 1),
    );
    expect(tester.takeException(), isNull);
  });
}

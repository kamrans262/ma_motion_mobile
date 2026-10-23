import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Settings gear matches the original Heart width and stays centered', () async {
    final outline = await rootBundle.loadString('assets/heart.svg');
    final filled = await rootBundle.loadString('assets/heart_filled.svg');
    final gear = await rootBundle.loadString('assets/setting.svg');
    final gearFallback = await rootBundle.loadString('assets/icons/setting.svg');

    // The original Heart path spans x=1.548..22.452 in its 24px viewBox.
    expect(outline, contains('M20.84 4.61'));
    expect(filled, contains('M20.84 4.61'));
    expect(gearFallback, gear);
    // Settings' outer gear now reaches the same bounds, centered at x=12.
    // Its separate inner circular path is left unchanged.
    expect(gear, contains('L 1.548 9.2'));
    expect(gear, contains('L 22.452 9.2'));
    expect(gear, contains('M12 15.25A3.25 3.25'));
    expect(gear, isNot(contains('transform="translate(-0.67 0)"')));
  });

  test('bottom Heart and Settings assets use matched 24px canvas geometry', () async {
    final outline = await rootBundle.loadString('assets/heart.svg');
    final fallback = await rootBundle.loadString('assets/icons/heart.svg');
    final filled = await rootBundle.loadString('assets/heart_filled.svg');
    final filledFallback = await rootBundle.loadString(
      'assets/icons/heart_filled.svg',
    );
    final settings = await rootBundle.loadString('assets/setting.svg');

    for (final source in <String>[
      outline,
      fallback,
      filled,
      filledFallback,
      settings,
    ]) {
      expect(source, contains('width="24" height="24"'));
      expect(source, contains('viewBox="0 0 24 24"'));
      expect(source, contains('stroke-width="1.2"'));
    }

    expect(fallback, outline);
    expect(filledFallback, filled);
    final pathData = RegExp(r'\bd="([^"]+)"');
    final outlinedPath = pathData.firstMatch(outline)?.group(1);
    final selectedPath = pathData.firstMatch(filled)?.group(1);
    expect(outlinedPath, isNotNull);
    expect(selectedPath, outlinedPath);
    expect(outline, contains('fill="none"'));
    expect(filled, contains('fill="#9F67FF"'));
  });

  test('search, filter, heart, and settings use the shared 1.2 stroke width', () async {
    const assets = <String>[
      'assets/search.svg',
      'assets/heart.svg',
      'assets/MA_FilterIcon_3.svg',
      'assets/setting.svg',
    ];

    for (final asset in assets) {
      final source = await rootBundle.loadString(asset);
      expect(
        source.contains('stroke-width="1.2"') ||
            source.contains('stroke-width: 1.2px'),
        isTrue,
        reason: '$asset must use the shared 1.2 stroke width',
      );
    }
  });
}

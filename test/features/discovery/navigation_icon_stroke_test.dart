import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings inner circle and outer gear share the same horizontal center', () async {
    for (final asset in <String>['assets/setting.svg', 'assets/icons/setting.svg']) {
      final source = await rootBundle.loadString(asset);
      expect(source, contains('transform="translate(-0.67 0)"'));
    }
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

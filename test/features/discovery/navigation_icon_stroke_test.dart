import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('navigation SVG sources use the shared 1.4 stroke width', () async {
    const assets = <String>[
      'assets/search.svg',
      'assets/heart.svg',
      'assets/setting.svg',
      'assets/MA_FilterIcon_3.svg',
    ];

    for (final asset in assets) {
      final source = await rootBundle.loadString(asset);
      expect(
        source.contains('stroke-width="1.4"') ||
            source.contains('stroke-width: 1.4px'),
        isTrue,
        reason: '$asset must use the shared 1.4 stroke width',
      );
    }
  });
}

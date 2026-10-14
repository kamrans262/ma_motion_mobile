import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

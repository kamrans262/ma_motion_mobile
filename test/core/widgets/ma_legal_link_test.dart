import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/widgets/ma_legal_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.mamotion.ma_motion_mobile/external_links',
  );
  final binaryMessenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    binaryMessenger.setMockMethodCallHandler(channel, null);
  });

  for (final (label, url) in <(String, String)>[
    ('Terms & Conditions', MaLegalUrls.terms),
    ('Privacy Policy', MaLegalUrls.privacy),
  ]) {
    testWidgets('Android opens $label via the native browser intent', (tester) async {
      MethodCall? received;
      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        received = call;
        return true;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaLegalLink(
              label: label,
              url: url,
              textKey: const Key('legal_page'),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('legal_page')));
      await tester.pump();

      expect(received?.method, 'openExternalUrl');
      expect(received?.arguments, <String, String>{'url': url});
      expect(tester.takeException(), isNull);
    });
  }
}

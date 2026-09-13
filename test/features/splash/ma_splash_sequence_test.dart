import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';
import 'package:ma_motion_mobile/features/splash/presentation/screens/ma_splash_sequence_screen.dart';

void main() {
  Widget app({
    bool autoPlay = false,
    ValueChanged<MakerEntryDestination>? onResolved,
    Future<MakerEntryDestination> Function()? entryResolver,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: MaSplashSequenceScreen(
          autoPlay: autoPlay,
          onResolved: onResolved,
          entryResolver:
              entryResolver ?? () async => MakerEntryDestination.join,
          duration: duration,
        ),
      ),
    );
  }

  testWidgets('splash starts with purple opening mask over hidden content', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.byKey(const Key('ma_animated_splash')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_logo')), findsOneWidget);
    expect(find.byKey(const Key('ma_splash_dot_pattern')), findsOneWidget);

    final logoOpacity = tester.widget<Opacity>(
      find.byKey(const Key('ma_splash_logo_opacity')),
    );
    final welcomeOpacity = tester.widget<Opacity>(
      find.byKey(const Key('ma_splash_welcome_opacity')),
    );
    final background = tester.widget<ColoredBox>(
      find.byKey(const Key('ma_splash_background')),
    );

    // The logo is present underneath the solid purple opening mask. The mask
    // reveals it through its expanding holes rather than fading it in.
    expect(logoOpacity.opacity, 1);
    expect(welcomeOpacity.opacity, 0);
    expect(background.color, const Color(0xFF0F2419));
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening reveals static logo before welcome copy', (tester) async {
    await tester.pumpWidget(
      app(autoPlay: true, duration: const Duration(milliseconds: 1000)),
    );

    await tester.pump(const Duration(milliseconds: 420));

    final logoOpacity = tester.widget<Opacity>(
      find.byKey(const Key('ma_splash_logo_opacity')),
    );
    final welcomeOpacity = tester.widget<Opacity>(
      find.byKey(const Key('ma_splash_welcome_opacity')),
    );

    expect(logoOpacity.opacity, 1);
    expect(welcomeOpacity.opacity, 0);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('welcome fades in, holds, then fades out before navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        autoPlay: true,
        duration: const Duration(milliseconds: 1000),
        onResolved: (_) {},
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));

    var welcomeOpacity = tester.widget<Opacity>(
      find.byKey(const Key('ma_splash_welcome_opacity')),
    );
    expect(welcomeOpacity.opacity, 1);

    await tester.pump(const Duration(milliseconds: 270));

    welcomeOpacity = tester.widget<Opacity>(
      find.byKey(const Key('ma_splash_welcome_opacity')),
    );
    expect(welcomeOpacity.opacity, greaterThan(0));
    expect(welcomeOpacity.opacity, lessThan(1));

    await tester.pump(const Duration(milliseconds: 25));

    welcomeOpacity = tester.widget<Opacity>(
      find.byKey(const Key('ma_splash_welcome_opacity')),
    );
    expect(welcomeOpacity.opacity, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth resolved early waits for animation then navigates once', (
    tester,
  ) async {
    final destinations = <MakerEntryDestination>[];

    await tester.pumpWidget(
      app(
        autoPlay: true,
        duration: const Duration(milliseconds: 300),
        entryResolver: () async => MakerEntryDestination.discovery,
        onResolved: destinations.add,
      ),
    );

    await tester.pump();
    expect(destinations, isEmpty);

    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();

    expect(destinations, <MakerEntryDestination>[
      MakerEntryDestination.discovery,
    ]);

    await tester.pump(const Duration(milliseconds: 300));
    expect(destinations.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'animation completed early holds welcome if auth is still unresolved',
    (tester) async {
      final completer = Completer<MakerEntryDestination>();
      final destinations = <MakerEntryDestination>[];

      await tester.pumpWidget(
        app(
          autoPlay: true,
          duration: const Duration(milliseconds: 200),
          entryResolver: () => completer.future,
          onResolved: destinations.add,
        ),
      );

      await tester.pump(const Duration(milliseconds: 201));
      await tester.pump();

      expect(destinations, isEmpty);
      expect(
        tester
            .widget<Opacity>(find.byKey(const Key('ma_splash_welcome_opacity')))
            .opacity,
        1,
      );

      completer.complete(MakerEntryDestination.join);
      await tester.pump();
      await tester.pump();

      expect(destinations, <MakerEntryDestination>[MakerEntryDestination.join]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('splash is safe at compact phone size', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());

    final image = tester.widget<Image>(find.byKey(const Key('ma_splash_logo')));

    expect(image.fit, BoxFit.contain);
    expect(find.byKey(const Key('ma_splash_dot_pattern')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

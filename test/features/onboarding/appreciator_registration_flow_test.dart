import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/features/auth/data/experience_switch_repository.dart';
import 'package:ma_motion_mobile/features/auth/domain/maker_entry_destination.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/appreciator_registration_flow_screen.dart';

void main() {
  Widget app({
    int initialStep = 0,
    VoidCallback? onExit,
    ValueChanged<MakerEntryDestination>? onSwitchToMaker,
    ExperienceSwitchRepositoryContract? switchRepository,
    double keyboardInset = 0,
  }) {
    final flow = AppreciatorRegistrationFlowScreen(
      key: ValueKey<int>(initialStep),
      initialStep: initialStep,
      onExit: onExit ?? () {},
      onSwitchToMaker: onSwitchToMaker,
    );

    return ProviderScope(
      overrides: [
        if (switchRepository != null)
          experienceSwitchRepositoryProvider.overrideWithValue(
            switchRepository,
          ),
      ],
      child: MaterialApp(
        home: keyboardInset > 0
            ? MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 844),
                  viewInsets: EdgeInsets.only(bottom: keyboardInset),
                ),
                child: flow,
              )
            : flow,
      ),
    );
  }

  testWidgets('Appreciator flow starts with name and three progress dots', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.byKey(const Key('appreciator_name_field')), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      expect(find.byKey(Key('maker_step_dot_$index')), findsOneWidget);
    }

    expect(find.byKey(const Key('maker_step_dot_3')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Appreciator name and location validate and advance', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pump();
    expect(find.byKey(const Key('maker_validation_message')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('appreciator_name_field')),
      'Art Lover',
    );
    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('Where are you based?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('appreciator_location_field')),
      'Chicago 60601',
    );
    await tester.tap(find.byKey(const Key('maker_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email Address'), findsOneWidget);
    expect(find.byKey(const Key('appreciator_email_field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back from first Appreciator step returns to role selection', (
    tester,
  ) async {
    var exited = false;

    await tester.pumpWidget(app(onExit: () => exited = true));
    await tester.tap(find.byKey(const Key('maker_back_button')));
    await tester.pump();

    expect(exited, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Appreciator Next and Back remain visible while keyboard is open',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const keyboardInset = 320.0;

      await tester.pumpWidget(
        app(initialStep: 2, keyboardInset: keyboardInset),
      );
      await tester.pump();

      final footer = find.byKey(const Key('maker_onboarding_footer'));
      final next = find.byKey(const Key('maker_next_button'));
      final back = find.byKey(const Key('maker_back_button'));

      expect(footer, findsOneWidget);
      expect(next.hitTestable(), findsOneWidget);
      expect(back.hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('maker_step_dot_0')), findsNothing);

      final footerRect = tester.getRect(footer);
      expect(footerRect.bottom, lessThanOrEqualTo(844 - keyboardInset));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Email step shows small dark-grey underlined Switch to Maker action',
    (tester) async {
      final repository = _FakeExperienceSwitchRepository(
        MakerEntryDestination.discovery,
      );
      MakerEntryDestination? destination;

      await tester.pumpWidget(
        app(
          initialStep: 2,
          switchRepository: repository,
          onSwitchToMaker: (value) {
            destination = value;
          },
        ),
      );

      final switchFinder = find.byKey(const Key('appreciator_switch_maker'));
      expect(switchFinder, findsOneWidget);

      final text = tester.widget<Text>(
        find.descendant(
          of: switchFinder,
          matching: find.text('Switch to Maker'),
        ),
      );
      expect(text.style?.fontSize, 12);
      expect(text.style?.color, AppColors.darkGray);
      expect(text.style?.decoration, TextDecoration.underline);

      await Scrollable.ensureVisible(
        tester.element(switchFinder),
        alignment: 0.35,
        duration: Duration.zero,
      );
      await tester.pump();

      expect(switchFinder.hitTestable(), findsOneWidget);
      await tester.tap(switchFinder.hitTestable());
      await tester.pumpAndSettle();

      expect(repository.makerCalls, 1);
      expect(destination, MakerEntryDestination.discovery);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeExperienceSwitchRepository
    implements ExperienceSwitchRepositoryContract {
  _FakeExperienceSwitchRepository(this.destination);

  final MakerEntryDestination destination;
  int makerCalls = 0;

  @override
  Future<MakerEntryDestination> switchToAppreciator() async =>
      MakerEntryDestination.appreciatorDiscovery;

  @override
  Future<MakerEntryDestination> switchToMaker() async {
    makerCalls++;
    return destination;
  }
}

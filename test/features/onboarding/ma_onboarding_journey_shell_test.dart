import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/widgets/ma_dotted_background.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/screens/ma_role_selection_screen.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_onboarding_journey_shell.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_onboarding_scaffold.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_role_selection_wandering_dots.dart';

void main() {
  testWidgets(
    'role selection and onboarding share one persistent background surface',
    (tester) async {
      Widget app({required String location, required Widget child}) {
        return MaterialApp(
          home: MaOnboardingJourneyShell(location: location, child: child),
        );
      }

      await tester.pumpWidget(
        app(
          location: '/join',
          child: MaRoleSelectionScreen(
            onMaker: () {},
            onAppreciator: () {},
          ),
        ),
      );

      expect(
        find.byKey(const Key('onboarding_journey_shell')),
        findsOneWidget,
      );
      expect(find.byType(MaDottedBackground), findsOneWidget);
      expect(find.byType(MaRoleSelectionWanderingDots), findsOneWidget);

      final roleScaffold = tester.widget<Scaffold>(
        find.byKey(const Key('role_selection_screen')),
      );
      expect(roleScaffold.backgroundColor, Colors.transparent);

      final backgroundElement = tester.element(
        find.byType(MaDottedBackground),
      );

      await tester.pumpWidget(
        app(
          location: '/maker-registration',
          child: MaOnboardingScaffold(
            heading: "What's your name or studio name?",
            subtitle: "This is how you'll appear to others",
            currentStep: 0,
            totalSteps: 7,
            onNext: () {},
            onBack: () {},
            child: const SizedBox(height: 48),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MaDottedBackground), findsOneWidget);
      expect(
        identical(
          backgroundElement,
          tester.element(find.byType(MaDottedBackground)),
        ),
        isTrue,
      );

      final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
      expect(scaffolds.length, 2);
      expect(
        scaffolds.where((scaffold) => scaffold.backgroundColor == Colors.transparent),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

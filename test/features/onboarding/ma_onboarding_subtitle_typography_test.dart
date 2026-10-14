import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/theme/app_colors.dart';
import 'package:ma_motion_mobile/core/theme/app_text_styles.dart';
import 'package:ma_motion_mobile/features/onboarding/presentation/widgets/ma_onboarding_scaffold.dart';

void main() {
  testWidgets('onboarding subtitle uses Instrument Sans at 60% white', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MaOnboardingScaffold(
          heading: 'Heading',
          subtitle: "This is how you'll appear to others",
          currentStep: 0,
          totalSteps: 3,
          onNext: () {},
          onBack: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    final subtitle = tester.widget<Text>(
      find.byKey(const Key('maker_step_subtitle')),
    );

    expect(subtitle.style?.fontFamily, AppTextStyles.bodyFontFamily);
    expect(subtitle.style?.fontSize, 14);
    expect(subtitle.style?.letterSpacing, 0);
    expect(subtitle.style?.color, AppColors.white.withValues(alpha: 0.60));
  });
}

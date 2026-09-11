import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import 'ma_onboarding_button.dart';
import 'ma_step_dots.dart';

class MaOnboardingScaffold extends StatelessWidget {
  const MaOnboardingScaffold({
    super.key,
    required this.heading,
    required this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    required this.child,
    required this.onNext,
    required this.onBack,
    this.validationMessage,
  });

  final String heading;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MaDottedBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  final buttonHorizontalPadding = width < 360 ? 20.0 : 50.0;

                  // Keep the progress dots visually about 50 logical pixels
                  // from the physical bottom of the display while still
                  // respecting gesture/navigation safe-area insets.
                  final mediaQuery = MediaQuery.of(context);
                  final deviceBottomInset = mediaQuery.viewPadding.bottom;
                  final keyboardOpen = mediaQuery.viewInsets.bottom > 0;

                  final dotsBottomGap = keyboardOpen
                      ? 12.0
                      : math.max(16.0, 50.0 - deviceBottomInset);

                  final topGap = height < 650
                      ? 36.0
                      : math.min(180.0, height * 0.20);

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(20, topGap, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                heading,
                                key: const Key('maker_step_heading'),
                                style: AppTextStyles.onboardingHeading,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: AppTextStyles.onboardingHelper,
                              ),
                              const SizedBox(height: 30),
                              child,
                              if (validationMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  validationMessage!,
                                  key: const Key('maker_validation_message'),
                                  style: AppTextStyles.error,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: buttonHorizontalPadding,
                        ),
                        child: Column(
                          children: [
                            MaOnboardingButton(
                              key: const Key('maker_next_button'),
                              label: 'Next',
                              onPressed: onNext,
                            ),
                            const SizedBox(height: 14),
                            MaOnboardingButton(
                              key: const Key('maker_back_button'),
                              label: 'Back',
                              onPressed: onBack,
                              filled: false,
                            ),
                            const SizedBox(height: 30),
                            MaStepDots(
                              currentStep: currentStep,
                              totalSteps: totalSteps,
                            ),
                            SizedBox(
                              key: const Key('maker_dots_bottom_gap'),
                              height: dotsBottomGap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

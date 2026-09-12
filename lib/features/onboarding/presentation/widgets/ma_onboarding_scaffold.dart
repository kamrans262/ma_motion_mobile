import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import 'ma_onboarding_button.dart';
import 'ma_step_dots.dart';

/// Shared frame for the seven Maker profile-onboarding screens.
///
/// The geometry follows the supplied MA Motion registration references:
/// content begins around 25.6% down the viewport, controls use 20px side
/// gutters, and the Next / Back / progress footer stays anchored near the
/// bottom. The body remains scrollable so the same composition survives
/// compact Android devices and the on-screen keyboard.
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
    this.isBusy = false,
    this.contentTopFraction = 0.256,
    this.childGap = 18,
  });

  final String heading;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String? validationMessage;
  final bool isBusy;

  /// Fraction of the full viewport where the title begins.
  ///
  /// The dense Type / Style reference starts slightly higher than the other
  /// registration screens, so that screen overrides this value.
  final double contentTopFraction;

  /// Vertical gap between helper copy and the screen-specific control.
  final double childGap;

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
            LayoutBuilder(
              builder: (context, constraints) {
                final media = MediaQuery.of(context);
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final keyboardOpen = media.viewInsets.bottom > 0;

                final contentTop = math.max(
                  media.padding.top + 24,
                  height * contentTopFraction,
                );

                final footerHorizontal = (width * 0.1145).clamp(20.0, 50.0);
                final dotsBottomGap = math.max(
                  media.padding.bottom + 12,
                  height * 0.0557,
                );

                // Reference footer geometry at 390x844:
                // Next 46px, 13px gap, Back 46px, 26px gap, 8px dots.
                final footerReserve = keyboardOpen
                    ? 24.0
                    : dotsBottomGap + 46 + 13 + 46 + 26 + 8 + 24;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    SingleChildScrollView(
                      key: const Key('maker_onboarding_scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        contentTop,
                        20,
                        footerReserve,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            key: const Key('maker_step_heading'),
                            style: AppTextStyles.onboardingHeading,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: AppTextStyles.onboardingHelper,
                          ),
                          SizedBox(height: childGap),
                          child,
                          if (validationMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              validationMessage!,
                              key: const Key('maker_validation_message'),
                              style: AppTextStyles.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!keyboardOpen)
                      Positioned(
                        left: footerHorizontal,
                        right: footerHorizontal,
                        bottom: dotsBottomGap,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MaOnboardingButton(
                              key: const Key('maker_next_button'),
                              label: isBusy ? 'Saving...' : 'Next',
                              onPressed: isBusy ? null : onNext,
                            ),
                            const SizedBox(height: 13),
                            MaOnboardingButton(
                              key: const Key('maker_back_button'),
                              label: 'Back',
                              onPressed: isBusy ? null : onBack,
                              filled: false,
                            ),
                            const SizedBox(height: 26),
                            MaStepDots(
                              currentStep: currentStep,
                              totalSteps: totalSteps,
                            ),
                            SizedBox(
                              key: const Key('maker_dots_bottom_gap'),
                              height: 0,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

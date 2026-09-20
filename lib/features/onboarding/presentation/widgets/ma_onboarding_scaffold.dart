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
    this.headingStyle,
    this.isBusy = false,
    this.contentTopWidthFactor = 0.555,
    this.childGap = 20,
    this.contentBottom = 36,
  });

  final String heading;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final String? validationMessage;
  final TextStyle? headingStyle;
  final bool isBusy;
  final double contentTopWidthFactor;
  final double childGap;
  final double contentBottom;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MaDottedBackground(),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final media = MediaQuery.of(context);
                  final width = constraints.maxWidth;

                  final contentTop = math.max(
                    18.0,
                    (width * contentTopWidthFactor) - media.padding.top,
                  );
                  final resolvedContentBottom = keyboardOpen
                      ? media.viewInsets.bottom + 20
                      : math.max(20.0, contentBottom);

                  final footerHorizontal = (width * 0.116)
                      .clamp(24.0, 50.0)
                      .toDouble();
                  final dotsBottomGap = math.max(
                    50.0,
                    media.padding.bottom + 20,
                  );

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const Key('maker_onboarding_scroll'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            contentTop,
                            20,
                            resolvedContentBottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                heading,
                                key: const Key('maker_step_heading'),
                                style:
                                    headingStyle ??
                                    AppTextStyles.onboardingHeading.copyWith(
                                      fontSize: 32,
                                      letterSpacing: -0.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                key: const Key('maker_step_subtitle'),
                                style: AppTextStyles.onboardingHelper,
                              ),
                              SizedBox(height: childGap),
                              child,
                              if (validationMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  validationMessage!,
                                  key: const Key('maker_validation_message'),
                                  style: AppTextStyles.onboardingError,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        key: const Key('maker_onboarding_footer'),
                        padding: EdgeInsets.symmetric(
                          horizontal: footerHorizontal,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MaOnboardingButton(
                              key: const Key('maker_next_button'),
                              label: isBusy ? 'Saving...' : 'Next',
                              onPressed: isBusy ? null : onNext,
                              filled: false,
                              height: 53,
                            ),
                            const SizedBox(height: 13),
                            MaOnboardingButton(
                              key: const Key('maker_back_button'),
                              label: 'Back',
                              onPressed: isBusy ? null : onBack,
                              filled: false,
                              subdued: true,
                              height: 53,
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

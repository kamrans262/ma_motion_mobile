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
    this.isBusy = false,
    this.contentTopWidthFactor = 0.555,
    this.childGap = 20,
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
  final double contentTopWidthFactor;
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
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final media = MediaQuery.of(context);
                  final width = constraints.maxWidth;
                  final keyboardOpen = media.viewInsets.bottom > 0;

                  final contentTop = math.max(
                    18.0,
                    (width * contentTopWidthFactor) - media.padding.top,
                  );

                  final footerHorizontal = (width * 0.116)
                      .clamp(24.0, 50.0)
                      .toDouble();

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
                            keyboardOpen ? 28 : 36,
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
                                  style: AppTextStyles.error,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (!keyboardOpen)
                        Padding(
                          key: const Key('maker_onboarding_footer'),
                          padding: EdgeInsets.fromLTRB(
                            footerHorizontal,
                            0,
                            footerHorizontal,
                            math.max(14, media.padding.bottom),
                          ),
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
                              const SizedBox(height: 30),
                              MaStepDots(
                                currentStep: currentStep,
                                totalSteps: totalSteps,
                              ),
                              const SizedBox(
                                key: Key('maker_dots_bottom_gap'),
                                height: 20,
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

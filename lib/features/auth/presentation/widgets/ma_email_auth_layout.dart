import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../onboarding/presentation/widgets/ma_onboarding_button.dart';

/// The existing onboarding geometry, without changing the shared onboarding
/// scaffold or adding progress dots to Login and OTP.
class MaEmailAuthLayout extends StatelessWidget {
  const MaEmailAuthLayout({
    super.key,
    required this.screenKey,
    required this.background,
    required this.heading,
    required this.subtitle,
    required this.content,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.primaryKey,
    required this.secondaryKey,
    this.headingKey,
    this.belowSecondary,
    this.secondaryFilled = false,
    this.secondarySubdued = true,
  });

  final Key screenKey;
  final Widget background;
  final String heading;
  final String subtitle;
  final Widget content;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final Key primaryKey;
  final Key secondaryKey;
  final Key? headingKey;
  final Widget? belowSecondary;
  final bool secondaryFilled;
  final bool secondarySubdued;

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
        key: screenKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            background,
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final media = MediaQuery.of(context);
                  final width = constraints.maxWidth;
                  final contentTop = math.max(
                    18.0,
                    (width * 0.555) - media.padding.top,
                  );
                  final contentBottom = keyboardOpen
                      ? media.viewInsets.bottom + 20
                      : 36.0;
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
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            contentTop,
                            20,
                            contentBottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                heading,
                                key: headingKey,
                                style: AppTextStyles.onboardingHeading,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: AppTextStyles.onboardingHelper,
                              ),
                              const SizedBox(height: 20),
                              content,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: footerHorizontal,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MaOnboardingButton(
                              key: primaryKey,
                              label: primaryLabel,
                              onPressed: onPrimary,
                              filled: false,
                              height: 53,
                            ),
                            const SizedBox(height: 13),
                            MaOnboardingButton(
                              key: secondaryKey,
                              label: secondaryLabel,
                              onPressed: onSecondary,
                              filled: secondaryFilled,
                              subdued: !secondaryFilled && secondarySubdued,
                              height: 53,
                            ),
                            if (belowSecondary != null) ...[
                              const SizedBox(height: 20),
                              belowSecondary!,
                            ],
                            // Keep the OTP footer unchanged; the Login screen
                            // has legal copy and needs less empty space below it.
                            const SizedBox(height: 38),
                            SizedBox(
                              height: belowSecondary == null
                                  ? dotsBottomGap
                                  : math.max(24.0, media.padding.bottom + 12),
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

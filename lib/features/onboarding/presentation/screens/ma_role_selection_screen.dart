import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/ma_dotted_background.dart';

class MaRoleSelectionScreen extends StatelessWidget {
  const MaRoleSelectionScreen({
    super.key,
    required this.onMaker,
    required this.onAppreciator,
  });

  final VoidCallback onMaker;
  final VoidCallback onAppreciator;

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
        key: const Key('role_selection_screen'),
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MaDottedBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth < 360 ? 20.0 : 50.0;

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Would you like to\njoin as a Maker or\nAppreciator?',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.onboardingHeading.copyWith(
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    key: const Key('select_maker_button'),
                                    onPressed: onMaker,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.black,
                                      shape: const RoundedRectangleBorder(),
                                    ),
                                    child: Text(
                                      'Maker',
                                      style: AppTextStyles.buttonDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                flex: 5,
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    key: const Key('select_appreciator_button'),
                                    onPressed: onAppreciator,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.2,
                                      ),
                                      shape: const RoundedRectangleBorder(),
                                    ),
                                    child: Text(
                                      'Appreciator',
                                      maxLines: 1,
                                      style: AppTextStyles.buttonPurple,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

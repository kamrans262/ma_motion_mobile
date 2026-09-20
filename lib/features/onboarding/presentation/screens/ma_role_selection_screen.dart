import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_button_styles.dart';
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
                  final horizontal = constraints.maxWidth < 360 ? 20.0 : 28.0;
                  final buttonGap = constraints.maxWidth < 360 ? 12.0 : 16.0;
                  const roleFontSize = 22.0;

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Would you like to\njoin as a Maker or\nAppreciator?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 32,
                              letterSpacing: -0.3,
                              height: 1.18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: buttonGap,
                            runSpacing: buttonGap,
                            children: [
                              OutlinedButton(
                                key: const Key('select_maker_button'),
                                onPressed: onMaker,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.splashBackground,
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    18,
                                    32,
                                    14,
                                  ),
                                  shape: const RoundedRectangleBorder(),
                                ).copyWith(
                                  backgroundColor:
                                      AppButtonStyles.purpleWhenPressed(
                                    AppColors.splashBackground,
                                  ),
                                  foregroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (states) => states.contains(
                                      WidgetState.pressed,
                                    )
                                        ? AppColors.white
                                        : AppColors.primary,
                                  ),
                                ),
                                child: const Text(
                                  'Maker',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: roleFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              OutlinedButton(
                                key: const Key('select_appreciator_button'),
                                onPressed: onAppreciator,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.splashBackground,
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    18,
                                    32,
                                    14,
                                  ),
                                  shape: const RoundedRectangleBorder(),
                                ).copyWith(
                                  backgroundColor:
                                      AppButtonStyles.purpleWhenPressed(
                                    AppColors.splashBackground,
                                  ),
                                  foregroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (states) => states.contains(
                                      WidgetState.pressed,
                                    )
                                        ? AppColors.white
                                        : AppColors.primary,
                                  ),
                                ),
                                child: const Text(
                                  'Appreciator',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.fontFamily,
                                    fontSize: roleFontSize,
                                    fontWeight: FontWeight.w500,
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

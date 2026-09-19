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
                  final horizontal = constraints.maxWidth < 360 ? 20.0 : 28.0;
                  final buttonGap = constraints.maxWidth < 360 ? 12.0 : 16.0;
                  final buttonWidth =
                      ((constraints.maxWidth - horizontal * 2 - buttonGap) / 2)
                          .clamp(0.0, 154.0)
                          .toDouble();
                  final roleFontSize =
                      constraints.maxWidth < 360 ? 24.0 : 26.0;

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
                              height: 1.18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: buttonWidth,
                                height: 76,
                                child: OutlinedButton(
                                  key: const Key('select_maker_button'),
                                  onPressed: onMaker,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.splashBackground,
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    shape: const RoundedRectangleBorder(),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Maker',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: roleFontSize,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: buttonGap),
                              SizedBox(
                                width: buttonWidth,
                                height: 76,
                                child: OutlinedButton(
                                  key: const Key('select_appreciator_button'),
                                  onPressed: onAppreciator,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.splashBackground,
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    shape: const RoundedRectangleBorder(),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Appreciator',
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: roleFontSize,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
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

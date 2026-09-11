import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MaStepDots extends StatelessWidget {
  const MaStepDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${currentStep + 1} of $totalSteps',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              key: Key('maker_step_dot_$index'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.splashDot,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

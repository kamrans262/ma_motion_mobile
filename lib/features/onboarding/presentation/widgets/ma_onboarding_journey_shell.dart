import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ma_dotted_background.dart';
import 'ma_role_selection_wandering_dots.dart';

class MaOnboardingJourneyShell extends StatefulWidget {
  const MaOnboardingJourneyShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  State<MaOnboardingJourneyShell> createState() =>
      _MaOnboardingJourneyShellState();
}

class _MaOnboardingJourneyShellState extends State<MaOnboardingJourneyShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wanderingController;

  bool _usesWanderingDots(String location) =>
      location == '/login' || location == '/join';

  @override
  void initState() {
    super.initState();
    _wanderingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    if (_usesWanderingDots(widget.location)) {
      _wanderingController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MaOnboardingJourneyShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasWandering = _usesWanderingDots(oldWidget.location);
    final isWandering = _usesWanderingDots(widget.location);

    if (!wasWandering && isWandering) {
      _wanderingController
        ..value = 0
        ..forward();
    } else if (wasWandering && !isWandering) {
      _wanderingController.stop();
    }
  }

  @override
  void dispose() {
    _wanderingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wandering = _usesWanderingDots(widget.location);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.splashBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: const Key('onboarding_journey_shell'),
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.splashBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MaDottedBackground(),
            IgnorePointer(
              child: AnimatedOpacity(
                key: const Key('onboarding_journey_wandering_layer'),
                opacity: wandering ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: ColoredBox(
                  color: AppColors.splashBackground,
                  child: MaRoleSelectionWanderingDots(
                    progress: _wanderingController,
                  ),
                ),
              ),
            ),
            MaOnboardingJourneyScope(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class MaOnboardingJourneyScope extends InheritedWidget {
  const MaOnboardingJourneyScope({super.key, required super.child});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MaOnboardingJourneyScope>() !=
      null;

  @override
  bool updateShouldNotify(MaOnboardingJourneyScope oldWidget) => false;
}

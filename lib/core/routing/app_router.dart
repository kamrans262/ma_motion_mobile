import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/presentation/screens/ma_role_selection_screen.dart';
import '../../features/onboarding/presentation/screens/maker_registration_flow_screen.dart';
import '../../features/splash/presentation/screens/ma_splash_sequence_screen.dart';

GoRouter createAppRouter({
  required bool splashAutoPlay,
  required Duration splashDuration,
}) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => MaSplashSequenceScreen(
          autoPlay: splashAutoPlay,
          duration: splashDuration,
          onFinished: () {
            // Navigation is scheduled after the animation frame completes.
            // This avoids mutating the router from inside an animation status
            // notification while the frame is being finalized.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.go('/join');
              }
            });
          },
        ),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => MaRoleSelectionScreen(
          onMaker: () => context.go('/maker-registration'),
          onAppreciator: () {
            // Appreciator flow is intentionally separate and will be wired
            // when its supplied Figma screens are implemented.
          },
        ),
      ),
      GoRoute(
        path: '/maker-registration',
        builder: (context, state) =>
            MakerRegistrationFlowScreen(onExit: () => context.go('/join')),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text(state.error?.toString() ?? 'Navigation error'),
        ),
      );
    },
  );
}

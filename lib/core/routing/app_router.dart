import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/maker_entry_destination.dart';
import '../../features/auth/presentation/screens/maker_auth_screen.dart';
import '../../features/auth/presentation/screens/maker_session_gate_screen.dart';
import '../../features/discovery/presentation/screens/discovery_filter_screen.dart';
import '../../features/discovery/presentation/screens/discovery_search_screen.dart';
import '../../features/discovery/presentation/screens/maker_artwork_discovery_screen.dart';
import '../../features/onboarding/presentation/screens/ma_role_selection_screen.dart';
import '../../features/onboarding/presentation/screens/maker_registration_flow_screen.dart';
import '../../features/splash/presentation/screens/ma_splash_sequence_screen.dart';

GoRouter createAppRouter({
  required bool splashAutoPlay,
  required Duration splashDuration,
}) {
  void goForMakerEntry(
    BuildContext context,
    MakerEntryDestination destination,
  ) {
    switch (destination) {
      case MakerEntryDestination.join:
        context.go('/join');
      case MakerEntryDestination.profileSetup:
        context.go('/maker-registration');
      case MakerEntryDestination.discovery:
        context.go('/maker/discovery');
    }
  }

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => MaSplashSequenceScreen(
          autoPlay: splashAutoPlay,
          duration: splashDuration,
          onFinished: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/session-gate');
            });
          },
        ),
      ),
      GoRoute(
        path: '/session-gate',
        builder: (context, state) => MakerSessionGateScreen(
          onResolved: (destination) {
            if (context.mounted) {
              goForMakerEntry(context, destination);
            }
          },
        ),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => MaRoleSelectionScreen(
          onMaker: () => context.go('/maker-auth'),
          onAppreciator: () {},
        ),
      ),
      GoRoute(
        path: '/maker-auth',
        builder: (context, state) => MakerAuthScreen(
          onBack: () => context.go('/join'),
          onAuthenticated: (destination) {
            goForMakerEntry(context, destination);
          },
        ),
      ),
      GoRoute(
        path: '/maker-registration',
        builder: (context, state) => MakerRegistrationFlowScreen(
          onExit: () => context.go('/join'),
          onCompleted: () => context.go('/maker/discovery'),
        ),
      ),
      GoRoute(
        path: '/maker/discovery',
        builder: (context, state) => MakerArtworkDiscoveryScreen(
          onSearchTap: () => context.push('/maker/discovery/search'),
          onFilterTap: () => context.push('/maker/discovery/filter'),
        ),
      ),
      GoRoute(
        path: '/maker/discovery/search',
        builder: (context, state) => DiscoverySearchScreen(
          onBack: () => context.pop(),
          onFilterTap: () => context.push('/maker/discovery/filter'),
        ),
      ),
      GoRoute(
        path: '/maker/discovery/filter',
        builder: (context, state) => DiscoveryFilterScreen(
          onClose: () => context.pop(),
          onApplied: () => context.pop(),
        ),
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

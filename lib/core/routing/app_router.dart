import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/artwork_viewer/presentation/screens/artwork_viewer_screen.dart';
import '../../features/auth/domain/maker_entry_destination.dart';
import '../../features/auth/presentation/screens/maker_auth_screen.dart';
import '../../features/auth/presentation/screens/maker_session_gate_screen.dart';
import '../../features/discovery/presentation/screens/discovery_filter_screen.dart';
import '../../features/discovery/presentation/screens/discovery_search_screen.dart';
import '../../features/discovery/presentation/screens/maker_artwork_discovery_screen.dart';
import '../providers/core_providers.dart';
import '../../features/onboarding/application/maker_registration_controller.dart';
import '../../features/onboarding/presentation/screens/ma_role_selection_screen.dart';
import '../../features/onboarding/presentation/screens/maker_registration_flow_screen.dart';
import '../../features/settings/presentation/screens/maker_info_settings_screen.dart';
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
          onMaker: () => context.go('/maker-registration'),
          onAppreciator: () {},
        ),
      ),
      GoRoute(
        path: '/maker-auth',
        builder: (context, state) {
          final continueRegistration =
              state.uri.queryParameters['continue'] == 'registration';

          return MakerAuthScreen(
            onBack: () {
              if (continueRegistration) {
                context.pop<MakerEntryDestination?>();
                return;
              }

              context.go('/join');
            },
            onAuthenticated: (destination) {
              if (continueRegistration) {
                context.pop(destination);
                return;
              }

              goForMakerEntry(context, destination);
            },
          );
        },
      ),
      GoRoute(
        path: '/maker-registration',
        builder: (context, state) => const _MakerRegistrationRoute(),
      ),
      GoRoute(
        path: '/maker/discovery',
        builder: (context, state) => MakerArtworkDiscoveryScreen(
          onSearchTap: () => context.push('/maker/discovery/search'),
          onFilterTap: () => context.push('/maker/discovery/filter'),
          onArtworkTap: (artwork) {
            context.push('/maker/discovery/artwork/${artwork.id}');
          },
          onBottomNavigationTap: (index) {
            if (index == 5) {
              context.push('/maker/settings');
            }
          },
        ),
      ),
      GoRoute(
        path: '/maker/discovery/search',
        builder: (context, state) => DiscoverySearchScreen(
          onBack: () => context.pop(),
          onFilterTap: () => context.push('/maker/discovery/filter'),
          onArtworkTap: (artwork) {
            context.push('/maker/discovery/artwork/${artwork.id}');
          },
        ),
      ),
      GoRoute(
        path: '/maker/discovery/filter',
        builder: (context, state) => DiscoveryFilterScreen(
          onClose: () => context.pop(),
          onApplied: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/maker/settings',
        builder: (context, state) => MakerInfoSettingsScreen(
          onClose: () => context.pop(),
          onSwitchedToAppreciator: () => context.go('/join'),
        ),
      ),
      GoRoute(
        path: '/maker/discovery/artwork/:artworkId',
        builder: (context, state) {
          final artworkId = int.tryParse(
            state.pathParameters['artworkId'] ?? '',
          );

          if (artworkId == null) {
            return const Scaffold(body: Center(child: Text('Invalid artwork')));
          }

          return ArtworkViewerScreen(
            artworkId: artworkId,
            onClose: () => context.pop(),
          );
        },
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

class _MakerRegistrationRoute extends ConsumerWidget {
  const _MakerRegistrationRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MakerRegistrationFlowScreen(
      onExit: () => context.go('/join'),
      onCompleted: () => context.go('/maker/discovery'),
      ensureAuthenticated: () async {
        try {
          final session = await ref
              .read(authRepositoryProvider)
              .restoreSession();

          if (session != null && session.user.isMaker) {
            return true;
          }
        } catch (_) {
          // Fall through to the existing Maker authentication screen.
        }

        if (!context.mounted) {
          return false;
        }

        final destination = await context.push<MakerEntryDestination?>(
          '/maker-auth?continue=registration',
        );

        if (!context.mounted) {
          return false;
        }

        if (destination == MakerEntryDestination.discovery) {
          ref.read(makerRegistrationProvider.notifier).reset();
          context.go('/maker/discovery');
          return false;
        }

        return destination == MakerEntryDestination.profileSetup;
      },
    );
  }
}

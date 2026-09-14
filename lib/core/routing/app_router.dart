import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/artwork_viewer/presentation/screens/artwork_viewer_screen.dart';
import '../../features/auth/domain/maker_entry_destination.dart';
import '../../features/discovery/domain/discovery_artwork.dart';
import '../../features/discovery/presentation/screens/appreciator_artwork_discovery_screen.dart';
import '../../features/discovery/presentation/screens/discovery_filter_screen.dart';
import '../../features/discovery/presentation/screens/maker_artwork_discovery_screen.dart';
import '../../features/onboarding/presentation/screens/appreciator_registration_flow_screen.dart';
import '../../features/onboarding/presentation/screens/ma_role_selection_screen.dart';
import '../../features/onboarding/presentation/screens/maker_registration_flow_screen.dart';
import '../../features/saved_artworks/presentation/screens/maker_saved_artworks_screen.dart';
import '../../features/settings/presentation/screens/maker_info_settings_screen.dart';
import '../../features/settings/presentation/widgets/appreciator_settings_modal.dart';
import '../../features/splash/presentation/screens/ma_splash_sequence_screen.dart';

const _premiumTransitionDuration = Duration(milliseconds: 300);
const _premiumReverseTransitionDuration = Duration(milliseconds: 240);

CustomTransitionPage<void> _premiumPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: _premiumTransitionDuration,
    reverseTransitionDuration: _premiumReverseTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;

      if (disableAnimations) {
        return child;
      }

      final primary = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final secondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final incomingOffset = Tween<Offset>(
        begin: const Offset(0.018, 0),
        end: Offset.zero,
      ).animate(primary);
      final incomingScale = Tween<double>(
        begin: 0.992,
        end: 1,
      ).animate(primary);
      final outgoingScale = Tween<double>(
        begin: 1,
        end: 0.996,
      ).animate(secondary);
      final outgoingOpacity = Tween<double>(
        begin: 1,
        end: 0.985,
      ).animate(secondary);

      return FadeTransition(
        opacity: outgoingOpacity,
        child: ScaleTransition(
          scale: outgoingScale,
          child: FadeTransition(
            opacity: primary,
            child: SlideTransition(
              position: incomingOffset,
              child: ScaleTransition(
                scale: incomingScale,
                alignment: Alignment.center,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
    child: child,
  );
}

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
      case MakerEntryDestination.appreciatorProfileSetup:
        context.go('/appreciator-registration');
      case MakerEntryDestination.appreciatorDiscovery:
        context.go('/appreciator/discovery');
    }
  }

  Future<void> openAppreciatorSettings(BuildContext context) async {
    final destination = await showAppreciatorSettingsModal(context);

    if (!context.mounted || destination == null) {
      return;
    }

    goForMakerEntry(context, destination);
  }

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => MaSplashSequenceScreen(
          autoPlay: splashAutoPlay,
          duration: splashDuration,
          onResolved: (destination) {
            if (context.mounted) {
              goForMakerEntry(context, destination);
            }
          },
        ),
      ),
      GoRoute(
        path: '/join',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: MaRoleSelectionScreen(
            onMaker: () => context.go('/maker-registration'),
            onAppreciator: () => context.go('/appreciator-registration'),
          ),
        ),
      ),
      GoRoute(
        path: '/maker-registration',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: MakerRegistrationFlowScreen(
            onExit: () => context.go('/join'),
            onCompleted: () => context.go('/maker/discovery'),
          ),
        ),
      ),
      GoRoute(
        path: '/appreciator-registration',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: AppreciatorRegistrationFlowScreen(
            onExit: () => context.go('/join'),
            onCompleted: () => context.go('/appreciator/discovery'),
            onSwitchToMaker: (destination) {
              goForMakerEntry(context, destination);
            },
          ),
        ),
      ),
      GoRoute(
        path: '/appreciator/discovery',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: AppreciatorArtworkDiscoveryScreen(
            onFilterTap: () => context.push('/appreciator/discovery/filter'),
            onSavedTap: () => context.push('/appreciator/saved-artworks'),
            onMakerDestination: (destination) {
              goForMakerEntry(context, destination);
            },
            onArtworkTap: (artwork) {
              final url = artwork.primaryMedia?.url.trim() ?? '';
              if (url.isNotEmpty && artwork.primaryMedia?.isVideo != true) {
                precacheImage(NetworkImage(url), context);
              }
              context.push(
                '/appreciator/discovery/artwork/${artwork.id}',
                extra: artwork,
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/appreciator/saved-artworks',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: MakerSavedArtworksScreen(
            onBack: () => context.pop(),
            onSettingsTap: () => unawaited(openAppreciatorSettings(context)),
            onArtworkTap: (artwork) {
              final url = artwork.primaryMedia?.url.trim() ?? '';
              if (url.isNotEmpty && artwork.primaryMedia?.isVideo != true) {
                precacheImage(NetworkImage(url), context);
              }
              context.push(
                '/appreciator/discovery/artwork/${artwork.id}',
                extra: artwork,
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/appreciator/discovery/filter',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: DiscoveryFilterScreen(
            onClose: () => context.pop(),
            onApplied: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: '/appreciator/discovery/artwork/:artworkId',
        pageBuilder: (context, state) {
          final artworkId = int.tryParse(
            state.pathParameters['artworkId'] ?? '',
          );

          if (artworkId == null) {
            return _premiumPage(
              state: state,
              child: const Scaffold(
                body: Center(child: Text('Invalid artwork')),
              ),
            );
          }

          return _premiumPage(
            state: state,
            child: ArtworkViewerScreen(
              artworkId: artworkId,
              initialArtwork: state.extra is DiscoveryArtwork
                  ? state.extra! as DiscoveryArtwork
                  : null,
              onClose: () => context.pop(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/maker/discovery',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: MakerArtworkDiscoveryScreen(
            onFilterTap: () => context.push('/maker/discovery/filter'),
            onSavedTap: () => context.push('/maker/saved-artworks'),
            onSettingsTap: () => context.push('/maker/settings'),
            onArtworkTap: (artwork) {
              final url = artwork.primaryMedia?.url.trim() ?? '';
              if (url.isNotEmpty && artwork.primaryMedia?.isVideo != true) {
                precacheImage(NetworkImage(url), context);
              }
              context.push(
                '/maker/discovery/artwork/${artwork.id}',
                extra: artwork,
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/maker/saved-artworks',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: MakerSavedArtworksScreen(
            onBack: () => context.pop(),
            onSettingsTap: () => context.push('/maker/settings'),
            onArtworkTap: (artwork) {
              final url = artwork.primaryMedia?.url.trim() ?? '';
              if (url.isNotEmpty && artwork.primaryMedia?.isVideo != true) {
                precacheImage(NetworkImage(url), context);
              }
              context.push(
                '/maker/discovery/artwork/${artwork.id}',
                extra: artwork,
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: '/maker/discovery/filter',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: DiscoveryFilterScreen(
            onClose: () => context.pop(),
            onApplied: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: '/maker/settings',
        pageBuilder: (context, state) => _premiumPage(
          state: state,
          child: MakerInfoSettingsScreen(
            onClose: () => context.pop(),
            onSwitchedToAppreciator: (destination) {
              goForMakerEntry(context, destination);
            },
          ),
        ),
      ),
      GoRoute(
        path: '/maker/discovery/artwork/:artworkId',
        pageBuilder: (context, state) {
          final artworkId = int.tryParse(
            state.pathParameters['artworkId'] ?? '',
          );

          if (artworkId == null) {
            return _premiumPage(
              state: state,
              child: const Scaffold(
                body: Center(child: Text('Invalid artwork')),
              ),
            );
          }

          return _premiumPage(
            state: state,
            child: ArtworkViewerScreen(
              artworkId: artworkId,
              initialArtwork: state.extra is DiscoveryArtwork
                  ? state.extra! as DiscoveryArtwork
                  : null,
              onClose: () => context.pop(),
            ),
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

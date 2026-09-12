import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/artwork_viewer/presentation/screens/artwork_viewer_screen.dart';
import '../../features/auth/domain/maker_entry_destination.dart';
import '../../features/discovery/domain/discovery_artwork.dart';
import '../../features/discovery/presentation/screens/discovery_filter_screen.dart';
import '../../features/discovery/presentation/screens/maker_artwork_discovery_screen.dart';
import '../../features/onboarding/presentation/screens/ma_role_selection_screen.dart';
import '../../features/onboarding/presentation/screens/maker_registration_flow_screen.dart';
import '../../features/saved_artworks/presentation/screens/maker_saved_artworks_screen.dart';
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
        path: '/maker-registration',
        builder: (context, state) => MakerRegistrationFlowScreen(
          onExit: () => context.go('/join'),
          onCompleted: () => context.go('/maker/discovery'),
        ),
      ),
      GoRoute(
        path: '/maker/discovery',
        builder: (context, state) => MakerArtworkDiscoveryScreen(
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
      GoRoute(
        path: '/maker/saved-artworks',
        builder: (context, state) => MakerSavedArtworksScreen(
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
            initialArtwork: state.extra is DiscoveryArtwork
                ? state.extra! as DiscoveryArtwork
                : null,
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

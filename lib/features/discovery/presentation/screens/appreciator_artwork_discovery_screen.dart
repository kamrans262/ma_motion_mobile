import 'dart:async';

import 'package:flutter/material.dart';

import '../../../auth/domain/maker_entry_destination.dart';
import '../../../settings/presentation/widgets/appreciator_settings_modal.dart';
import '../../domain/discovery_artwork.dart';
import 'maker_artwork_discovery_screen.dart';

class AppreciatorArtworkDiscoveryScreen extends StatelessWidget {
  const AppreciatorArtworkDiscoveryScreen({
    super.key,
    this.onArtworkTap,
    this.onFilterTap,
    this.onSavedTap,
    this.onMakerDestination,
  });

  final ValueChanged<DiscoveryArtwork>? onArtworkTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSavedTap;
  final ValueChanged<MakerEntryDestination>? onMakerDestination;

  Future<void> _openSettings(BuildContext context) async {
    final destination = await showAppreciatorSettingsModal(context);

    if (!context.mounted || destination == null) {
      return;
    }

    onMakerDestination?.call(destination);
  }

  @override
  Widget build(BuildContext context) {
    return MakerArtworkDiscoveryScreen(
      onArtworkTap: onArtworkTap,
      onFilterTap: onFilterTap,
      onSavedTap: onSavedTap,
      onSettingsTap: () => unawaited(_openSettings(context)),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_artworks_repository.dart';

final artworkSavedStatusProvider = FutureProvider.family<bool, int>((
  ref,
  artworkId,
) {
  return ref.watch(savedArtworksRepositoryProvider).isSaved(artworkId);
});

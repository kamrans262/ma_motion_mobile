import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/artwork_detail_repository.dart';
import '../domain/artwork_detail.dart';

final artworkDetailProvider = FutureProvider.autoDispose
    .family<ArtworkDetail, int>((ref, artworkId) {
      return ref.watch(artworkDetailRepositoryProvider).fetch(artworkId);
    });

import '../../../core/network/pagination_meta.dart';
import 'discovery_artwork.dart';

class DiscoveryArtworkPage {
  const DiscoveryArtworkPage({required this.items, required this.meta});

  final List<DiscoveryArtwork> items;
  final PaginationMeta meta;
}

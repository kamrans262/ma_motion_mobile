import '../../../core/network/pagination_meta.dart';
import 'discovery_artwork.dart';

class DiscoverySearchMakerStatistics {
  const DiscoverySearchMakerStatistics({
    this.savedCount = 0,
    this.artworkCount = 0,
    this.currentShowCount = 0,
    this.upcomingShowCount = 0,
  });

  final int savedCount;
  final int artworkCount;
  final int currentShowCount;
  final int upcomingShowCount;

  factory DiscoverySearchMakerStatistics.fromMap(Map<String, dynamic> map) {
    return DiscoverySearchMakerStatistics(
      savedCount: asInt(map['saved_count']) ?? 0,
      artworkCount: asInt(map['artwork_count']) ?? 0,
      currentShowCount: asInt(map['current_show_count']) ?? 0,
      upcomingShowCount: asInt(map['upcoming_show_count']) ?? 0,
    );
  }
}

class DiscoverySearchMaker {
  const DiscoverySearchMaker({
    required this.id,
    required this.name,
    this.bio,
    this.profileImageUrl,
    this.location,
    this.locationText,
    this.distanceKm,
    this.statistics = const DiscoverySearchMakerStatistics(),
  });

  final int id;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final DiscoveryLocation? location;
  final String? locationText;
  final double? distanceKm;
  final DiscoverySearchMakerStatistics statistics;

  factory DiscoverySearchMaker.fromMap(Map<String, dynamic> map) {
    final locationMap = mapOrNull(map['location']);
    final statisticsMap = mapOrNull(map['statistics']);

    return DiscoverySearchMaker(
      id: asInt(map['id']) ?? 0,
      name: map['name']?.toString() ?? '',
      bio: nullableString(map['bio']),
      profileImageUrl: nullableString(map['profile_image_url']),
      location: locationMap == null
          ? null
          : DiscoveryLocation.fromMap(locationMap),
      locationText: nullableString(map['location_text']),
      distanceKm: asDouble(map['distance_km']),
      statistics: statisticsMap == null
          ? const DiscoverySearchMakerStatistics()
          : DiscoverySearchMakerStatistics.fromMap(statisticsMap),
    );
  }
}

class DiscoverySearchResultPage {
  const DiscoverySearchResultPage({
    required this.artworks,
    required this.makers,
    required this.artworkMeta,
    required this.makerMeta,
  });

  final List<DiscoveryArtwork> artworks;
  final List<DiscoverySearchMaker> makers;
  final PaginationMeta artworkMeta;
  final PaginationMeta makerMeta;

  bool get hasNextPage => artworkMeta.hasNextPage || makerMeta.hasNextPage;
}

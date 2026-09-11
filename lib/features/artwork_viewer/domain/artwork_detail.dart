import '../../discovery/domain/discovery_artwork.dart';

class ArtworkDetailMaker {
  const ArtworkDetailMaker({
    required this.id,
    required this.name,
    this.bio,
    this.location,
    this.profileImageUrl,
    this.websiteUrl,
    this.contactEmail,
    this.showShowsOnInfoPage = true,
    this.savedCount = 0,
  });

  final int id;
  final String name;
  final String? bio;
  final String? location;
  final String? profileImageUrl;
  final String? websiteUrl;
  final String? contactEmail;
  final bool showShowsOnInfoPage;
  final int savedCount;

  factory ArtworkDetailMaker.fromMap(Map<String, dynamic> map) {
    return ArtworkDetailMaker(
      id: _asInt(map['id']) ?? 0,
      name: map['name']?.toString() ?? '',
      bio: _nullableString(map['bio']),
      location: _nullableString(map['location']),
      profileImageUrl: _nullableString(map['profile_image_url']),
      websiteUrl: _nullableString(map['website_url']),
      contactEmail: _nullableString(map['contact_email']),
      showShowsOnInfoPage: _asBoolDefaultTrue(
        map['show_shows_on_info_page'],
      ),
      savedCount: _asInt(map['saved_count']) ?? 0,
    );
  }
}

class ArtworkDetail {
  const ArtworkDetail({
    required this.id,
    required this.title,
    required this.media,
    this.description,
    this.primaryMedia,
    this.type,
    this.style,
    this.location,
    this.locationText,
    this.maker,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? description;
  final List<DiscoveryArtworkMedia> media;
  final DiscoveryArtworkMedia? primaryMedia;
  final DiscoveryTaxonomy? type;
  final DiscoveryTaxonomy? style;
  final DiscoveryLocation? location;
  final String? locationText;
  final ArtworkDetailMaker? maker;
  final DateTime? createdAt;

  int get viewerPageCount => (media.isEmpty ? 1 : media.length) + 1;

  factory ArtworkDetail.fromMap(Map<String, dynamic> map) {
    final primaryMediaMap = _mapOrNull(map['primary_media']);
    final typeMap = _mapOrNull(map['type']);
    final styleMap = _mapOrNull(map['style']);
    final locationMap = _mapOrNull(map['location']);
    final makerMap = _mapOrNull(map['maker']);

    final parsedMedia = _listOrEmpty(map['media'])
        .whereType<Map>()
        .map(
          (item) =>
              DiscoveryArtworkMedia.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return ArtworkDetail(
      id: _asInt(map['id']) ?? 0,
      title: map['title']?.toString() ?? '',
      description: _nullableString(map['description']),
      media: parsedMedia,
      primaryMedia: primaryMediaMap == null
          ? null
          : DiscoveryArtworkMedia.fromMap(primaryMediaMap),
      type: typeMap == null ? null : DiscoveryTaxonomy.fromMap(typeMap),
      style: styleMap == null ? null : DiscoveryTaxonomy.fromMap(styleMap),
      location: locationMap == null
          ? null
          : DiscoveryLocation.fromMap(locationMap),
      locationText: _nullableString(map['location_text']),
      maker: makerMap == null ? null : ArtworkDetailMaker.fromMap(makerMap),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

List<dynamic> _listOrEmpty(Object? value) {
  return value is List ? value : const <dynamic>[];
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

bool _asBoolDefaultTrue(Object? value) {
  if (value == null) return true;
  if (value is bool) return value;

  return value == 1 || value == '1' || value == 'true';
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

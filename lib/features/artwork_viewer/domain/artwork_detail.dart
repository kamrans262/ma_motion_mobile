import '../../discovery/domain/discovery_artwork.dart';

class ArtworkDetailMakerShow {
  const ArtworkDetailMakerShow({
    required this.description,
    required this.location,
  });

  final String description;
  final String location;

  factory ArtworkDetailMakerShow.fromMap(Map<String, dynamic> map) {
    return ArtworkDetailMakerShow(
      description: map['description']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
    );
  }
}

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
    this.currentUpcomingShows = const <ArtworkDetailMakerShow>[],
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
  final List<ArtworkDetailMakerShow> currentUpcomingShows;
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
      showShowsOnInfoPage: _asBoolDefaultTrue(map['show_shows_on_info_page']),
      currentUpcomingShows: _listOrEmpty(map['current_upcoming_shows'])
          .whereType<Map>()
          .map(
            (item) =>
                ArtworkDetailMakerShow.fromMap(Map<String, dynamic>.from(item)),
          )
          .where(
            (item) =>
                item.description.trim().isNotEmpty &&
                item.location.trim().isNotEmpty,
          )
          .toList(growable: false),
      savedCount: _asInt(map['saved_count']) ?? 0,
    );
  }
}

class ArtworkDisplayItem {
  const ArtworkDisplayItem({
    required this.slot,
    required this.id,
    required this.title,
    this.description,
    this.primaryMedia,
    this.createdAt,
    this.isSalonImage = false,
  });

  final int? slot;
  final int id;
  final String title;
  final String? description;
  final DiscoveryArtworkMedia? primaryMedia;
  final DateTime? createdAt;
  final bool isSalonImage;

  factory ArtworkDisplayItem.fromPlacementMap(Map<String, dynamic> map) {
    final artwork = _mapOrNull(map['artwork']) ?? const <String, dynamic>{};
    final primaryMediaMap = _mapOrNull(artwork['primary_media']);

    return ArtworkDisplayItem(
      slot: _asInt(map['slot']),
      id: _asInt(artwork['id']) ?? 0,
      title: artwork['title']?.toString() ?? '',
      description: _nullableString(artwork['description']),
      primaryMedia: primaryMediaMap == null
          ? null
          : DiscoveryArtworkMedia.fromMap(primaryMediaMap),
      createdAt: DateTime.tryParse(artwork['created_at']?.toString() ?? ''),
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
    this.artDisplayArtworks = const <ArtworkDisplayItem>[],
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
  final List<ArtworkDisplayItem> artDisplayArtworks;

  bool get hasSalonImage => maker?.profileImageUrl?.trim().isNotEmpty == true;

  bool get hasConfiguredDisplay =>
      hasSalonImage || artDisplayArtworks.isNotEmpty;

  int get viewerPageCount {
    if (hasConfiguredDisplay) {
      return orderedArtDisplayItems.length + 1;
    }

    return (media.isEmpty ? 1 : media.length) + 1;
  }

  List<ArtworkDisplayItem> get orderedArtDisplayItems {
    int? selectedSlot;
    for (final item in artDisplayArtworks) {
      if (item.id == id) {
        selectedSlot = item.slot;
        break;
      }
    }

    final selected = ArtworkDisplayItem(
      slot: selectedSlot,
      id: id,
      title: title,
      description: description,
      primaryMedia: primaryMedia ?? (media.isEmpty ? null : media.first),
      createdAt: createdAt,
    );

    final orderedSlots = [...artDisplayArtworks]
      ..sort((a, b) => (a.slot ?? 999).compareTo(b.slot ?? 999));

    final ordered = <ArtworkDisplayItem>[];

    final salonUrl = maker?.profileImageUrl?.trim() ?? '';
    if (salonUrl.isNotEmpty) {
      final salonId = -((maker?.id ?? 0) + 1);
      ordered.add(
        ArtworkDisplayItem(
          slot: 1,
          id: salonId,
          title: 'Salon Image',
          isSalonImage: true,
          primaryMedia: DiscoveryArtworkMedia(
            id: salonId,
            kind: 'image',
            url: salonUrl,
            isPrimary: true,
          ),
        ),
      );
    }

    ordered.add(selected);
    ordered.addAll(orderedSlots.where((item) => item.id != id));

    return ordered;
  }

  factory ArtworkDetail.fromDiscovery(DiscoveryArtwork artwork) {
    final preview = artwork.maker;

    return ArtworkDetail(
      id: artwork.id,
      title: artwork.title,
      description: artwork.description,
      media: artwork.primaryMedia == null
          ? const <DiscoveryArtworkMedia>[]
          : <DiscoveryArtworkMedia>[artwork.primaryMedia!],
      primaryMedia: artwork.primaryMedia,
      type: artwork.type,
      style: artwork.style,
      location: artwork.location,
      locationText: artwork.locationText,
      maker: preview == null
          ? null
          : ArtworkDetailMaker(
              id: preview.id,
              name: preview.name,
              bio: preview.bio,
              profileImageUrl: preview.profileImageUrl,
              savedCount: preview.savedCount,
            ),
      createdAt: artwork.createdAt,
    );
  }

  factory ArtworkDetail.fromMap(Map<String, dynamic> map) {
    final primaryMediaMap = _mapOrNull(map['primary_media']);
    final typeMap = _mapOrNull(map['type']);
    final styleMap = _mapOrNull(map['style']);
    final locationMap = _mapOrNull(map['location']);
    final makerMap = _mapOrNull(map['maker']);
    final parsedArtDisplayArtworks = _listOrEmpty(map['art_display_artworks'])
        .whereType<Map>()
        .map(
          (item) => ArtworkDisplayItem.fromPlacementMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((item) => item.id > 0)
        .toList(growable: false);

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
      artDisplayArtworks: parsedArtDisplayArtworks,
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

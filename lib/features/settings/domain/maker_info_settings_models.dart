import 'dart:typed_data';

class MakerSettingsTaxonomyOption {
  const MakerSettingsTaxonomyOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory MakerSettingsTaxonomyOption.fromMap(Map<String, dynamic> map) {
    return MakerSettingsTaxonomyOption(
      id: _asInt(map['id']) ?? 0,
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
    );
  }
}

class MakerCarouselItem {
  const MakerCarouselItem({
    required this.slot,
    required this.kind,
    this.id,
    this.url,
    this.mimeType,
    this.caption,
  });

  final int? id;
  final int slot;
  final String kind;
  final String? url;
  final String? mimeType;
  final String? caption;

  bool get isVideo {
    return kind.toLowerCase() == 'video' ||
        (mimeType?.toLowerCase().startsWith('video/') ?? false);
  }

  factory MakerCarouselItem.fromMap(Map<String, dynamic> map) {
    return MakerCarouselItem(
      id: _asInt(map['id']),
      slot: _asInt(map['slot']) ?? 0,
      kind: map['kind']?.toString() ?? 'image',
      url: _nullableString(map['url']),
      mimeType: _nullableString(map['mime_type']),
      caption: _nullableString(map['caption']),
    );
  }
}

class MakerSettingsArtworkMedia {
  const MakerSettingsArtworkMedia({
    required this.id,
    required this.url,
    required this.isPrimary,
    this.kind = 'image',
    this.mimeType,
  });

  final int id;
  final String url;
  final bool isPrimary;
  final String kind;
  final String? mimeType;

  bool get isVideo =>
      kind.toLowerCase() == 'video' ||
      (mimeType?.toLowerCase().startsWith('video/') ?? false);

  factory MakerSettingsArtworkMedia.fromMap(Map<String, dynamic> map) {
    return MakerSettingsArtworkMedia(
      id: _asInt(map['id']) ?? 0,
      url: map['url']?.toString() ?? '',
      isPrimary: _asBool(map['is_primary']),
      kind: map['kind']?.toString() ?? 'image',
      mimeType: _nullableString(map['mime_type']),
    );
  }
}

class MakerSettingsArtwork {
  const MakerSettingsArtwork({
    required this.id,
    required this.title,
    required this.description,
    required this.typeId,
    required this.styleId,
    required this.locationId,
    required this.locationText,
    required this.moderationStatus,
    required this.isVisible,
    required this.media,
  });

  final int id;
  final String title;
  final String description;
  final int? typeId;
  final int? styleId;
  final int? locationId;
  final String locationText;
  final String moderationStatus;
  final bool isVisible;
  final List<MakerSettingsArtworkMedia> media;

  MakerSettingsArtworkMedia? get primaryMedia {
    for (final item in media) {
      if (item.isPrimary) return item;
    }
    return media.isEmpty ? null : media.first;
  }

  String? get primaryImageUrl {
    final value = primaryMedia?.url.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  factory MakerSettingsArtwork.fromMap(Map<String, dynamic> map) {
    final type = _mapOrNull(map['type']);
    final style = _mapOrNull(map['style']);
    final location = _mapOrNull(map['location']);

    return MakerSettingsArtwork(
      id: _asInt(map['id']) ?? 0,
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      typeId: _asInt(type?['id']),
      styleId: _asInt(style?['id']),
      locationId: _asInt(location?['id']),
      locationText: map['location_text']?.toString() ?? '',
      moderationStatus: map['moderation_status']?.toString() ?? 'pending',
      isVisible: _asBool(map['is_visible'], fallback: true),
      media: _mapList(map['media'])
          .map(MakerSettingsArtworkMedia.fromMap)
          .toList(growable: false),
    );
  }
}

class MakerInfoArtworkSlot {
  const MakerInfoArtworkSlot({required this.slot, required this.artwork});

  final int slot;
  final MakerSettingsArtwork artwork;

  factory MakerInfoArtworkSlot.fromMap(Map<String, dynamic> map) {
    return MakerInfoArtworkSlot(
      slot: _asInt(map['slot']) ?? 0,
      artwork: MakerSettingsArtwork.fromMap(
        _mapOrNull(map['artwork']) ?? const <String, dynamic>{},
      ),
    );
  }
}

class MakerInfoSettingsData {
  const MakerInfoSettingsData({
    required this.name,
    required this.bio,
    required this.locationText,
    required this.website,
    required this.email,
    required this.profileImageUrl,
    required this.managedLocationId,
    required this.showWebsite,
    required this.showEmail,
    required this.showShows,
    required this.selectedTypeIds,
    required this.selectedStyleIds,
    required this.carousel,
    required this.artworkSlots,
    required this.savedCount,
    required this.availableTypes,
    required this.availableStyles,
  });

  final String name;
  final String bio;
  final String locationText;
  final String website;
  final String email;
  final String? profileImageUrl;
  final int? managedLocationId;
  final bool showWebsite;
  final bool showEmail;
  final bool showShows;
  final Set<int> selectedTypeIds;
  final Set<int> selectedStyleIds;
  final List<MakerCarouselItem> carousel;
  final List<MakerInfoArtworkSlot> artworkSlots;
  final int savedCount;
  final List<MakerSettingsTaxonomyOption> availableTypes;
  final List<MakerSettingsTaxonomyOption> availableStyles;
}

class MakerInfoSettingsDraft {
  const MakerInfoSettingsDraft({
    required this.name,
    required this.bio,
    required this.locationText,
    required this.website,
    required this.email,
    required this.locationId,
    required this.showWebsite,
    required this.showEmail,
    required this.showShows,
    required this.typeIds,
    required this.styleIds,
  });

  final String name;
  final String bio;
  final String locationText;
  final String website;
  final String email;
  final int? locationId;
  final bool showWebsite;
  final bool showEmail;
  final bool showShows;
  final Set<int> typeIds;
  final Set<int> styleIds;
}

class PendingCarouselMedia {
  const PendingCarouselMedia({
    required this.slot,
    required this.bytes,
    required this.name,
    required this.kind,
    this.caption,
    this.localPath,
  });

  final int slot;
  final Uint8List bytes;
  final String name;
  final String kind;
  final String? caption;
  final String? localPath;
}

Map<String, dynamic>? _mapOrNull(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  return value == 1 || value == '1' || value == 'true';
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

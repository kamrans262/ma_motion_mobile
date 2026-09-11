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
  });

  final int slot;
  final Uint8List bytes;
  final String name;
  final String kind;
  final String? caption;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

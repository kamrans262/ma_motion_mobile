class DiscoveryTaxonomy {
  const DiscoveryTaxonomy({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory DiscoveryTaxonomy.fromMap(Map<String, dynamic> map) {
    return DiscoveryTaxonomy(
      id: _asInt(map['id']) ?? 0,
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
    );
  }
}

class DiscoveryLocation {
  const DiscoveryLocation({
    required this.id,
    required this.label,
    this.city,
    this.region,
    this.postalCode,
    this.countryCode,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String label;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? countryCode;
  final double? latitude;
  final double? longitude;

  factory DiscoveryLocation.fromMap(Map<String, dynamic> map) {
    return DiscoveryLocation(
      id: _asInt(map['id']) ?? 0,
      label: map['label']?.toString() ?? '',
      city: _nullableString(map['city']),
      region: _nullableString(map['region']),
      postalCode: _nullableString(map['postal_code']),
      countryCode: _nullableString(map['country_code']),
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
    );
  }
}

class DiscoveryArtworkMedia {
  const DiscoveryArtworkMedia({
    required this.id,
    required this.kind,
    required this.url,
    this.mimeType,
    this.sizeBytes,
    this.width,
    this.height,
    this.altText,
    this.sortOrder,
    this.isPrimary = false,
  });

  final int id;
  final String kind;
  final String url;
  final String? mimeType;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final String? altText;
  final int? sortOrder;
  final bool isPrimary;

  bool get isVideo {
    final normalizedKind = kind.trim().toLowerCase();
    final normalizedMime = mimeType?.trim().toLowerCase() ?? '';

    return normalizedKind == 'video' || normalizedMime.startsWith('video/');
  }

  factory DiscoveryArtworkMedia.fromMap(Map<String, dynamic> map) {
    return DiscoveryArtworkMedia(
      id: _asInt(map['id']) ?? 0,
      kind: map['kind']?.toString() ?? 'image',
      url: map['url']?.toString() ?? '',
      mimeType: _nullableString(map['mime_type']),
      sizeBytes: _asInt(map['size_bytes']),
      width: _asInt(map['width']),
      height: _asInt(map['height']),
      altText: _nullableString(map['alt_text']),
      sortOrder: _asInt(map['sort_order']),
      isPrimary: _asBool(map['is_primary']),
    );
  }
}

class DiscoveryMakerPreview {
  const DiscoveryMakerPreview({
    required this.id,
    required this.name,
    this.bio,
    this.profileImageUrl,
    this.savedCount = 0,
  });

  final int id;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final int savedCount;

  factory DiscoveryMakerPreview.fromMap(Map<String, dynamic> map) {
    return DiscoveryMakerPreview(
      id: _asInt(map['id']) ?? 0,
      name: map['name']?.toString() ?? '',
      bio: _nullableString(map['bio']),
      profileImageUrl: _nullableString(map['profile_image_url']),
      savedCount: _asInt(map['saved_count']) ?? 0,
    );
  }
}

class DiscoveryArtwork {
  const DiscoveryArtwork({
    required this.id,
    required this.title,
    this.description,
    this.primaryMedia,
    this.type,
    this.style,
    this.location,
    this.locationText,
    this.locationSource,
    this.distanceKm,
    this.maker,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? description;
  final DiscoveryArtworkMedia? primaryMedia;
  final DiscoveryTaxonomy? type;
  final DiscoveryTaxonomy? style;
  final DiscoveryLocation? location;
  final String? locationText;
  final String? locationSource;
  final double? distanceKm;
  final DiscoveryMakerPreview? maker;
  final DateTime? createdAt;

  factory DiscoveryArtwork.fromMap(Map<String, dynamic> map) {
    final mediaMap = _mapOrNull(map['primary_media']);
    final typeMap = _mapOrNull(map['type']);
    final styleMap = _mapOrNull(map['style']);
    final locationMap = _mapOrNull(map['location']);
    final makerMap = _mapOrNull(map['maker']);

    return DiscoveryArtwork(
      id: _asInt(map['id']) ?? 0,
      title: map['title']?.toString() ?? '',
      description: _nullableString(map['description']),
      primaryMedia: mediaMap == null
          ? null
          : DiscoveryArtworkMedia.fromMap(mediaMap),
      type: typeMap == null ? null : DiscoveryTaxonomy.fromMap(typeMap),
      style: styleMap == null ? null : DiscoveryTaxonomy.fromMap(styleMap),
      location: locationMap == null
          ? null
          : DiscoveryLocation.fromMap(locationMap),
      locationText: _nullableString(map['location_text']),
      locationSource: _nullableString(map['location_source']),
      distanceKm: _asDouble(map['distance_km']),
      maker: makerMap == null ? null : DiscoveryMakerPreview.fromMap(makerMap),
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

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}

bool _asBool(Object? value) {
  if (value is bool) {
    return value;
  }

  return value == 1 || value == '1' || value == 'true';
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

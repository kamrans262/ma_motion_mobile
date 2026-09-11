import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoveryQueryProvider =
    NotifierProvider<DiscoveryQueryController, DiscoveryQuery>(
      DiscoveryQueryController.new,
    );

class DiscoveryQuery {
  const DiscoveryQuery({
    this.search = '',
    this.typeIds = const <int>{},
    this.styleIds = const <int>{},
    this.showStatuses = const <String>{},
    this.locationId,
    this.locationLabel,
    this.city = '',
    this.postalCode = '',
    this.countryCode,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  final String search;
  final Set<int> typeIds;
  final Set<int> styleIds;
  final Set<String> showStatuses;
  final int? locationId;
  final String? locationLabel;
  final String city;
  final String postalCode;
  final String? countryCode;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  bool get hasFilters =>
      typeIds.isNotEmpty ||
      styleIds.isNotEmpty ||
      showStatuses.isNotEmpty ||
      locationId != null ||
      city.trim().isNotEmpty ||
      postalCode.trim().isNotEmpty ||
      radiusKm != null;

  int get activeFilterCount {
    var count = 0;
    if (typeIds.isNotEmpty) count++;
    if (styleIds.isNotEmpty) count++;
    if (showStatuses.isNotEmpty) count++;
    if (locationId != null ||
        city.trim().isNotEmpty ||
        postalCode.trim().isNotEmpty ||
        radiusKm != null) {
      count++;
    }
    return count;
  }

  DiscoveryQuery withSearch(String value) {
    return DiscoveryQuery(
      search: value.trim(),
      typeIds: Set<int>.from(typeIds),
      styleIds: Set<int>.from(styleIds),
      showStatuses: Set<String>.from(showStatuses),
      locationId: locationId,
      locationLabel: locationLabel,
      city: city,
      postalCode: postalCode,
      countryCode: countryCode,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  DiscoveryQuery withoutSearch() => withSearch('');

  Map<String, dynamic> toQueryParameters({
    required int page,
    required int perPage,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};

    if (search.trim().isNotEmpty) query['search'] = search.trim();
    if (typeIds.isNotEmpty) {
      query['type_ids'] = (typeIds.toList()..sort()).join(',');
    }
    if (styleIds.isNotEmpty) {
      query['style_ids'] = (styleIds.toList()..sort()).join(',');
    }
    if (showStatuses.isNotEmpty) {
      final statuses = showStatuses.toList()..sort();
      query['show_statuses'] = statuses.join(',');
    }

    final hasRadius = latitude != null && longitude != null && radiusKm != null;

    if (hasRadius) {
      query['latitude'] = latitude;
      query['longitude'] = longitude;
      query['radius_km'] = radiusKm;
    } else if (locationId != null) {
      query['location_id'] = locationId;
    }

    if (city.trim().isNotEmpty) query['city'] = city.trim();
    if (postalCode.trim().isNotEmpty) {
      query['postal_code'] = postalCode.trim();
    }
    if ((countryCode ?? '').trim().isNotEmpty) {
      query['country_code'] = countryCode!.trim().toUpperCase();
    }

    return query;
  }
}

class DiscoveryQueryController extends Notifier<DiscoveryQuery> {
  @override
  DiscoveryQuery build() => const DiscoveryQuery();

  void setQuery(DiscoveryQuery query) {
    state = query.withoutSearch();
  }

  void clearFilters() {
    state = const DiscoveryQuery();
  }
}

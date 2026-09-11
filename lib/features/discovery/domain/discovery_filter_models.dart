import '../../../core/network/pagination_meta.dart';
import 'discovery_artwork.dart';

class DiscoveryShowStatusOption {
  const DiscoveryShowStatusOption({required this.value, required this.label});

  final String value;
  final String label;

  factory DiscoveryShowStatusOption.fromMap(Map<String, dynamic> map) {
    return DiscoveryShowStatusOption(
      value: map['value']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
    );
  }
}

class DiscoveryFilterOptions {
  const DiscoveryFilterOptions({
    this.types = const <DiscoveryTaxonomy>[],
    this.styles = const <DiscoveryTaxonomy>[],
    this.showStatuses = const <DiscoveryShowStatusOption>[],
    this.radiusMinKm = 1,
    this.radiusMaxKm = 500,
  });

  final List<DiscoveryTaxonomy> types;
  final List<DiscoveryTaxonomy> styles;
  final List<DiscoveryShowStatusOption> showStatuses;
  final double radiusMinKm;
  final double radiusMaxKm;

  factory DiscoveryFilterOptions.fromMap(Map<String, dynamic> map) {
    final location = mapOrNull(map['location']) ?? const <String, dynamic>{};
    final radius =
        mapOrNull(location['radius_km']) ?? const <String, dynamic>{};

    return DiscoveryFilterOptions(
      types: listOrEmpty(map['types'])
          .whereType<Map>()
          .map(
            (item) =>
                DiscoveryTaxonomy.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      styles: listOrEmpty(map['styles'])
          .whereType<Map>()
          .map(
            (item) =>
                DiscoveryTaxonomy.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      showStatuses: listOrEmpty(map['show_statuses'])
          .whereType<Map>()
          .map(
            (item) => DiscoveryShowStatusOption.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      radiusMinKm: asDouble(radius['min']) ?? 1,
      radiusMaxKm: asDouble(radius['max']) ?? 500,
    );
  }
}

class DiscoveryLocationPage {
  const DiscoveryLocationPage({required this.items, required this.meta});

  final List<DiscoveryLocation> items;
  final PaginationMeta meta;
}

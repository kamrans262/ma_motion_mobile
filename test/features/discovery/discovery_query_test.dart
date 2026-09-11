import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';

void main() {
  test('serializes canonical discovery filters and avoids radius conflict', () {
    const query = DiscoveryQuery(
      search: 'Orbit',
      typeIds: <int>{3, 1},
      styleIds: <int>{9},
      showStatuses: <String>{'upcoming', 'current'},
      locationId: 50,
      locationLabel: 'New York, NY 10001',
      countryCode: 'us',
      latitude: 40.7128,
      longitude: -74.0060,
      radiusKm: 25,
    );

    final params = query.toQueryParameters(page: 2, perPage: 24);

    expect(params['page'], 2);
    expect(params['per_page'], 24);
    expect(params['search'], 'Orbit');
    expect(params['type_ids'], '1,3');
    expect(params['style_ids'], '9');
    expect(params['show_statuses'], 'current,upcoming');
    expect(params['country_code'], 'US');
    expect(params['latitude'], 40.7128);
    expect(params['longitude'], -74.0060);
    expect(params['radius_km'], 25);
    expect(params.containsKey('location_id'), isFalse);
  });

  test('uses exact managed location when radius is absent', () {
    const query = DiscoveryQuery(
      locationId: 50,
      locationLabel: 'New York, NY 10001',
    );

    final params = query.toQueryParameters(page: 1, perPage: 24);

    expect(params['location_id'], 50);
    expect(params.containsKey('latitude'), isFalse);
    expect(params.containsKey('radius_km'), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/discovery/data/discovery_filter_repository.dart';

void main() {
  test('parses filter options from Laravel contract', () async {
    final api = _FakeApiGateway();
    final repository = DiscoveryFilterRepository(api: api);

    final options = await repository.fetchOptions();

    expect(api.lastPath, ApiPaths.discoveryFilters);
    expect(api.lastRequiresAuth, isFalse);
    expect(options.types.single.name, 'Painting');
    expect(options.styles.single.name, 'Minimal');
    expect(
      options.showStatuses.map((item) => item.value),
      containsAll(<String>['current', 'upcoming', 'past']),
    );
    expect(options.radiusMinKm, 1);
    expect(options.radiusMaxKm, 500);
  });

  test('searches managed locations by city or postal term', () async {
    final api = _FakeApiGateway();
    final repository = DiscoveryFilterRepository(api: api);

    final page = await repository.searchLocations('10001', countryCode: 'us');

    expect(api.lastPath, ApiPaths.discoveryLocations);
    expect(api.lastQuery?['search'], '10001');
    expect(api.lastQuery?['country_code'], 'US');
    expect(page.items.single.city, 'New York');
    expect(page.items.single.postalCode, '10001');
    expect(page.meta.total, 1);
  });
}

class _FakeApiGateway implements ApiGateway {
  String? lastPath;
  Map<String, dynamic>? lastQuery;
  bool? lastRequiresAuth;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    lastRequiresAuth = requiresAuth;

    if (path == ApiPaths.discoveryFilters) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'types': <dynamic>[
            <String, dynamic>{'id': 1, 'name': 'Painting', 'slug': 'painting'},
          ],
          'styles': <dynamic>[
            <String, dynamic>{'id': 2, 'name': 'Minimal', 'slug': 'minimal'},
          ],
          'show_statuses': <dynamic>[
            <String, dynamic>{'value': 'current', 'label': 'Current'},
            <String, dynamic>{'value': 'upcoming', 'label': 'Upcoming'},
            <String, dynamic>{'value': 'past', 'label': 'Past'},
          ],
          'location': <String, dynamic>{
            'radius_km': <String, dynamic>{'min': 1, 'max': 500},
          },
        },
      };
    }

    if (path == ApiPaths.discoveryLocations) {
      return <String, dynamic>{
        'success': true,
        'data': <dynamic>[
          <String, dynamic>{
            'id': 7,
            'label': 'New York, NY 10001',
            'city': 'New York',
            'region': 'NY',
            'postal_code': '10001',
            'country_code': 'US',
            'latitude': 40.7128,
            'longitude': -74.0060,
          },
        ],
        'meta': <String, dynamic>{
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': 1,
        },
      };
    }

    throw StateError('Unexpected GET $path');
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    throw UnimplementedError();
  }
}

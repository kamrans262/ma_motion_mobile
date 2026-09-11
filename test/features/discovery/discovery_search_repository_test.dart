import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/discovery/data/discovery_search_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';

void main() {
  test('parses unified artwork and Maker search sections', () async {
    final api = _FakeApiGateway();
    final repository = DiscoverySearchRepository(api: api);

    final page = await repository.search(
      query: const DiscoveryQuery(search: 'Orbit', typeIds: <int>{1}),
      page: 1,
    );

    expect(api.lastPath, ApiPaths.discoverySearch);
    expect(api.lastRequiresAuth, isFalse);
    expect(api.lastQuery?['search'], 'Orbit');
    expect(api.lastQuery?['type_ids'], '1');

    expect(page.artworks.single.title, 'Orbit Light');
    expect(page.makers.single.name, 'Orbit Artist');
    expect(page.makers.single.statistics.savedCount, 12);
    expect(page.makers.single.statistics.artworkCount, 4);
    expect(page.artworkMeta.total, 1);
    expect(page.makerMeta.total, 1);
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

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'artworks': <dynamic>[
          <String, dynamic>{
            'id': 9,
            'title': 'Orbit Light',
            'primary_media': null,
            'maker': <String, dynamic>{
              'id': 4,
              'name': 'Orbit Artist',
              'saved_count': 12,
            },
          },
        ],
        'makers': <dynamic>[
          <String, dynamic>{
            'id': 4,
            'name': 'Orbit Artist',
            'bio': 'Installation work',
            'profile_image_url': null,
            'statistics': <String, dynamic>{
              'saved_count': 12,
              'artwork_count': 4,
              'current_show_count': 1,
              'upcoming_show_count': 1,
            },
          },
        ],
      },
      'meta': <String, dynamic>{
        'artworks': <String, dynamic>{
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': 1,
        },
        'makers': <String, dynamic>{
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': 1,
        },
      },
    };
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

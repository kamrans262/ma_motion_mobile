import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';
import 'package:ma_motion_mobile/features/discovery/domain/discovery_query.dart';

void main() {
  test('parses Laravel discovery artwork with active filters', () async {
    final api = _FakeApiGateway(
      response: <String, dynamic>{
        'success': true,
        'data': <dynamic>[
          <String, dynamic>{
            'id': 10,
            'title': 'Purple Geometry',
            'primary_media': <String, dynamic>{
              'id': 50,
              'kind': 'image',
              'url': 'https://example.test/a.jpg',
              'mime_type': 'image/jpeg',
              'is_primary': true,
            },
            'maker': <String, dynamic>{
              'id': 3,
              'name': 'Maya Linwood',
              'saved_count': 7,
            },
          },
        ],
        'meta': <String, dynamic>{
          'current_page': 1,
          'last_page': 3,
          'per_page': 24,
          'total': 41,
        },
      },
    );

    final repository = ArtworkDiscoveryRepository(api: api);
    final page = await repository.fetchPage(
      page: 1,
      query: const DiscoveryQuery(
        typeIds: <int>{2},
        showStatuses: <String>{'current'},
      ),
    );

    expect(api.lastPath, ApiPaths.discoveryArtworks);
    expect(api.lastRequiresAuth, isFalse);
    expect(api.lastQuery?['type_ids'], '2');
    expect(api.lastQuery?['show_statuses'], 'current');
    expect(page.items.single.title, 'Purple Geometry');
    expect(page.meta.hasNextPage, isTrue);
  });
}

class _FakeApiGateway implements ApiGateway {
  _FakeApiGateway({required this.response});

  final Map<String, dynamic> response;
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
    return response;
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

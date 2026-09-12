import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/saved_artworks/data/saved_artworks_repository.dart';

void main() {
  test('saved artwork repository uses authenticated paginated API', () async {
    final api = _FakeApiGateway();
    final repository = SavedArtworksRepository(api: api);

    final page = await repository.fetchPage(page: 2, perPage: 8);

    expect(api.lastPath, ApiPaths.savedArtworks);
    expect(api.lastQuery?['page'], 2);
    expect(api.lastQuery?['per_page'], 8);
    expect(api.lastRequiresAuth, isTrue);
    expect(page.meta.currentPage, 2);
    expect(page.items.single.id, 77);

    expect(await repository.isSaved(77), isTrue);
    expect(api.lastPath, ApiPaths.savedArtwork(77));

    await repository.save(77);
    expect(api.lastMethod, 'POST');

    await repository.unsave(77);
    expect(api.lastMethod, 'DELETE');
  });
}

class _FakeApiGateway implements ApiGateway {
  String? lastPath;
  String? lastMethod;
  Map<String, dynamic>? lastQuery;
  bool? lastRequiresAuth;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPath = path;
    lastMethod = 'GET';
    lastQuery = queryParameters;
    lastRequiresAuth = requiresAuth;

    if (path == ApiPaths.savedArtwork(77)) {
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'artwork_id': 77, 'saved': true},
      };
    }

    return <String, dynamic>{
      'success': true,
      'data': <dynamic>[
        <String, dynamic>{
          'id': 77,
          'title': 'Saved artwork',
          'primary_media': null,
        },
      ],
      'meta': <String, dynamic>{
        'current_page': 2,
        'last_page': 3,
        'per_page': 8,
        'total': 17,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPath = path;
    lastMethod = 'POST';
    lastRequiresAuth = requiresAuth;

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'saved': true},
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPath = path;
    lastMethod = 'DELETE';
    lastRequiresAuth = requiresAuth;

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'saved': false},
    };
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
}

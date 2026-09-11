import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/discovery/data/artwork_discovery_repository.dart';

void main() {
  test(
    'parses exact Laravel discovery artwork and pagination contract',
    () async {
      final api = _FakeApiGateway(
        response: <String, dynamic>{
          'success': true,
          'message': 'Discovery artwork retrieved successfully.',
          'data': <dynamic>[
            <String, dynamic>{
              'id': 10,
              'title': 'Purple Geometry',
              'description': 'A precise city study',
              'primary_media': <String, dynamic>{
                'id': 50,
                'kind': 'image',
                'url': 'https://example.test/storage/artworks/a.jpg',
                'mime_type': 'image/jpeg',
                'size_bytes': 12345,
                'width': 1200,
                'height': 1200,
                'alt_text': 'Purple Geometry',
                'sort_order': 0,
                'is_primary': true,
              },
              'type': <String, dynamic>{
                'id': 1,
                'name': 'Painting',
                'slug': 'painting',
              },
              'style': <String, dynamic>{
                'id': 2,
                'name': 'Contemporary',
                'slug': 'contemporary',
              },
              'location': <String, dynamic>{
                'id': 4,
                'label': 'Chicago, IL 60601',
                'city': 'Chicago',
                'region': 'IL',
                'postal_code': '60601',
                'country_code': 'US',
                'latitude': 41.88,
                'longitude': -87.63,
              },
              'location_text': 'Chicago 60601',
              'location_source': 'artwork',
              'distance_km': 2.7,
              'maker': <String, dynamic>{
                'id': 3,
                'name': 'Maya Linwood',
                'bio': 'Geometric painter',
                'profile_image_url': null,
                'saved_count': 7,
              },
              'created_at': '2026-09-11T10:00:00.000000Z',
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
      final page = await repository.fetchPage(page: 1);

      expect(api.lastPath, ApiPaths.discoveryArtworks);
      expect(api.lastRequiresAuth, isFalse);
      expect(api.lastQuery?['page'], 1);
      expect(api.lastQuery?['per_page'], 24);

      expect(page.items, hasLength(1));

      final artwork = page.items.single;
      expect(artwork.id, 10);
      expect(artwork.title, 'Purple Geometry');
      expect(artwork.primaryMedia?.sizeBytes, 12345);
      expect(artwork.primaryMedia?.isPrimary, isTrue);
      expect(artwork.type?.name, 'Painting');
      expect(artwork.style?.name, 'Contemporary');
      expect(artwork.location?.postalCode, '60601');
      expect(artwork.locationSource, 'artwork');
      expect(artwork.distanceKm, 2.7);
      expect(artwork.maker?.name, 'Maya Linwood');
      expect(artwork.maker?.savedCount, 7);
      expect(artwork.createdAt, isNotNull);

      expect(page.meta.currentPage, 1);
      expect(page.meta.lastPage, 3);
      expect(page.meta.perPage, 24);
      expect(page.meta.total, 41);
      expect(page.meta.hasNextPage, isTrue);
    },
  );
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

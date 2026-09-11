import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/artwork_viewer/data/artwork_detail_repository.dart';

void main() {
  test('parses complete public artwork viewer contract', () async {
    final api = _FakeApiGateway();

    final repository = ArtworkDetailRepository(api: api);
    final detail = await repository.fetch(41);

    expect(api.lastPath, '${ApiPaths.discoveryArtworks}/41');
    expect(api.lastRequiresAuth, isFalse);

    expect(detail.id, 41);
    expect(detail.title, 'Tide Register No. 4');
    expect(detail.description, 'Built in slow layers over eleven months.');
    expect(detail.media, hasLength(2));
    expect(detail.media.first.id, 91);
    expect(detail.media.last.id, 92);
    expect(detail.primaryMedia?.id, 91);
    expect(detail.maker?.name, 'Mara Vellan');
    expect(detail.maker?.websiteUrl, 'https://artist.example');
    expect(detail.maker?.location, 'Chicago, IL');
    expect(detail.maker?.savedCount, 12);
    expect(detail.createdAt?.year, 2024);
    expect(detail.viewerPageCount, 3);
  });
}

class _FakeApiGateway implements ApiGateway {
  String? lastPath;
  bool? lastRequiresAuth;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPath = path;
    lastRequiresAuth = requiresAuth;

    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'id': 41,
        'title': 'Tide Register No. 4',
        'description': 'Built in slow layers over eleven months.',
        'media': <dynamic>[
          <String, dynamic>{
            'id': 91,
            'kind': 'image',
            'url': '',
            'mime_type': 'image/jpeg',
            'size_bytes': 100,
            'width': 800,
            'height': 1000,
            'alt_text': 'Front',
            'sort_order': 1,
            'is_primary': true,
          },
          <String, dynamic>{
            'id': 92,
            'kind': 'image',
            'url': '',
            'mime_type': 'image/jpeg',
            'size_bytes': 110,
            'width': 800,
            'height': 1000,
            'alt_text': 'Detail',
            'sort_order': 2,
            'is_primary': false,
          },
        ],
        'primary_media': <String, dynamic>{
          'id': 91,
          'kind': 'image',
          'url': '',
          'mime_type': 'image/jpeg',
          'width': 800,
          'height': 1000,
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
        'location': null,
        'location_text': 'Chicago, IL',
        'maker': <String, dynamic>{
          'id': 7,
          'name': 'Mara Vellan',
          'bio': 'A contemporary artist.',
          'location': 'Chicago, IL',
          'profile_image_url': null,
          'website_url': 'https://artist.example',
          'saved_count': 12,
        },
        'created_at': '2024-05-01T00:00:00.000000Z',
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

import 'package:flutter_test/flutter_test.dart';
import 'package:ma_motion_mobile/core/network/api_gateway.dart';
import 'package:ma_motion_mobile/core/network/api_paths.dart';
import 'package:ma_motion_mobile/features/settings/data/event_location_autocomplete_repository.dart';

void main() {
  test('fetches Event Location suggestions only through the backend', () async {
    final api = _FakeApiGateway();
    final repository = EventLocationAutocompleteRepository(api: api);

    final suggestions = await repository.search('  gallery  ');

    expect(api.lastPath, ApiPaths.eventLocationSuggestions);
    expect(api.lastQuery, <String, dynamic>{'input': 'gallery'});
    expect(suggestions, <String>[
      'Art Gallery, Chicago, IL, USA',
      '60622, Chicago, IL, USA',
    ]);
  });

  test('skips short queries without a network request', () async {
    final api = _FakeApiGateway();
    final repository = EventLocationAutocompleteRepository(api: api);

    expect(await repository.search('a'), isEmpty);
    expect(api.lastPath, isNull);
  });
}

class _FakeApiGateway implements ApiGateway {
  String? lastPath;
  Map<String, dynamic>? lastQuery;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    expect(requiresAuth, isTrue);
    return <String, dynamic>{
      'success': true,
      'data': <Map<String, dynamic>>[
        <String, dynamic>{'description': 'Art Gallery, Chicago, IL, USA'},
        <String, dynamic>{'description': '60622, Chicago, IL, USA'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) => throw UnimplementedError();
}

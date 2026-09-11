import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/pagination_meta.dart';
import '../../../core/providers/core_providers.dart';
import '../domain/discovery_artwork.dart';
import '../domain/discovery_filter_models.dart';

final discoveryFilterRepositoryProvider =
    Provider<DiscoveryFilterRepositoryContract>((ref) {
      return DiscoveryFilterRepository(api: ref.watch(apiGatewayProvider));
    });

abstract interface class DiscoveryFilterRepositoryContract {
  Future<DiscoveryFilterOptions> fetchOptions();

  Future<DiscoveryLocationPage> searchLocations(
    String search, {
    int page,
    int perPage,
    String? countryCode,
  });
}

class DiscoveryFilterRepository implements DiscoveryFilterRepositoryContract {
  const DiscoveryFilterRepository({required this.api});

  final ApiGateway api;

  @override
  Future<DiscoveryFilterOptions> fetchOptions() async {
    final response = await api.get(
      ApiPaths.discoveryFilters,
      requiresAuth: false,
    );

    return DiscoveryFilterOptions.fromMap(ApiEnvelope(raw: response).dataMap);
  }

  @override
  Future<DiscoveryLocationPage> searchLocations(
    String search, {
    int page = 1,
    int perPage = 20,
    String? countryCode,
  }) async {
    final text = search.trim();

    if (text.isEmpty) {
      return const DiscoveryLocationPage(
        items: <DiscoveryLocation>[],
        meta: PaginationMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: 20,
          total: 0,
        ),
      );
    }

    final query = <String, dynamic>{
      'search': text,
      'page': page,
      'per_page': perPage,
    };

    if ((countryCode ?? '').trim().isNotEmpty) {
      query['country_code'] = countryCode!.trim().toUpperCase();
    }

    final response = await api.get(
      ApiPaths.discoveryLocations,
      requiresAuth: false,
      queryParameters: query,
    );

    final envelope = ApiEnvelope(raw: response);
    final items = envelope.dataList
        .whereType<Map>()
        .map(
          (item) => DiscoveryLocation.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return DiscoveryLocationPage(
      items: items,
      meta: PaginationMeta.fromMap(envelope.meta),
    );
  }
}

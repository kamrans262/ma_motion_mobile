import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/auth_token_store.dart';
import '../domain/maker_onboarding_options.dart';
import '../domain/maker_registration_draft.dart';
import '../domain/maker_taxonomy_option.dart';

final makerOnboardingRepositoryProvider = Provider<MakerOnboardingRepository>(
  (ref) => MakerOnboardingRepository(
    api: ref.watch(apiGatewayProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
  ),
);

class MakerOnboardingRepository {
  const MakerOnboardingRepository({
    required this.api,
    required this.tokenStore,
  });

  final ApiGateway api;
  final AuthTokenStore tokenStore;

  static const Map<String, String> _typeAliases = <String, String>{
    'graphic designer': 'graphic design',
  };

  Future<MakerOnboardingOptions> loadOptions() async {
    final response = await api.get(
      ApiPaths.discoveryFilters,
      requiresAuth: false,
    );
    final data = ApiEnvelope(raw: response).dataMap;

    return MakerOnboardingOptions(
      types: _parseOptions(data['types']),
      styles: _parseOptions(data['styles']),
    );
  }

  Future<int?> resolveLocationId(String query) async {
    final value = query.trim();

    if (value.isEmpty) {
      return null;
    }

    final response = await api.get(
      ApiPaths.discoveryLocations,
      requiresAuth: false,
      queryParameters: <String, dynamic>{'search': value, 'per_page': 1},
    );

    final locations = ApiEnvelope(raw: response).dataList;

    if (locations.isEmpty || locations.first is! Map) {
      return null;
    }

    final first = Map<String, dynamic>.from(locations.first as Map);
    final id = first['id'];

    if (id is int) {
      return id;
    }

    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> completeMakerProfile(
    MakerRegistrationDraft draft, {
    String? otpChallengeId,
  }) async {
    await _ensureMakerSession(draft, otpChallengeId);

    final options = await loadOptions();
    final locationId = await resolveLocationId(draft.location);

    final typeIds = _resolveSelectedIds(
      selected: draft.types,
      options: options.types,
      aliases: _typeAliases,
      label: 'Type',
    );
    final styleIds = _resolveSelectedIds(
      selected: draft.styles,
      options: options.styles,
      label: 'Style',
    );

    try {
      await api.patch(
        ApiPaths.makerProfile,
        data: <String, dynamic>{
          'name': draft.name.trim(),
          if (draft.aboutWork.trim().isNotEmpty) 'bio': draft.aboutWork.trim(),
          'location_text': draft.location.trim(),
          'location_id': ?locationId,
          if (draft.website.trim().isNotEmpty)
            'website_url': _normalizeWebsite(draft.website),
          'contact_email': draft.email.trim(),
          'type_ids': typeIds,
          'style_ids': styleIds,
        },
      );

      final imageBytes = draft.imageBytes;
      if (imageBytes == null || imageBytes.isEmpty) {
        if (draft.existingImageUrl?.trim().isNotEmpty != true) {
          throw const ApiException(
            message: 'Please upload your salon image before continuing.',
          );
        }
      } else {
        await _uploadProfileImage(imageBytes, draft.imageName);
      }

      await api.patch(
        ApiPaths.makerProfile,
        data: const <String, dynamic>{'complete_onboarding': true},
      );
    } on ApiException catch (error) {
      if (error.isUnauthenticated) {
        throw const ApiException(
          message:
              'Your Maker session expired before the profile could be saved. '
              'Please try again.',
          statusCode: 401,
          code: 'maker_onboarding_session_expired',
        );
      }

      rethrow;
    }
  }

  Future<void> _ensureMakerSession(
    MakerRegistrationDraft draft,
    String? otpChallengeId,
  ) async {
    final existingToken = await tokenStore.read();

    if (existingToken != null && existingToken.trim().isNotEmpty) {
      await api.post(ApiPaths.makerExperienceOnboarding);
      return;
    }

    final response = await api.post(
      ApiPaths.makerOnboarding,
      requiresAuth: false,
      data: <String, dynamic>{
        'name': draft.name.trim(),
        'email': draft.email.trim(),
        'otp_challenge_id': ?otpChallengeId,
        'device_name': 'MA Motion Mobile',
      },
    );

    final data = ApiEnvelope(raw: response).dataMap;
    final token = data['token']?.toString().trim() ?? '';

    if (token.isEmpty) {
      throw const ApiException(
        message: 'The server did not return a Maker session token.',
        code: 'maker_onboarding_token_missing',
      );
    }

    await tokenStore.write(token);
  }

  Future<void> _uploadProfileImage(
    Uint8List bytes,
    String? originalName,
  ) async {
    final name = _safeImageName(originalName);
    final form = FormData.fromMap(<String, dynamic>{
      'image': MultipartFile.fromBytes(bytes, filename: name),
    });

    await api.post(ApiPaths.profileImage, data: form);
  }

  List<int> _resolveSelectedIds({
    required Set<String> selected,
    required List<MakerTaxonomyOption> options,
    Map<String, String> aliases = const <String, String>{},
    required String label,
  }) {
    final byName = <String, MakerTaxonomyOption>{
      for (final option in options) _normalize(option.name): option,
    };

    final ids = <int>[];
    final missing = <String>[];

    for (final rawName in selected) {
      var normalized = _normalize(rawName);
      normalized = aliases[normalized] ?? normalized;

      final option = byName[normalized];
      if (option == null) {
        missing.add(rawName);
      } else {
        ids.add(option.id);
      }
    }

    if (missing.isNotEmpty) {
      throw ApiException(
        message:
            '$label selection is no longer available: ${missing.join(', ')}.',
        statusCode: 422,
        code: 'maker_onboarding_taxonomy_mismatch',
      );
    }

    return ids;
  }

  static List<MakerTaxonomyOption> _parseOptions(Object? value) {
    if (value is! List) {
      return const <MakerTaxonomyOption>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
              MakerTaxonomyOption.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  static String? _normalizeWebsite(String value) {
    final website = value.trim();

    if (website.isEmpty) {
      return null;
    }

    if (website.startsWith('http://') || website.startsWith('https://')) {
      return website;
    }

    return 'https://$website';
  }

  static String _safeImageName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'maker-profile.jpg';
    }

    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}

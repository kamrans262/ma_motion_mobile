import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/maker_info_settings_models.dart';

final makerInfoSettingsRepositoryProvider =
    Provider<MakerInfoSettingsRepositoryContract>((ref) {
      return MakerInfoSettingsRepository(
        api: ref.watch(apiGatewayProvider),
        auth: ref.watch(authRepositoryProvider),
      );
    });

abstract interface class MakerInfoSettingsRepositoryContract {
  Future<MakerInfoSettingsData> load();

  Future<void> saveProfile(MakerInfoSettingsDraft draft);

  Future<MakerCarouselItem> saveCarouselSlot({
    required int slot,
    required String? caption,
    Uint8List? bytes,
    String? fileName,
  });

  Future<void> deleteCarouselSlot(int slot);

  Future<MakerInfoArtworkSlot> saveArtworkSlot({
    required int slot,
    required MakerSettingsArtwork? existingArtwork,
    required String title,
    required String description,
    required int? typeId,
    required int? styleId,
    required int? locationId,
    required String locationText,
    Uint8List? bytes,
    String? fileName,
  });

  Future<void> deleteArtworkSlot(int slot);

  Future<void> logout();
}

class MakerInfoSettingsRepository
    implements MakerInfoSettingsRepositoryContract {
  const MakerInfoSettingsRepository({required this.api, required this.auth});

  final ApiGateway api;
  final AuthRepository auth;

  @override
  Future<MakerInfoSettingsData> load() async {
    final profileResponse = await api.get(ApiPaths.makerProfile);
    final statisticsResponse = await api.get(ApiPaths.makerStatistics);
    final filterResponse = await api.get(
      ApiPaths.discoveryFilters,
      requiresAuth: false,
    );

    final profile = ApiEnvelope(raw: profileResponse).dataMap;
    final statistics = ApiEnvelope(raw: statisticsResponse).dataMap;
    final filters = ApiEnvelope(raw: filterResponse).dataMap;

    final availableTypes = _mapList(filters['types'])
        .map(MakerSettingsTaxonomyOption.fromMap)
        .toList(growable: false);

    final availableStyles = _mapList(filters['styles'])
        .map(MakerSettingsTaxonomyOption.fromMap)
        .toList(growable: false);

    final selectedTypeIds = _mapList(profile['types'])
        .map((item) => _asInt(item['id']))
        .whereType<int>()
        .toSet();

    final selectedStyleIds = _mapList(profile['styles'])
        .map((item) => _asInt(item['id']))
        .whereType<int>()
        .toSet();

    final carousel = _mapList(profile['carousel_content'])
        .map(MakerCarouselItem.fromMap)
        .where((item) => item.slot == 1)
        .toList(growable: false);

    final artworkSlots = _mapList(profile['artwork_slots'])
        .map(MakerInfoArtworkSlot.fromMap)
        .where((item) => item.slot >= 2 && item.slot <= 4)
        .toList(growable: false);

    return MakerInfoSettingsData(
      name: profile['name']?.toString() ?? '',
      bio: profile['bio']?.toString() ?? '',
      locationText: profile['location_text']?.toString() ?? '',
      website: profile['website_url']?.toString() ?? '',
      email: profile['contact_email']?.toString() ?? '',
      profileImageUrl: _nullableString(profile['profile_image_url']),
      managedLocationId: _asInt(_mapOrNull(profile['managed_location'])?['id']),
      showWebsite: _asBool(
        profile['show_website_on_info_page'],
        fallback: true,
      ),
      showEmail: _asBool(profile['show_email_on_info_page']),
      showShows: _asBool(profile['show_shows_on_info_page'], fallback: true),
      selectedTypeIds: selectedTypeIds,
      selectedStyleIds: selectedStyleIds,
      carousel: carousel,
      artworkSlots: artworkSlots,
      savedCount: _asInt(statistics['profile_saved_count']) ?? 0,
      availableTypes: availableTypes,
      availableStyles: availableStyles,
    );
  }

  @override
  Future<void> saveProfile(MakerInfoSettingsDraft draft) async {
    await api.patch(
      ApiPaths.makerProfile,
      data: <String, dynamic>{
        'name': draft.name.trim(),
        'bio': _emptyToNull(draft.bio),
        'location_text': _emptyToNull(draft.locationText),
        'location_id': draft.locationId,
        'website_url': _emptyToNull(draft.website),
        'contact_email': _emptyToNull(draft.email),
        'show_website_on_info_page': draft.showWebsite,
        'show_email_on_info_page': draft.showEmail,
        'show_shows_on_info_page': draft.showShows,
        'type_ids': draft.typeIds.toList(growable: false),
        'style_ids': draft.styleIds.toList(growable: false),
      },
    );
  }

  @override
  Future<MakerCarouselItem> saveCarouselSlot({
    required int slot,
    required String? caption,
    Uint8List? bytes,
    String? fileName,
  }) async {
    if (slot != 1) {
      throw ArgumentError.value(slot, 'slot', 'Only Content 1 is profile media.');
    }

    final formData = FormData();

    formData.fields.add(
      MapEntry<String, String>('caption', caption?.trim() ?? ''),
    );

    if (bytes != null && bytes.isNotEmpty && fileName != null) {
      formData.files.add(
        MapEntry<String, MultipartFile>(
          'media',
          MultipartFile.fromBytes(bytes, filename: fileName),
        ),
      );
    }

    final response = await api.post(
      '${ApiPaths.makerProfile}/carousel/$slot',
      data: formData,
    );

    return MakerCarouselItem.fromMap(ApiEnvelope(raw: response).dataMap);
  }

  @override
  Future<void> deleteCarouselSlot(int slot) async {
    if (slot != 1) {
      throw ArgumentError.value(slot, 'slot', 'Only Content 1 is profile media.');
    }

    await api.delete('${ApiPaths.makerProfile}/carousel/$slot');
  }

  @override
  Future<MakerInfoArtworkSlot> saveArtworkSlot({
    required int slot,
    required MakerSettingsArtwork? existingArtwork,
    required String title,
    required String description,
    required int? typeId,
    required int? styleId,
    required int? locationId,
    required String locationText,
    Uint8List? bytes,
    String? fileName,
  }) async {
    if (slot < 2 || slot > 4) {
      throw ArgumentError.value(slot, 'slot', 'Artwork slots are Content 2-4.');
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Artwork title is required.');
    }

    final metadata = <String, dynamic>{
      'title': trimmedTitle,
      'description': _emptyToNull(description),
      'artwork_type_id': typeId,
      'artwork_style_id': styleId,
      'location_id': locationId,
      'location_text': _emptyToNull(locationText),
    };

    MakerSettingsArtwork artwork;

    if (existingArtwork == null) {
      if (bytes == null || bytes.isEmpty || fileName == null) {
        throw ArgumentError('A new artwork requires an image.');
      }

      final formData = FormData.fromMap(<String, dynamic>{
        ...metadata,
        'media': <MultipartFile>[
          MultipartFile.fromBytes(bytes, filename: fileName),
        ],
      });

      final response = await api.post(ApiPaths.myArtworks, data: formData);
      artwork = MakerSettingsArtwork.fromMap(
        ApiEnvelope(raw: response).dataMap,
      );
    } else {
      final response = await api.patch(
        '${ApiPaths.myArtworks}/${existingArtwork.id}',
        data: metadata,
      );
      artwork = MakerSettingsArtwork.fromMap(
        ApiEnvelope(raw: response).dataMap,
      );

      if (bytes != null && bytes.isNotEmpty && fileName != null) {
        final oldMediaIds = existingArtwork.media.map((item) => item.id).toSet();
        final oldPrimaryId = existingArtwork.primaryMedia?.id;
        final mediaData = FormData.fromMap(<String, dynamic>{
          'media': <MultipartFile>[
            MultipartFile.fromBytes(bytes, filename: fileName),
          ],
        });

        final mediaResponse = await api.post(
          '${ApiPaths.myArtworks}/${existingArtwork.id}/media',
          data: mediaData,
        );
        final withMedia = MakerSettingsArtwork.fromMap(
          ApiEnvelope(raw: mediaResponse).dataMap,
        );

        MakerSettingsArtworkMedia? newMedia;
        for (final item in withMedia.media) {
          if (!oldMediaIds.contains(item.id)) {
            newMedia = item;
            break;
          }
        }

        if (newMedia != null) {
          final primaryResponse = await api.patch(
            '${ApiPaths.myArtworks}/${existingArtwork.id}/media/${newMedia.id}/primary',
          );
          artwork = MakerSettingsArtwork.fromMap(
            ApiEnvelope(raw: primaryResponse).dataMap,
          );

          if (oldPrimaryId != null && oldPrimaryId != newMedia.id) {
            await api.delete(
              '${ApiPaths.myArtworks}/${existingArtwork.id}/media/$oldPrimaryId',
            );
          }
        } else {
          artwork = withMedia;
        }
      }
    }

    final assignmentResponse = await api.put(
      '${ApiPaths.makerProfile}/artwork-slots/$slot',
      data: <String, dynamic>{'artwork_id': artwork.id},
    );

    return MakerInfoArtworkSlot.fromMap(
      ApiEnvelope(raw: assignmentResponse).dataMap,
    );
  }

  @override
  Future<void> deleteArtworkSlot(int slot) async {
    if (slot < 2 || slot > 4) {
      throw ArgumentError.value(slot, 'slot', 'Artwork slots are Content 2-4.');
    }

    await api.delete('${ApiPaths.makerProfile}/artwork-slots/$slot');
  }

  @override
  Future<void> logout() => auth.logout();

  static Map<String, dynamic>? _mapOrNull(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static List<Map<String, dynamic>> _mapList(Object? value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static bool _asBool(Object? value, {bool fallback = false}) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    return value == 1 || value == '1' || value == 'true';
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

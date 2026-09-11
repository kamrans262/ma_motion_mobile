import 'dart:typed_data';

class MakerRegistrationDraft {
  const MakerRegistrationDraft({
    this.name = '',
    this.location = '',
    this.aboutWork = '',
    this.types = const <String>{},
    this.styles = const <String>{},
    this.website = '',
    this.email = '',
    this.imageBytes,
    this.imageName,
    this.imagePath,
  });

  final String name;
  final String location;
  final String aboutWork;
  final Set<String> types;
  final Set<String> styles;
  final String website;
  final String email;

  /// In-memory preview/upload source used consistently on Android and iOS.
  final Uint8List? imageBytes;
  final String? imageName;

  /// Native image path retained for later multipart-upload optimization.
  final String? imagePath;

  MakerRegistrationDraft copyWith({
    String? name,
    String? location,
    String? aboutWork,
    Set<String>? types,
    Set<String>? styles,
    String? website,
    String? email,
    Uint8List? imageBytes,
    String? imageName,
    String? imagePath,
    bool clearImage = false,
  }) {
    return MakerRegistrationDraft(
      name: name ?? this.name,
      location: location ?? this.location,
      aboutWork: aboutWork ?? this.aboutWork,
      types: types ?? this.types,
      styles: styles ?? this.styles,
      website: website ?? this.website,
      email: email ?? this.email,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      imageName: clearImage ? null : (imageName ?? this.imageName),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }
}

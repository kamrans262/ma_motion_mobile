class PublicMakerDetail {
  const PublicMakerDetail({
    required this.id,
    required this.name,
    this.bio,
    this.location,
    this.profileImageUrl,
    this.savedCount = 0,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? bio;
  final String? location;
  final String? profileImageUrl;
  final int savedCount;
  final DateTime? createdAt;

  factory PublicMakerDetail.fromMap(Map<String, dynamic> map) {
    return PublicMakerDetail(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      name: map['name']?.toString() ?? '',
      bio: _nullable(map['bio']),
      location: _nullable(map['location']),
      profileImageUrl: _nullable(map['profile_image_url']),
      savedCount: int.tryParse(map['saved_count']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  static String? _nullable(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

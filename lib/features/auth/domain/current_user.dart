class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive,
    this.profileImageUrl,
  });

  final int? id;
  final String name;
  final String email;
  final String role;
  final bool? isActive;
  final String? profileImageUrl;

  bool get isMaker => role.toLowerCase() == 'maker';
  bool get isAppreciator => role.toLowerCase() == 'appreciator';

  factory CurrentUser.fromMap(Map<String, dynamic> map) {
    int? asInt(Object? value) {
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString() ?? '');
    }

    bool? asBool(Object? value) {
      if (value is bool) {
        return value;
      }
      if (value == 1 || value == '1') {
        return true;
      }
      if (value == 0 || value == '0') {
        return false;
      }
      return null;
    }

    return CurrentUser(
      id: asInt(map['id']),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      isActive: asBool(map['is_active'] ?? map['active']),
      profileImageUrl:
          map['profile_image_url']?.toString() ??
          map['profile_image']?.toString(),
    );
  }
}

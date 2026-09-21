class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive,
    this.hasPassword = true,
    this.profileImageUrl,
    this.makerRegistered = false,
    this.makerOnboardingCompleted = false,
    this.appreciatorRegistered = false,
    this.appreciatorOnboardingCompleted = false,
    this.makerLocation = '',
    this.appreciatorLocation = '',
    this.makerBio = '',
    this.makerProfileImageUrl,
  });

  final int? id;
  final String name;
  final String email;
  final String role;
  final bool? isActive;
  final bool hasPassword;
  final String? profileImageUrl;
  final bool makerRegistered;
  final bool makerOnboardingCompleted;
  final bool appreciatorRegistered;
  final bool appreciatorOnboardingCompleted;
  final String makerLocation;
  final String appreciatorLocation;
  final String makerBio;
  final String? makerProfileImageUrl;

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

    Map<String, dynamic> nested(Object? value) {
      return value is Map
          ? Map<String, dynamic>.from(value)
          : const <String, dynamic>{};
    }

    final makerProfile = nested(map['maker_profile']);
    final appreciatorProfile = nested(map['appreciator_profile']);

    return CurrentUser(
      id: asInt(map['id']),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      isActive: asBool(map['is_active'] ?? map['active']),
      hasPassword: asBool(map['has_password']) ?? true,
      profileImageUrl:
          map['profile_image_url']?.toString() ??
          map['profile_image']?.toString(),
      makerRegistered: asBool(map['maker_registered']) ?? false,
      makerOnboardingCompleted:
          asBool(map['maker_onboarding_completed']) ?? false,
      appreciatorRegistered: asBool(map['appreciator_registered']) ?? false,
      appreciatorOnboardingCompleted:
          asBool(map['appreciator_onboarding_completed']) ?? false,
      makerLocation:
          (makerProfile['location_text'] ?? makerProfile['location'] ?? '')
              .toString(),
      appreciatorLocation: (appreciatorProfile['location_text'] ?? '')
          .toString(),
      makerBio: (makerProfile['bio'] ?? '').toString(),
      makerProfileImageUrl: makerProfile['profile_image_url']?.toString(),
    );
  }
}

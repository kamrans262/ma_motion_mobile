class AppreciatorSettingsData {
  const AppreciatorSettingsData({
    required this.name,
    required this.email,
    required this.locationText,
    this.locationId,
    this.onboardingCompleted = false,
  });

  final String name;
  final String email;
  final String locationText;
  final int? locationId;
  final bool onboardingCompleted;

  factory AppreciatorSettingsData.fromMap(Map<String, dynamic> map) {
    return AppreciatorSettingsData(
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      locationText: map['location_text']?.toString() ?? '',
      locationId: _asInt(map['location_id']),
      onboardingCompleted: _asBool(map['onboarding_completed']),
    );
  }
}

class AppreciatorSettingsDraft {
  const AppreciatorSettingsDraft({
    required this.name,
    required this.email,
    required this.locationText,
    this.locationId,
  });

  final String name;
  final String email;
  final String locationText;
  final int? locationId;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

bool _asBool(Object? value) {
  if (value is bool) {
    return value;
  }

  return value == 1 || value == '1' || value == 'true';
}

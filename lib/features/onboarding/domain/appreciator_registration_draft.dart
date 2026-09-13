class AppreciatorRegistrationDraft {
  const AppreciatorRegistrationDraft({
    this.name = '',
    this.location = '',
    this.email = '',
  });

  final String name;
  final String location;
  final String email;

  AppreciatorRegistrationDraft copyWith({
    String? name,
    String? location,
    String? email,
  }) {
    return AppreciatorRegistrationDraft(
      name: name ?? this.name,
      location: location ?? this.location,
      email: email ?? this.email,
    );
  }
}

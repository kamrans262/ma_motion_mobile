import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/appreciator_registration_draft.dart';

final appreciatorRegistrationProvider =
    NotifierProvider<
      AppreciatorRegistrationController,
      AppreciatorRegistrationDraft
    >(AppreciatorRegistrationController.new);

class AppreciatorRegistrationController
    extends Notifier<AppreciatorRegistrationDraft> {
  @override
  AppreciatorRegistrationDraft build() => const AppreciatorRegistrationDraft();

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  void setLocation(String value) {
    state = state.copyWith(location: value);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value);
  }

  void reset() {
    state = const AppreciatorRegistrationDraft();
  }
}

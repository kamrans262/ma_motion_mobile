import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/maker_registration_draft.dart';

final makerRegistrationProvider =
    NotifierProvider<MakerRegistrationController, MakerRegistrationDraft>(
      MakerRegistrationController.new,
    );

class MakerRegistrationController extends Notifier<MakerRegistrationDraft> {
  @override
  MakerRegistrationDraft build() => const MakerRegistrationDraft();

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  void setLocation(String value) {
    state = state.copyWith(location: value);
  }

  void setAboutWork(String value) {
    state = state.copyWith(aboutWork: value);
  }

  void setWebsite(String value) {
    state = state.copyWith(website: value);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value);
  }

  void setImage({
    required Uint8List bytes,
    required String name,
    String? path,
  }) {
    state = state.copyWith(imageBytes: bytes, imageName: name, imagePath: path);
  }

  void clearImage() {
    state = state.copyWith(clearImage: true);
  }

  void setExistingImageUrl(String value) {
    state = state.copyWith(existingImageUrl: value);
  }

  void setTypes(Set<String> values) {
    state = state.copyWith(types: values);
  }

  void setStyles(Set<String> values) {
    state = state.copyWith(styles: values);
  }

  void toggleType(String value) {
    final next = <String>{...state.types};

    if (!next.add(value)) {
      next.remove(value);
    }

    state = state.copyWith(types: next);
  }

  void toggleStyle(String value) {
    final next = <String>{...state.styles};

    if (!next.add(value)) {
      next.remove(value);
    }

    state = state.copyWith(styles: next);
  }

  void reset() {
    state = const MakerRegistrationDraft();
  }
}

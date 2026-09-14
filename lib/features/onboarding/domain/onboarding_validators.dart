import 'dart:typed_data';

abstract final class OnboardingValidators {
  static const int nameMaxLength = 120;
  static const int locationMaxLength = 180;
  static const int aboutMaxLength = 5000;
  static const int emailMaxLength = 255;
  static const int websiteMaxLength = 2048;
  static const int salonImageMaxBytes = 5 * 1024 * 1024;

  static String? makerName(String value) {
    return _requiredText(
      value,
      emptyMessage: 'Please enter your name or studio name.',
      maxLength: nameMaxLength,
      maxMessage: 'Name or studio name must be 120 characters or fewer.',
    );
  }

  static String? appreciatorName(String value) {
    return _requiredText(
      value,
      emptyMessage: 'Please enter your name.',
      maxLength: nameMaxLength,
      maxMessage: 'Name must be 120 characters or fewer.',
    );
  }

  static String? location(String value) {
    return _requiredText(
      value,
      emptyMessage: 'Please enter your city or ZIP code.',
      maxLength: locationMaxLength,
      maxMessage: 'Location must be 180 characters or fewer.',
    );
  }

  static String? aboutWork(String value) {
    return _requiredText(
      value,
      emptyMessage: 'Please tell us a little about your work.',
      maxLength: aboutMaxLength,
      maxMessage: 'About your work must be 5000 characters or fewer.',
    );
  }

  static String? email(String value) {
    final email = value.trim();

    if (email.isEmpty) {
      return 'Please enter your email address.';
    }

    if (email.length > emailMaxLength) {
      return 'Email address must be 255 characters or fewer.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  static String? website(String value) {
    final website = value.trim();

    if (website.isEmpty) {
      return null;
    }

    if (website.length > websiteMaxLength) {
      return 'Website address must be 2048 characters or fewer.';
    }

    if (website.contains(RegExp(r'\s'))) {
      return 'Please enter a valid website address.';
    }

    final normalized =
        website.startsWith('http://') || website.startsWith('https://')
        ? website
        : 'https://$website';
    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty) {
      return 'Please enter a valid website address.';
    }

    return null;
  }

  static String? makerTypes(Set<String> values) {
    return values.isEmpty ? 'Select at least one type.' : null;
  }

  static String? makerStyles(Set<String> values) {
    return values.isEmpty ? 'Select at least one style.' : null;
  }

  static String? salonImage({
    required Uint8List? bytes,
    required String? fileName,
  }) {
    if (bytes == null || bytes.isEmpty) {
      return 'Please upload your salon image.';
    }

    if (bytes.lengthInBytes > salonImageMaxBytes) {
      return 'Salon image must be 5 MB or smaller.';
    }

    final normalizedName = fileName?.trim().toLowerCase() ?? '';
    final extension = normalizedName.contains('.')
        ? normalizedName.split('.').last
        : '';

    if (!const <String>{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      return 'Salon image must be JPG, PNG, or WebP.';
    }

    return null;
  }

  static String? _requiredText(
    String value, {
    required String emptyMessage,
    required int maxLength,
    required String maxMessage,
  }) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return emptyMessage;
    }

    if (normalized.length > maxLength) {
      return maxMessage;
    }

    return null;
  }
}

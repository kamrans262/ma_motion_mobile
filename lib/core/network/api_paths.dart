abstract final class ApiPaths {
  static const String health = '/health';

  static const String register = '/auth/register';
  static const String makerOnboarding = '/auth/maker-onboarding';
  static const String appreciatorOnboarding = '/auth/appreciator-onboarding';
  static const String login = '/auth/login';
  static const String requestEmailOtp = '/auth/email-otp/request';
  static const String verifyEmailOtp = '/auth/email-otp/verify';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static const String me = '/me';
  static const String experience = '/me/experience';
  static const String makerExperienceOnboarding =
      '/me/experience/maker/onboarding';
  static const String appreciatorExperienceOnboarding =
      '/me/experience/appreciator/onboarding';
  static const String makerProfile = '/me/maker-profile';
  static const String appreciatorProfile = '/me/appreciator-profile';
  static const String profile = '/me/profile';
  static const String profileImage = '/me/profile-image';
  static const String password = '/me/password';
  static const String account = '/me/account';
  static const String makerStatistics = '/me/maker-statistics';
  static const String myArtworks = '/me/artworks';
  static const String savedArtworks = '/me/saved-artworks';

  static const String discovery = '/discovery';
  static const String discoveryArtworks = '/discovery/artworks';
  static const String discoveryMakers = '/discovery/makers';
  static const String discoveryFilters = '/discovery/filters';
  static const String discoveryLocations = '/discovery/locations';
  static const String discoverySearch = '/discovery/search';

  static const String makers = '/makers';

  static String maker(int makerId) => '/makers/$makerId';
  static String makerShows(int makerId) => '/makers/$makerId/shows';
  static String savedArtwork(int artworkId) => '/me/saved-artworks/$artworkId';
}

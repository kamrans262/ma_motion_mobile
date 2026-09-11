abstract interface class AuthTokenStore {
  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

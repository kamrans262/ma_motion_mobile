import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/health/data/health_repository.dart';
import '../config/app_environment.dart';
import '../network/api_gateway.dart';
import '../network/dio_api_gateway.dart';
import '../storage/auth_token_store.dart';
import '../storage/flutter_secure_auth_token_store.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return FlutterSecureAuthTokenStore();
});

final apiGatewayProvider = Provider<ApiGateway>((ref) {
  return DioApiGateway(
    baseUrl: AppEnvironment.apiBaseUrl,
    connectTimeout: AppEnvironment.connectTimeout,
    receiveTimeout: AppEnvironment.receiveTimeout,
    tokenStore: ref.watch(authTokenStoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiGatewayProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
  );
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(api: ref.watch(apiGatewayProvider));
});

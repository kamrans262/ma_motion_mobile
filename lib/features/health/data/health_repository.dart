import '../../../core/network/api_envelope.dart';
import '../../../core/network/api_gateway.dart';
import '../../../core/network/api_paths.dart';

class HealthRepository {
  const HealthRepository({required this.api});

  final ApiGateway api;

  Future<HealthStatus> check() async {
    final response = await api.get(ApiPaths.health, requiresAuth: false);

    final envelope = ApiEnvelope(raw: response);

    return HealthStatus(
      success: envelope.success ?? true,
      message: envelope.message,
      raw: response,
    );
  }
}

class HealthStatus {
  const HealthStatus({required this.success, required this.raw, this.message});

  final bool success;
  final String? message;
  final Map<String, dynamic> raw;
}

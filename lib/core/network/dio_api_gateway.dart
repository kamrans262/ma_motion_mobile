import 'package:dio/dio.dart';

import '../storage/auth_token_store.dart';
import 'api_exception.dart';
import 'api_gateway.dart';

class DioApiGateway implements ApiGateway {
  DioApiGateway({
    required String baseUrl,
    required this.tokenStore,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 30),
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: connectTimeout,
               receiveTimeout: receiveTimeout,
               sendTimeout: connectTimeout,
               headers: const <String, Object>{'Accept': 'application/json'},
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final requiresAuth = options.extra['requiresAuth'] as bool? ?? true;

          if (requiresAuth) {
            final token = await tokenStore.read();

            if (token != null && token.trim().isNotEmpty) {
              options.headers['Authorization'] = 'Bearer ${token.trim()}';
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await tokenStore.clear();
          }

          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final AuthTokenStore tokenStore;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    required bool requiresAuth,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          extra: <String, Object>{'requiresAuth': requiresAuth},
        ),
      );

      final body = response.data;

      if (body == null) {
        return <String, dynamic>{'success': true, 'data': null};
      }

      if (body is Map<String, dynamic>) {
        return body;
      }

      if (body is Map) {
        return Map<String, dynamic>.from(body);
      }

      throw ApiException(
        message: 'The server returned an unexpected response.',
        statusCode: response.statusCode,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

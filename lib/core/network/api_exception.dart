import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const <String, List<String>>{},
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, List<String>> fieldErrors;
  final bool isNetworkError;

  bool get isUnauthenticated => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidation => statusCode == 422;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final body = response?.data;

    final parsed = _parseBody(body);

    final isNetwork =
        response == null &&
        {
          DioExceptionType.connectionError,
          DioExceptionType.connectionTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.unknown,
        }.contains(error.type);

    return ApiException(
      message:
          parsed.message ??
          (isNetwork
              ? 'Unable to reach the server. Check your connection and try again.'
              : 'The request could not be completed.'),
      statusCode: response?.statusCode,
      code: parsed.code,
      fieldErrors: parsed.fieldErrors,
      isNetworkError: isNetwork,
    );
  }

  factory ApiException.fromResponse({
    required int? statusCode,
    required Object? body,
  }) {
    final parsed = _parseBody(body);

    return ApiException(
      message: parsed.message ?? 'The request could not be completed.',
      statusCode: statusCode,
      code: parsed.code,
      fieldErrors: parsed.fieldErrors,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';

  static _ParsedError _parseBody(Object? body) {
    if (body is! Map) {
      return const _ParsedError();
    }

    final map = Map<String, dynamic>.from(body);

    final messageValue = map['message'];
    final codeValue = map['code'];

    final fieldErrors = <String, List<String>>{};
    final rawErrors = map['errors'];

    if (rawErrors is Map) {
      for (final entry in rawErrors.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        if (value is List) {
          fieldErrors[key] = value.map((item) => item.toString()).toList();
        } else if (value != null) {
          fieldErrors[key] = <String>[value.toString()];
        }
      }
    }

    return _ParsedError(
      message: messageValue?.toString(),
      code: codeValue?.toString(),
      fieldErrors: fieldErrors,
    );
  }
}

class _ParsedError {
  const _ParsedError({
    this.message,
    this.code,
    this.fieldErrors = const <String, List<String>>{},
  });

  final String? message;
  final String? code;
  final Map<String, List<String>> fieldErrors;
}

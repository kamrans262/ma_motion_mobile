class ApiEnvelope {
  const ApiEnvelope({required this.raw});

  final Map<String, dynamic> raw;

  bool? get success => raw['success'] as bool?;

  String? get message => raw['message']?.toString();

  Object? get data => raw['data'];

  Map<String, dynamic> get dataMap {
    final value = data;

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  List<dynamic> get dataList {
    final value = data;
    return value is List ? value : const <dynamic>[];
  }

  Map<String, dynamic> get meta {
    final value = raw['meta'];

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }
}

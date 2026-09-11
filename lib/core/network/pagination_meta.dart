class PaginationMeta {
  const PaginationMeta({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
  });

  final int? currentPage;
  final int? lastPage;
  final int? perPage;
  final int? total;

  bool get hasNextPage =>
      currentPage != null && lastPage != null && currentPage! < lastPage!;

  factory PaginationMeta.fromMap(Map<String, dynamic> map) {
    int? asInt(Object? value) {
      if (value is int) {
        return value;
      }
      return int.tryParse(value?.toString() ?? '');
    }

    return PaginationMeta(
      currentPage: asInt(map['current_page'] ?? map['currentPage']),
      lastPage: asInt(map['last_page'] ?? map['lastPage']),
      perPage: asInt(map['per_page'] ?? map['perPage']),
      total: asInt(map['total']),
    );
  }
}

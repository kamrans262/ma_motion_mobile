class MakerCurrentShow {
  const MakerCurrentShow({required this.id, required this.name, this.endDate});

  final int id;
  final String name;
  final DateTime? endDate;

  factory MakerCurrentShow.fromMap(Map<String, dynamic> map) {
    return MakerCurrentShow(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      name: map['name']?.toString() ?? '',
      endDate: DateTime.tryParse(map['end_date']?.toString() ?? ''),
    );
  }
}

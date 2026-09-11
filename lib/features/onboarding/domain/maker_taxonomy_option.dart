class MakerTaxonomyOption {
  const MakerTaxonomyOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  factory MakerTaxonomyOption.fromMap(Map<String, dynamic> map) {
    final id = _asInt(map['id']);
    final name = map['name']?.toString().trim() ?? '';
    final slug = map['slug']?.toString().trim() ?? '';

    if (id == null || name.isEmpty) {
      throw const FormatException('Invalid Maker taxonomy option.');
    }

    return MakerTaxonomyOption(id: id, name: name, slug: slug);
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }
}

class CustomStat {
  final String id;
  final String label;
  final String abbreviation;
  final bool isError;
  final double weight;

  CustomStat({
    required this.id,
    required this.label,
    required this.abbreviation,
    required this.isError,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'abbreviation': abbreviation,
      'isError': isError,
      'weight': weight,
    };
  }

  factory CustomStat.fromMap(Map<dynamic, dynamic> map) {
    return CustomStat(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      abbreviation: map['abbreviation'] as String? ?? '',
      isError: map['isError'] as bool? ?? false,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

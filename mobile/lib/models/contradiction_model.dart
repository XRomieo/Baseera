// models/contradiction_model.dart
// Represents a detected contradiction between two data sources.

class ContradictionModel {
  final String sourceA;
  final String sourceB;
  final String conflict;
  final String resolution;
  final String credibilityWinner;

  const ContradictionModel({
    required this.sourceA,
    required this.sourceB,
    required this.conflict,
    required this.resolution,
    required this.credibilityWinner,
  });

  factory ContradictionModel.fromJson(Map<String, dynamic> json) {
    return ContradictionModel(
      sourceA: json['source_a'] ?? '',
      sourceB: json['source_b'] ?? '',
      conflict: json['conflict'] ?? '',
      resolution: json['resolution'] ?? '',
      credibilityWinner: json['credibility_winner'] ?? '',
    );
  }
}

// models/source_model.dart
// Represents a single data source and its analysis result.

class SourceModel {
  final String name;
  final String keyInsight;
  final SourceCredibility credibility;
  final String recency;
  final String icon; // emoji icon
  final bool isProcessed;

  const SourceModel({
    required this.name,
    required this.keyInsight,
    required this.credibility,
    required this.recency,
    required this.icon,
    this.isProcessed = false,
  });

  SourceModel copyWith({
    String? name,
    String? keyInsight,
    SourceCredibility? credibility,
    String? recency,
    String? icon,
    bool? isProcessed,
  }) {
    return SourceModel(
      name: name ?? this.name,
      keyInsight: keyInsight ?? this.keyInsight,
      credibility: credibility ?? this.credibility,
      recency: recency ?? this.recency,
      icon: icon ?? this.icon,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      name: json['source'] ?? '',
      keyInsight: json['key_insight'] ?? '',
      credibility: SourceCredibility.fromString(json['credibility'] ?? 'MEDIUM'),
      recency: json['recency'] ?? '',
      icon: _iconForSource(json['source'] ?? ''),
      isProcessed: true,
    );
  }

  // UI now renders Lucide icons keyed by source slot; this field is retained
  // for API compatibility but no longer holds an emoji glyph.
  static String _iconForSource(String sourceName) => '';
}

enum SourceCredibility {
  high,
  medium,
  low,
  stale;

  static SourceCredibility fromString(String value) {
    switch (value.toUpperCase()) {
      case 'HIGH':
        return SourceCredibility.high;
      case 'MEDIUM':
        return SourceCredibility.medium;
      case 'LOW':
        return SourceCredibility.low;
      case 'STALE':
        return SourceCredibility.stale;
      default:
        return SourceCredibility.medium;
    }
  }

  String get label {
    switch (this) {
      case SourceCredibility.high:
        return 'HIGH';
      case SourceCredibility.medium:
        return 'MEDIUM';
      case SourceCredibility.low:
        return 'LOW';
      case SourceCredibility.stale:
        return 'STALE';
    }
  }
}

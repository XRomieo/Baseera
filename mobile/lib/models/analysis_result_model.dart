// models/analysis_result_model.dart
// Top-level model for the complete Gemini analysis response.

import 'source_model.dart';
import 'contradiction_model.dart';
import 'action_step_model.dart';

class AnalysisResultModel {
  final List<SourceModel> sourcesSummary;
  final List<String> keyInsights;
  final List<ContradictionModel> contradictions;
  final List<ActionStepModel> actionChain;
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final List<String> agentTrace;
  final bool isFallback;
  final int latencyMs;

  const AnalysisResultModel({
    required this.sourcesSummary,
    required this.keyInsights,
    required this.contradictions,
    required this.actionChain,
    required this.beforeState,
    required this.afterState,
    required this.agentTrace,
    this.isFallback = false,
    this.latencyMs = 0,
  });

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return AnalysisResultModel(
      sourcesSummary: (json['sources_summary'] as List? ?? [])
          .map((s) => SourceModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      keyInsights: (json['key_insights'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      contradictions: (json['contradictions'] as List? ?? [])
          .map((c) => ContradictionModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      actionChain: (json['action_chain'] as List? ?? [])
          .map((a) => ActionStepModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      beforeState: Map<String, dynamic>.from(json['before_state'] ?? {}),
      afterState: Map<String, dynamic>.from(json['after_state'] ?? {}),
      agentTrace: (json['agent_trace'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      isFallback: json['is_fallback'] ?? false,
      latencyMs: json['latency_ms'] ?? 0,
    );
  }
}

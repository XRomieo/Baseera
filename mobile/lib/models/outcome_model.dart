// models/outcome_model.dart
// Represents the before/after outcome comparison.

class OutcomeModel {
  final Map<String, dynamic> beforeState;
  final Map<String, dynamic> afterState;
  final OutcomeMetrics metrics;
  final List<Map<String, dynamic>> stepDetails;

  const OutcomeModel({
    required this.beforeState,
    required this.afterState,
    required this.metrics,
    required this.stepDetails,
  });

  factory OutcomeModel.fromJson(Map<String, dynamic> json) {
    return OutcomeModel(
      beforeState: Map<String, dynamic>.from(json['before_state'] ?? {}),
      afterState: Map<String, dynamic>.from(json['after_state'] ?? {}),
      metrics: OutcomeMetrics.fromJson(json['metrics'] ?? {}),
      stepDetails: (json['step_details'] as List? ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList(),
    );
  }
}

class OutcomeMetrics {
  final int actionsCompleted;
  final int actionsTotal;
  final int costIncurredPkr;
  final int avgStepLatencyMs;
  final int totalExecutionTimeMs;
  final bool step2Retried;
  final int revenueAtRiskPkrDaily;
  final int estimatedRevenueSavedPkr;

  const OutcomeMetrics({
    required this.actionsCompleted,
    required this.actionsTotal,
    required this.costIncurredPkr,
    required this.avgStepLatencyMs,
    required this.totalExecutionTimeMs,
    required this.step2Retried,
    required this.revenueAtRiskPkrDaily,
    required this.estimatedRevenueSavedPkr,
  });

  factory OutcomeMetrics.fromJson(Map<String, dynamic> json) {
    return OutcomeMetrics(
      actionsCompleted: json['actions_completed'] ?? 0,
      actionsTotal: json['actions_total'] ?? 4,
      costIncurredPkr: json['cost_incurred_pkr'] ?? 0,
      avgStepLatencyMs: json['avg_step_latency_ms'] ?? 0,
      totalExecutionTimeMs: json['total_execution_time_ms'] ?? 0,
      step2Retried: json['step_2_retried'] ?? false,
      revenueAtRiskPkrDaily: json['revenue_at_risk_pkr_daily'] ?? 0,
      estimatedRevenueSavedPkr: json['estimated_revenue_saved_pkr'] ?? 0,
    );
  }

  // Default outcome for when API hasn't been called yet
  factory OutcomeMetrics.defaults() {
    return const OutcomeMetrics(
      actionsCompleted: 4,
      actionsTotal: 4,
      costIncurredPkr: 12500,
      avgStepLatencyMs: 2150,
      totalExecutionTimeMs: 14500,
      step2Retried: true,
      revenueAtRiskPkrDaily: 87050,
      estimatedRevenueSavedPkr: 261150,
    );
  }
}

// models/action_step_model.dart
// Represents a single step in the action chain.

class ActionStepModel {
  final int step;
  final String action;
  final StepStatus status;
  final String constraint;
  final String rationale;
  final String? error;
  final String? completionNote;
  final int? latencyMs;
  final int attempts;

  const ActionStepModel({
    required this.step,
    required this.action,
    required this.status,
    required this.constraint,
    required this.rationale,
    this.error,
    this.completionNote,
    this.latencyMs,
    this.attempts = 0,
  });

  ActionStepModel copyWith({
    int? step,
    String? action,
    StepStatus? status,
    String? constraint,
    String? rationale,
    String? error,
    String? completionNote,
    int? latencyMs,
    int? attempts,
  }) {
    return ActionStepModel(
      step: step ?? this.step,
      action: action ?? this.action,
      status: status ?? this.status,
      constraint: constraint ?? this.constraint,
      rationale: rationale ?? this.rationale,
      error: error ?? this.error,
      completionNote: completionNote ?? this.completionNote,
      latencyMs: latencyMs ?? this.latencyMs,
      attempts: attempts ?? this.attempts,
    );
  }

  factory ActionStepModel.fromJson(Map<String, dynamic> json) {
    return ActionStepModel(
      step: json['step'] ?? 0,
      action: json['action'] ?? '',
      status: StepStatus.fromString(json['status'] ?? 'pending'),
      constraint: json['constraint'] ?? '',
      rationale: json['rationale'] ?? '',
    );
  }

  factory ActionStepModel.placeholder(int stepNumber) {
    final actions = [
      'Conduct emergency physical stock audit',
      'Contact supplier and activate emergency procurement',
      'Update customer-facing platforms and send notifications',
      'Activate automated 24-hour inventory monitoring',
    ];
    return ActionStepModel(
      step: stepNumber,
      action: actions[stepNumber - 1],
      status: StepStatus.pending,
      constraint: '',
      rationale: '',
    );
  }
}

enum StepStatus {
  pending,
  running,
  failed,
  retrying,
  completed;

  static StepStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'running':
        return StepStatus.running;
      case 'failed':
        return StepStatus.failed;
      case 'retrying':
        return StepStatus.retrying;
      case 'completed':
        return StepStatus.completed;
      default:
        return StepStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case StepStatus.pending:
        return 'Pending';
      case StepStatus.running:
        return 'Running...';
      case StepStatus.failed:
        return 'Failed';
      case StepStatus.retrying:
        return 'Retrying...';
      case StepStatus.completed:
        return 'Completed';
    }
  }
}

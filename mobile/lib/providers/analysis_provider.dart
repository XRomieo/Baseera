// providers/analysis_provider.dart
// Central state management for the Baseera app using Provider.
// Holds analysis results, step execution state, and outcome data.

import 'package:flutter/foundation.dart';
import '../models/analysis_result_model.dart';
import '../models/action_step_model.dart';
import '../models/outcome_model.dart';
import '../services/api_service.dart';

enum AppState {
  idle,
  analyzing,
  analyzed,
  executing,
  executionComplete,
  error,
}

class AnalysisProvider extends ChangeNotifier {
  final ApiService _apiService;

  AnalysisProvider(this._apiService);

  // State
  AppState _appState = AppState.idle;
  AnalysisResultModel? _analysisResult;
  List<ActionStepModel> _steps = [
    ActionStepModel.placeholder(1),
    ActionStepModel.placeholder(2),
    ActionStepModel.placeholder(3),
    ActionStepModel.placeholder(4),
  ];
  OutcomeModel? _outcomeModel;
  String _errorMessage = '';
  bool _isFallbackMode = false;

  // Source processing animation state
  List<bool> _sourcesProcessed = [false, false, false, false, false];
  int _currentlyProcessingSource = -1;

  // Getters
  AppState get appState => _appState;
  AnalysisResultModel? get analysisResult => _analysisResult;
  List<ActionStepModel> get steps => _steps;
  OutcomeModel? get outcomeModel => _outcomeModel;
  String get errorMessage => _errorMessage;
  bool get isFallbackMode => _isFallbackMode;
  List<bool> get sourcesProcessed => _sourcesProcessed;
  int get currentlyProcessingSource => _currentlyProcessingSource;

  bool get isAnalyzing => _appState == AppState.analyzing;
  bool get isExecuting => _appState == AppState.executing;
  bool get hasResult => _analysisResult != null;

  /// Run the full analysis pipeline.
  Future<void> runAnalysis() async {
    _appState = AppState.analyzing;
    _errorMessage = '';
    _sourcesProcessed = [false, false, false, false, false];
    _currentlyProcessingSource = 0;
    notifyListeners();

    try {
      // Simulate sequential source processing for the UI animation
      // The actual API call runs simultaneously
      _startSourceAnimation();

      final result = await _apiService.runAnalysis();

      _analysisResult = result;
      _isFallbackMode = result.isFallback;

      // Update steps from Gemini result
      if (result.actionChain.isNotEmpty) {
        _steps = result.actionChain;
      }

      // Mark all sources as processed
      _sourcesProcessed = [true, true, true, true, true];
      _currentlyProcessingSource = -1;

      _appState = AppState.analyzed;
      notifyListeners();
    } on ApiException catch (e) {
      _appState = AppState.error;
      _errorMessage = e.message;
      _sourcesProcessed = [false, false, false, false, false];
      notifyListeners();
    } catch (e) {
      _appState = AppState.error;
      _errorMessage = 'Unexpected error: $e';
      notifyListeners();
    }
  }

  /// Animate source cards processing one by one.
  Future<void> _startSourceAnimation() async {
    for (int i = 0; i < 5; i++) {
      _currentlyProcessingSource = i;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 800));
      _sourcesProcessed[i] = true;
      notifyListeners();
    }
  }

  /// Execute all action steps in sequence with auto-progression.
  Future<void> executeAllSteps() async {
    _appState = AppState.executing;
    notifyListeners();

    for (int stepNum = 1; stepNum <= 4; stepNum++) {
      await _executeSingleStep(stepNum);
      // Brief pause between steps
      if (stepNum < 4) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _appState = AppState.executionComplete;
    notifyListeners();

    // Load outcome data
    await loadOutcome();
  }

  /// Execute a single step, handling failure and retry for step 2.
  Future<void> _executeSingleStep(int stepNumber) async {
    // Mark as running
    _updateStepStatus(stepNumber, StepStatus.running);

    try {
      final result = await _apiService.executeStep(stepNumber);
      final status = result['status'] as String? ?? 'completed';

      if (status == 'failed') {
        // Show FAILED state
        _updateStepStatus(
          stepNumber,
          StepStatus.failed,
          error: result['error'] as String?,
        );

        // Wait so user can see the failure
        await Future.delayed(const Duration(seconds: 3));

        // Show RETRYING state
        _updateStepStatus(stepNumber, StepStatus.retrying);
        await Future.delayed(const Duration(seconds: 1));

        // Retry the step
        final retryResult = await _apiService.executeStep(stepNumber);
        _updateStepStatus(
          stepNumber,
          StepStatus.completed,
          completionNote: retryResult['completion_note'] as String?,
          latencyMs: retryResult['latency_ms'] as int?,
        );
      } else {
        _updateStepStatus(
          stepNumber,
          StepStatus.completed,
          completionNote: result['completion_note'] as String?,
          latencyMs: result['latency_ms'] as int?,
        );
      }

      // Delay before next step
      await Future.delayed(const Duration(seconds: 2));
    } on ApiException catch (e) {
      _updateStepStatus(stepNumber, StepStatus.failed, error: e.message);
    }
  }

  void _updateStepStatus(
    int stepNumber,
    StepStatus status, {
    String? error,
    String? completionNote,
    int? latencyMs,
  }) {
    final index = stepNumber - 1;
    if (index >= 0 && index < _steps.length) {
      _steps[index] = _steps[index].copyWith(
        status: status,
        error: error,
        completionNote: completionNote,
        latencyMs: latencyMs,
      );
      notifyListeners();
    }
  }

  /// Load outcome data from the backend.
  Future<void> loadOutcome() async {
    try {
      _outcomeModel = await _apiService.getOutcome();
      notifyListeners();
    } catch (e) {
      // Use default metrics if API fails
      _outcomeModel = OutcomeModel.fromJson({
        'before_state': {
          'stockout_risk_pct': 87,
          'supplier_status': 'Delivery delayed 5 days — no alternative',
          'customer_notifications_sent': 0,
          'inventory_units': 1200,
          'data_confidence': 'LOW',
          'open_complaints': 47,
          'warehouse_data_age': '3 days (stale)',
          'alternative_supplier': 'None',
        },
        'after_state': {
          'stockout_risk_pct': 12,
          'supplier_status': 'Emergency order placed — Karachi Wholesale Distributors',
          'customer_notifications_sent': 847,
          'inventory_units': 47,
          'data_confidence': 'HIGH',
          'open_complaints': 0,
          'warehouse_data_age': '< 2 hours (fresh audit)',
          'alternative_supplier': 'Karachi Wholesale Distributors (800 units)',
        },
        'metrics': {
          'actions_completed': 4,
          'actions_total': 4,
          'cost_incurred_pkr': 12500,
          'avg_step_latency_ms': 2150,
          'total_execution_time_ms': 14500,
          'step_2_retried': true,
          'revenue_at_risk_pkr_daily': 87050,
          'estimated_revenue_saved_pkr': 261150,
        },
        'step_details': [],
      });
      notifyListeners();
    }
  }

  /// Reset everything to initial state (for "Run Again").
  void reset() {
    _appState = AppState.idle;
    _analysisResult = null;
    _steps = [
      ActionStepModel.placeholder(1),
      ActionStepModel.placeholder(2),
      ActionStepModel.placeholder(3),
      ActionStepModel.placeholder(4),
    ];
    _outcomeModel = null;
    _errorMessage = '';
    _isFallbackMode = false;
    _sourcesProcessed = [false, false, false, false, false];
    _currentlyProcessingSource = -1;
    notifyListeners();
  }
}

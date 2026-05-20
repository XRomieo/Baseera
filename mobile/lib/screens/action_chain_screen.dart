// screens/action_chain_screen.dart
// Screen 3: Action Chain Execution
// Vertical stepper showing 4 steps executing in sequence.
// Step 2 shows FAILED → RETRYING → COMPLETED for failure recovery demo.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/action_step_model.dart';
import '../providers/analysis_provider.dart';

class ActionChainScreen extends StatefulWidget {
  const ActionChainScreen({super.key});

  @override
  State<ActionChainScreen> createState() => _ActionChainScreenState();
}

class _ActionChainScreenState extends State<ActionChainScreen> {
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    // Auto-start execution after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startExecution();
    });
  }

  Future<void> _startExecution() async {
    if (_hasStarted) return;
    _hasStarted = true;

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      context.read<AnalysisProvider>().executeAllSteps();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AnalysisProvider>();
    final steps = provider.steps;
    final isComplete = provider.appState == AppState.executionComplete;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Action Chain'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isComplete
                        ? '✓ All 4 actions completed successfully'
                        : 'Autonomous execution in progress...',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isComplete ? colors.success : colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Steps
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...List.generate(steps.length, (index) {
                  final step = steps[index];
                  final isLast = index == steps.length - 1;
                  return _buildStepItem(
                    context: context,
                    step: step,
                    isLast: isLast,
                    colors: colors,
                  );
                }),

                const SizedBox(height: 16),

                // Step 2 failure explanation
                if (_hasStep2RetryOccurred(steps))
                  _buildRetryExplanation(colors)
                      .animate()
                      .fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                // Navigate to outcome
                if (isComplete)
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/outcome'),
                    icon: const Icon(Icons.dashboard_rounded),
                    label: const Text('View Outcome Dashboard'),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasStep2RetryOccurred(List<ActionStepModel> steps) {
    if (steps.length < 2) return false;
    final step2 = steps[1];
    return step2.status == StepStatus.completed && step2.attempts > 1 ||
        step2.status == StepStatus.completed && step2.completionNote != null;
  }

  Widget _buildStepItem({
    required BuildContext context,
    required ActionStepModel step,
    required bool isLast,
    required AppColors colors,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                _buildStepIcon(step, colors),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _lineColor(step, colors),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStepCard(context, step, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(ActionStepModel step, AppColors colors) {
    Widget child;
    Color bg;
    Color border;

    switch (step.status) {
      case StepStatus.pending:
        child = Text(
          '${step.step}',
          style: GoogleFonts.outfit(
            color: Colors.black38,
            fontWeight: FontWeight.w700,
          ),
        );
        bg = Colors.grey.shade100;
        border = Colors.grey.shade300;
      case StepStatus.running:
        child = SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(colors.primary),
          ),
        );
        bg = colors.primary.withValues(alpha: 0.1);
        border = colors.primary;
      case StepStatus.failed:
        child = Icon(Icons.close_rounded, color: colors.error, size: 20);
        bg = colors.error.withValues(alpha: 0.1);
        border = colors.error;
      case StepStatus.retrying:
        child = Icon(Icons.refresh_rounded, color: colors.warning, size: 20);
        bg = colors.warning.withValues(alpha: 0.1);
        border = colors.warning;
      case StepStatus.completed:
        child = Icon(Icons.check_rounded, color: colors.success, size: 20);
        bg = colors.success.withValues(alpha: 0.1);
        border = colors.success;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    ActionStepModel step,
    AppColors colors,
  ) {
    final statusColor = _statusColor(step.status, colors);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                Text(
                  'Step ${step.step}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.primary.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(step.status, statusColor),
              ],
            ),
            const SizedBox(height: 8),

            // Action description
            Text(
              step.action,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 8),

            // Constraint
            if (step.constraint.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: Colors.black38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      step.constraint,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),

            // Error message
            if (step.status == StepStatus.failed && step.error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 16, color: colors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.error!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Retrying message
            if (step.status == StepStatus.retrying) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 16, color: colors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Retrying via email fallback channel...',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: colors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Completion note
            if (step.status == StepStatus.completed &&
                step.completionNote != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 16, color: colors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.completionNote!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Latency
            if (step.latencyMs != null && step.status == StepStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⏱ ${step.latencyMs}ms',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.black38,
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate(target: step.status != StepStatus.pending ? 1 : 0)
        .custom(
          builder: (context, value, child) => child!,
        );
  }

  Widget _buildStatusChip(StepStatus status, Color color) {
    String icon;
    switch (status) {
      case StepStatus.pending:
        icon = '🕐';
      case StepStatus.running:
        icon = '⟳';
      case StepStatus.failed:
        icon = '✗';
      case StepStatus.retrying:
        icon = '↺';
      case StepStatus.completed:
        icon = '✓';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$icon ${status.label}',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRetryExplanation(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.success.withValues(alpha: 0.08),
            colors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded,
                  color: colors.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Autonomous Recovery Demonstrated',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Step 2 failed on first attempt (Supplier API timeout). '
            'The agent automatically detected the failure and retried using '
            'the email fallback channel — completing the action without any human intervention.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(StepStatus status, AppColors colors) {
    switch (status) {
      case StepStatus.pending:
        return Colors.grey;
      case StepStatus.running:
        return colors.primary;
      case StepStatus.failed:
        return colors.error;
      case StepStatus.retrying:
        return colors.warning;
      case StepStatus.completed:
        return colors.success;
    }
  }

  Color _lineColor(ActionStepModel step, AppColors colors) {
    if (step.status == StepStatus.completed) return colors.success;
    if (step.status == StepStatus.running) return colors.primary;
    return Colors.grey.shade200;
  }
}

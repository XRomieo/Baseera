// screens/action_chain_screen.dart
// Screen 3: Action Chain Execution
// Royal dark theme: gradient step circles, glowing status dots, dashed connector,
// spinning Lucide loader during execution.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/action_step_model.dart';
import '../providers/analysis_provider.dart';

class ActionChainScreen extends StatefulWidget {
  const ActionChainScreen({super.key});

  @override
  State<ActionChainScreen> createState() => _ActionChainScreenState();
}

class _ActionChainScreenState extends State<ActionChainScreen>
    with TickerProviderStateMixin {
  bool _hasStarted = false;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startExecution();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
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
    final provider = context.watch<AnalysisProvider>();
    final steps = provider.steps;
    final isComplete = provider.appState == AppState.executionComplete;

    return Scaffold(
      backgroundColor: BaseeraColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.gitBranch,
                color: BaseeraColors.primaryGlow, size: 20),
            const SizedBox(width: 8),
            Text(
              'Action Chain',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BaseeraColors.textPrimary,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: BaseeraColors.primaryGlow),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isComplete
                  ? BaseeraColors.success.withValues(alpha: 0.10)
                  : BaseeraColors.primary.withValues(alpha: 0.10),
              border: Border(
                bottom: BorderSide(
                  color: isComplete
                      ? BaseeraColors.success.withValues(alpha: 0.4)
                      : BaseeraColors.primary.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isComplete
                      ? LucideIcons.checkCircle
                      : LucideIcons.sparkles,
                  color: isComplete
                      ? BaseeraColors.success
                      : BaseeraColors.primaryGlow,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isComplete
                        ? 'All 4 actions completed successfully'
                        : 'Autonomous execution in progress...',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isComplete
                          ? BaseeraColors.success
                          : BaseeraColors.primaryGlow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...List.generate(steps.length, (index) {
                  final step = steps[index];
                  final isLast = index == steps.length - 1;
                  return _buildStepItem(
                    step: step,
                    isLast: isLast,
                  );
                }),
                const SizedBox(height: 16),
                if (_hasStep2RetryOccurred(steps))
                  _buildRetryExplanation().animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                if (isComplete)
                  _gradientButton(
                    icon: LucideIcons.barChart2,
                    label: 'View Outcome Dashboard',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/outcome'),
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
    required ActionStepModel step,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                _buildStepNumberCircle(step),
                if (!isLast)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: CustomPaint(
                        size: const Size(2, double.infinity),
                        painter: _DashedLinePainter(
                          color: _lineColor(step),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStepCard(step),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNumberCircle(ActionStepModel step) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BaseeraColors.primary, BaseeraColors.primaryGlow],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: BaseeraColors.primaryGlow.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${step.step}',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(ActionStepModel step) {
    final statusColor = _statusColor(step.status);
    final isStep2 = step.step == 2;
    final isFailedNow = step.status == StepStatus.failed;
    final isRetrying = step.status == StepStatus.retrying;
    final isCompleted = step.status == StepStatus.completed;

    Color cardBg = BaseeraColors.surface;
    if (isStep2 && (isFailedNow || isRetrying)) {
      cardBg = BaseeraColors.redTint;
    } else if (isStep2 && isCompleted) {
      cardBg = BaseeraColors.greenTint;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: cardBg,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: statusColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Step ${step.step}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BaseeraColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(step.status, statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.action,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BaseeraColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            if (step.constraint.isNotEmpty)
              Row(
                children: [
                  const Icon(LucideIcons.info,
                      size: 13, color: BaseeraColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      step.constraint,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: BaseeraColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            if (step.status == StepStatus.failed && step.error != null) ...[
              const SizedBox(height: 10),
              _noteBox(
                icon: LucideIcons.xCircle,
                color: BaseeraColors.error,
                text: step.error!,
              ),
            ],
            if (step.status == StepStatus.retrying) ...[
              const SizedBox(height: 10),
              _noteBox(
                icon: LucideIcons.refreshCw,
                color: BaseeraColors.goldGlow,
                text: 'Retrying via email fallback channel...',
                spinIcon: true,
              ),
            ],
            if (step.status == StepStatus.completed &&
                step.completionNote != null) ...[
              const SizedBox(height: 10),
              _noteBox(
                icon: LucideIcons.checkCircle,
                color: BaseeraColors.success,
                text: step.completionNote!,
              ),
            ],
            if (step.latencyMs != null && step.status == StepStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(LucideIcons.timer,
                        size: 12, color: BaseeraColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${step.latencyMs}ms',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: BaseeraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteBox({
    required IconData icon,
    required Color color,
    required String text,
    bool spinIcon = false,
  }) {
    final iconWidget = Icon(icon, size: 16, color: color);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          spinIcon
              ? AnimatedBuilder(
                  animation: _spinController,
                  builder: (_, __) => Transform.rotate(
                    angle: _spinController.value * 2 * math.pi,
                    child: iconWidget,
                  ),
                )
              : iconWidget,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(StepStatus status, Color color) {
    IconData icon;
    bool spin = false;
    switch (status) {
      case StepStatus.pending:
        icon = LucideIcons.clock;
      case StepStatus.running:
        icon = LucideIcons.loader;
        spin = true;
      case StepStatus.failed:
        icon = LucideIcons.xCircle;
      case StepStatus.retrying:
        icon = LucideIcons.refreshCw;
        spin = true;
      case StepStatus.completed:
        icon = LucideIcons.checkCircle;
    }

    Widget iconWidget = Icon(icon, color: color, size: 12);
    if (spin) {
      iconWidget = RotationTransition(
        turns: _spinController,
        child: iconWidget,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          iconWidget,
          const SizedBox(width: 4),
          Text(
            status.label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryExplanation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BaseeraColors.primary.withValues(alpha: 0.15),
            BaseeraColors.primaryGlow.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: BaseeraColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles,
                  color: BaseeraColors.goldGlow, size: 18),
              const SizedBox(width: 8),
              Text(
                'Autonomous Recovery Demonstrated',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BaseeraColors.goldGlow,
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
              color: BaseeraColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(StepStatus status) {
    switch (status) {
      case StepStatus.pending:
        return BaseeraColors.textSecondary;
      case StepStatus.running:
        return BaseeraColors.primaryGlow;
      case StepStatus.failed:
        return BaseeraColors.error;
      case StepStatus.retrying:
        return BaseeraColors.goldGlow;
      case StepStatus.completed:
        return BaseeraColors.success;
    }
  }

  Color _lineColor(ActionStepModel step) {
    if (step.status == StepStatus.completed) return BaseeraColors.success;
    if (step.status == StepStatus.running) return BaseeraColors.primaryGlow;
    if (step.status == StepStatus.failed) return BaseeraColors.error;
    if (step.status == StepStatus.retrying) return BaseeraColors.goldGlow;
    return BaseeraColors.border;
  }

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BaseeraColors.primary, BaseeraColors.primaryGlow],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: BaseeraColors.primaryGlow.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const dashH = 4.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashH),
        paint,
      );
      startY += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) =>
      old.color != color;
}

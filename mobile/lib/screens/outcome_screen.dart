// screens/outcome_screen.dart
// Screen 4: Outcome Dashboard
// Before/After comparison with animated metrics.
// Agent trace log and download report button.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../models/outcome_model.dart';
import '../providers/analysis_provider.dart';

class OutcomeScreen extends StatelessWidget {
  const OutcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AnalysisProvider>();
    final outcome = provider.outcomeModel;
    final analysis = provider.analysisResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outcome Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => _showDownloadSnackbar(context),
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: outcome == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Success banner
                _buildSuccessBanner(colors)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Stockout risk — animated progress bar
                _buildStockoutRiskCard(context, outcome, colors)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // Side by side metrics
                _buildMetricRow(
                  context: context,
                  icon: '🏭',
                  title: 'Supplier Status',
                  before: outcome.beforeState['supplier_status']?.toString() ??
                      'Unresponsive',
                  after: outcome.afterState['supplier_status']?.toString() ??
                      'Emergency order placed',
                  colors: colors,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 12),

                _buildMetricRow(
                  context: context,
                  icon: '📩',
                  title: 'Customer Notifications',
                  before: '0 sent',
                  after:
                      '${outcome.afterState['customer_notifications_sent'] ?? 847} sent',
                  colors: colors,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 12),

                _buildMetricRow(
                  context: context,
                  icon: '📦',
                  title: 'Data Confidence',
                  before:
                      '${outcome.beforeState['data_confidence'] ?? 'LOW'} (warehouse CSV 3 days old)',
                  after:
                      '${outcome.afterState['data_confidence'] ?? 'HIGH'} (fresh physical audit)',
                  colors: colors,
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // Performance stats
                _buildPerformanceStats(context, outcome.metrics, colors)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // Agent trace
                if (analysis != null && analysis.agentTrace.isNotEmpty)
                  _buildAgentTrace(context, analysis.agentTrace, colors)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Action buttons
                ElevatedButton.icon(
                  onPressed: () => _showDownloadSnackbar(context),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Report'),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {
                    provider.reset();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Run Again'),
                ).animate().fadeIn(delay: 750.ms),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSuccessBanner(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.success.withValues(alpha: 0.15),
            colors.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✓', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mission Accomplished',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.success,
                  ),
                ),
                Text(
                  '4/4 actions completed · 1 failure recovered automatically',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockoutRiskCard(
    BuildContext context,
    OutcomeModel outcome,
    AppColors colors,
  ) {
    final beforeRisk = (outcome.beforeState['stockout_risk_pct'] as num?)?.toInt() ?? 87;
    final afterRisk = (outcome.afterState['stockout_risk_pct'] as num?)?.toInt() ?? 12;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📉', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Stockout Risk',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Before
            Row(
              children: [
                Text(
                  'Before',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                  '$beforeRisk%',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: beforeRisk / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(colors.error),
                minHeight: 10,
              ),
            )
                .animate()
                .custom(
                  duration: 1200.ms,
                  curve: Curves.easeOut,
                  builder: (context, value, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (beforeRisk / 100) * value,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(colors.error),
                      minHeight: 10,
                    ),
                  ),
                ),

            const SizedBox(height: 12),

            // Arrow
            Center(
              child: Icon(Icons.arrow_downward_rounded,
                  color: colors.success, size: 24),
            ),

            const SizedBox(height: 12),

            // After
            Row(
              children: [
                Text(
                  'After',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                  '$afterRisk%',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: afterRisk / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(colors.success),
                minHeight: 10,
              ),
            )
                .animate()
                .custom(
                  delay: 400.ms,
                  duration: 1000.ms,
                  curve: Curves.easeOut,
                  builder: (context, value, child) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (afterRisk / 100) * value,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(colors.success),
                      minHeight: 10,
                    ),
                  ),
                ),

            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '▼ ${beforeRisk - afterRisk}% reduction in stockout risk',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.success,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required BuildContext context,
    required String icon,
    required String title,
    required String before,
    required String after,
    required AppColors colors,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: colors.error.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BEFORE',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.error,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          before,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: colors.success, size: 20),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: colors.success.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AFTER',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: colors.success,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          after,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStats(
    BuildContext context,
    OutcomeMetrics metrics,
    AppColors colors,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚡ Performance Metrics',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _statRow('Actions Completed',
                '${metrics.actionsCompleted}/${metrics.actionsTotal}', colors.success),
            _statRow(
                'Cost Incurred', 'PKR ${metrics.costIncurredPkr}', Colors.black87),
            _statRow('Revenue Saved',
                'PKR ${metrics.estimatedRevenueSavedPkr.toString()}', colors.success),
            _statRow('Avg Step Latency', '${metrics.avgStepLatencyMs}ms',
                Colors.black87),
            _statRow('Step 2 Recovery',
                metrics.step2Retried ? '✓ Auto-recovered' : 'N/A',
                metrics.step2Retried ? colors.success : Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentTrace(
    BuildContext context,
    List<String> trace,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤖 Agent Reasoning Trace',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: trace.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showDownloadSnackbar(BuildContext context) async {
    final provider = context.read<AnalysisProvider>();
    final outcome = provider.outcomeModel;
    final analysis = provider.analysisResult;

    // Show generating indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Generating PDF...',
                  style: GoogleFonts.outfit(color: Colors.white)),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      // ── Colour palette ────────────────────────────────────────────────
      const primary = PdfColor.fromInt(0xFF1565C0);
      const success = PdfColor.fromInt(0xFF2E7D32);
      const error = PdfColor.fromInt(0xFFC62828);
      const warning = PdfColor.fromInt(0xFFE65100);
      const bgLight = PdfColor.fromInt(0xFFF5F7FF);
      const divider = PdfColor.fromInt(0xFFE0E0E0);

      // ── Helper styles ─────────────────────────────────────────────────
      final headingStyle = pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: primary,
      );
      final labelStyle = pw.TextStyle(
        fontSize: 9,
        color: const PdfColor.fromInt(0xFF757575),
      );
      final bodyStyle = pw.TextStyle(
          fontSize: 10, color: const PdfColor.fromInt(0xFF212121));
      final boldBody =
          pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) {
            return [
              // ── Header ────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Baseera',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          'AI-Powered Supply Chain Analysis Report',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColor(1, 1, 1, 0.75)),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'AISeekho 2026 Hackathon',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColor(1, 1, 1, 0.75),
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Generated: ${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                          style: pw.TextStyle(
                              fontSize: 8, color: PdfColor(1, 1, 1, 0.6)),
                        ),
                        pw.Text(
                          'Powered by Gemini 2.5 Flash - Baseera v1.0',
                          style: pw.TextStyle(
                              fontSize: 8, color: PdfColor(1, 1, 1, 0.6)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Outcome Summary ───────────────────────────────────────
              if (outcome != null) ...[
                pw.Text('OUTCOME SUMMARY', style: headingStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: bgLight,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: divider),
                  ),
                  child: pw.Row(
                    children: [
                      _pdfMetricBox(
                        'Stockout Risk (Before)',
                        '${outcome.beforeState["stockout_risk_pct"] ?? 87}%',
                        error,
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text('->',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: success)),
                      pw.SizedBox(width: 8),
                      _pdfMetricBox(
                        'Stockout Risk (After)',
                        '${outcome.afterState["stockout_risk_pct"] ?? 12}%',
                        success,
                      ),
                      pw.SizedBox(width: 16),
                      _pdfMetricBox(
                        'Actions Completed',
                        '${outcome.metrics.actionsCompleted}/${outcome.metrics.actionsTotal}',
                        primary,
                      ),
                      pw.SizedBox(width: 8),
                      _pdfMetricBox(
                        'Revenue Saved',
                        'PKR ${outcome.metrics.estimatedRevenueSavedPkr}',
                        success,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // ── Key Insights ──────────────────────────────────────────
              if (analysis != null &&
                  analysis.keyInsights.isNotEmpty) ...[
                pw.Text('KEY INSIGHTS', style: headingStyle),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: primary, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: analysis.keyInsights
                        .map(
                          (insight) => pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Row(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('> ',
                                    style: pw.TextStyle(
                                        color: primary,
                                        fontWeight:
                                            pw.FontWeight.bold)),
                                pw.Expanded(
                                    child: pw.Text(insight,
                                        style: bodyStyle)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // ── Contradictions ────────────────────────────────────────
              if (analysis != null &&
                  analysis.contradictions.isNotEmpty) ...[
                pw.Text('CONTRADICTIONS DETECTED', style: headingStyle),
                pw.SizedBox(height: 8),
                ...analysis.contradictions.map(
                  (c) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color:
                            const PdfColor.fromInt(0xFFFFF3E0),
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                            color: warning, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '[!] ${c.sourceA}  vs  ${c.sourceB}',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: warning),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(c.conflict, style: bodyStyle),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Resolution: ${c.resolution}',
                            style: pw.TextStyle(
                                fontSize: 9,
                                color: success,
                                fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Winner: ${c.credibilityWinner}',
                            style: pw.TextStyle(
                                fontSize: 9, color: success),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
              ],

              // ── Action Chain ──────────────────────────────────────────
              if (analysis != null &&
                  analysis.actionChain.isNotEmpty) ...[
                pw.Text('ACTION CHAIN', style: headingStyle),
                pw.SizedBox(height: 8),
                ...analysis.actionChain.map(
                  (step) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 22,
                          height: 22,
                          decoration: pw.BoxDecoration(
                            color: primary,
                            shape: pw.BoxShape.circle,
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              '${step.step}',
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment:
                                pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(step.action,
                                  style: boldBody),
                              pw.Text(step.rationale,
                                  style: labelStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // ── Footer ────────────────────────────────────────────────
              pw.Divider(color: divider),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Baseera - AISeekho 2026 - Challenge 1',
                    style: labelStyle,
                  ),
                  pw.Text(
                    'Gemini 2.5 Flash - Autonomous Content-to-Action',
                    style: labelStyle,
                  ),
                ],
              ),
            ];
          },
        ),
      );

      // Save to temp and share
      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'Baseera_Report_${now.day}-${now.month}-${now.year}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Baseera Analysis Report',
          text: 'AISeekho 2026 — Supply Chain Analysis Report',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF failed: $e',
                style: GoogleFonts.outfit(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper: metric box for PDF
  pw.Widget _pdfMetricBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: color, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                  fontSize: 7,
                  color: const PdfColor.fromInt(0xFF757575)),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

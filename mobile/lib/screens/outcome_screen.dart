// screens/outcome_screen.dart
// Screen 4: Outcome Dashboard
// Royal dark theme: gradient header, red/green tinted metric cards,
// gold-bordered download button, restyled PDF.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../models/outcome_model.dart';
import '../providers/analysis_provider.dart';

class OutcomeScreen extends StatelessWidget {
  const OutcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final outcome = provider.outcomeModel;
    final analysis = provider.analysisResult;

    return Scaffold(
      backgroundColor: BaseeraColors.bg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.eye,
                color: BaseeraColors.primaryGlow, size: 20),
            const SizedBox(width: 8),
            Text(
              'Outcome Dashboard',
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
        actions: [
          IconButton(
            onPressed: () => _showDownloadSnackbar(context),
            icon: const Icon(LucideIcons.download,
                color: BaseeraColors.gold),
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: outcome == null
          ? const Center(
              child: CircularProgressIndicator(
                color: BaseeraColors.primaryGlow,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSuccessBanner()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0),
                const SizedBox(height: 20),
                _buildBeforeAfterHeader()
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 400.ms),
                const SizedBox(height: 12),
                _buildStockoutRiskCard(context, outcome)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 12),
                _buildMetricRow(
                  icon: LucideIcons.factory,
                  title: 'Supplier Status',
                  before: outcome.beforeState['supplier_status']?.toString() ??
                      'Unresponsive',
                  after: outcome.afterState['supplier_status']?.toString() ??
                      'Emergency order placed',
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 12),
                _buildMetricRow(
                  icon: LucideIcons.mail,
                  title: 'Customer Notifications',
                  before: '0 sent',
                  after:
                      '${outcome.afterState['customer_notifications_sent'] ?? 847} sent',
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 12),
                _buildMetricRow(
                  icon: LucideIcons.package,
                  title: 'Data Confidence',
                  before:
                      '${outcome.beforeState['data_confidence'] ?? 'LOW'} (warehouse CSV 3 days old)',
                  after:
                      '${outcome.afterState['data_confidence'] ?? 'HIGH'} (fresh physical audit)',
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                const SizedBox(height: 20),
                _buildPerformanceStats(outcome.metrics)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),
                const SizedBox(height: 20),
                if (analysis != null && analysis.agentTrace.isNotEmpty)
                  _buildAgentTrace(analysis.agentTrace)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms),
                const SizedBox(height: 24),
                _buildDownloadButton(context)
                    .animate()
                    .fadeIn(delay: 700.ms),
                const SizedBox(height: 12),
                _buildRunAgainButton(context, provider)
                    .animate()
                    .fadeIn(delay: 750.ms),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BaseeraColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: BaseeraColors.success.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BaseeraColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: BaseeraColors.success, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: BaseeraColors.success.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Icon(LucideIcons.checkCircle,
                  color: BaseeraColors.success, size: 26),
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
                    color: BaseeraColors.success,
                  ),
                ),
                Text(
                  '4/4 actions completed · 1 failure recovered automatically',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: BaseeraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfterHeader() {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [BaseeraColors.gold, BaseeraColors.goldGlow],
      ).createShader(rect),
      child: Text(
        'Before vs After',
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildStockoutRiskCard(BuildContext context, OutcomeModel outcome) {
    final beforeRisk =
        (outcome.beforeState['stockout_risk_pct'] as num?)?.toInt() ?? 87;
    final afterRisk =
        (outcome.afterState['stockout_risk_pct'] as num?)?.toInt() ?? 12;

    return Container(
      decoration: BoxDecoration(
        color: BaseeraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaseeraColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trendingDown,
                  color: BaseeraColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Stockout Risk',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BaseeraColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _riskRow('Before', beforeRisk, BaseeraColors.error),
          const SizedBox(height: 12),
          const Center(
            child: Icon(LucideIcons.arrowDown,
                color: BaseeraColors.success, size: 22),
          ),
          const SizedBox(height: 12),
          _riskRow('After', afterRisk, BaseeraColors.success),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: BaseeraColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: BaseeraColors.success.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.trendingDown,
                      color: BaseeraColors.success, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${beforeRisk - afterRisk}% reduction in stockout risk',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: BaseeraColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskRow(String label, int risk, Color accent) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: BaseeraColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '$risk%',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 10, color: BaseeraColors.border),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: risk / 100),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, value, child) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: child,
                ),
                child: Container(
                  height: 10,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String title,
    required String before,
    required String after,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BaseeraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaseeraColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: BaseeraColors.primaryGlow, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: BaseeraColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'BEFORE',
                  value: before,
                  bg: BaseeraColors.redTint,
                  borderColor: BaseeraColors.error,
                  trendIcon: LucideIcons.trendingDown,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(LucideIcons.arrowRight,
                    color: BaseeraColors.primaryGlow, size: 20),
              ),
              Expanded(
                child: _metricTile(
                  label: 'AFTER',
                  value: after,
                  bg: BaseeraColors.greenTint,
                  borderColor: BaseeraColors.success,
                  trendIcon: LucideIcons.trendingUp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color bg,
    required Color borderColor,
    required IconData trendIcon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        color: bg,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: borderColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(trendIcon, color: borderColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: borderColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: BaseeraColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
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

  Widget _buildPerformanceStats(OutcomeMetrics metrics) {
    return Container(
      decoration: BoxDecoration(
        color: BaseeraColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BaseeraColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.zap,
                  color: BaseeraColors.goldGlow, size: 18),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [BaseeraColors.gold, BaseeraColors.goldGlow],
                ).createShader(rect),
                child: Text(
                  'Performance Metrics',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _actionsCompletedRow(metrics),
          const Divider(color: BaseeraColors.border, height: 20),
          _statRow('Cost Incurred', 'PKR ${metrics.costIncurredPkr}',
              BaseeraColors.textPrimary),
          _statRow(
              'Revenue Saved',
              'PKR ${metrics.estimatedRevenueSavedPkr}',
              BaseeraColors.success),
          _statRow('Avg Step Latency', '${metrics.avgStepLatencyMs}ms',
              BaseeraColors.textPrimary),
          _statRow(
            'Step 2 Recovery',
            metrics.step2Retried ? 'Auto-recovered' : 'N/A',
            metrics.step2Retried
                ? BaseeraColors.success
                : BaseeraColors.textPrimary,
            valueIcon: metrics.step2Retried
                ? LucideIcons.checkCircle
                : null,
          ),
        ],
      ),
    );
  }

  Widget _actionsCompletedRow(OutcomeMetrics metrics) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            'Actions Completed',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: BaseeraColors.textSecondary,
            ),
          ),
          const Spacer(),
          const Icon(LucideIcons.checkCircle,
              color: BaseeraColors.success, size: 14),
          const SizedBox(width: 6),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [BaseeraColors.gold, BaseeraColors.goldGlow],
            ).createShader(rect),
            child: Text(
              '${metrics.actionsCompleted}/${metrics.actionsTotal}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    String label,
    String value,
    Color valueColor, {
    IconData? valueIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: BaseeraColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (valueIcon != null) ...[
            Icon(valueIcon, color: valueColor, size: 14),
            const SizedBox(width: 4),
          ],
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

  Widget _buildAgentTrace(List<String> trace) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.gitBranch,
                color: BaseeraColors.primaryGlow, size: 18),
            const SizedBox(width: 8),
            Text(
              'Agent Reasoning Trace',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BaseeraColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BaseeraColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BaseeraColors.border, width: 0.5),
          ),
          child: Column(
            children: trace
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(LucideIcons.dot,
                              color: BaseeraColors.primaryGlow, size: 18),
                        ),
                        Expanded(
                          child: Text(
                            step,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: BaseeraColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDownloadSnackbar(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: BaseeraColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BaseeraColors.gold, width: 1),
            boxShadow: [
              BoxShadow(
                color: BaseeraColors.gold.withValues(alpha: 0.2),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.fileText,
                  color: BaseeraColors.gold, size: 20),
              const SizedBox(width: 10),
              Text(
                'Download Report',
                style: GoogleFonts.outfit(
                  color: BaseeraColors.gold,
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

  Widget _buildRunAgainButton(
      BuildContext context, AnalysisProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          provider.reset();
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BaseeraColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.refreshCw,
                  color: BaseeraColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Run Again',
                style: GoogleFonts.outfit(
                  color: BaseeraColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDownloadSnackbar(BuildContext context) async {
    final provider = context.read<AnalysisProvider>();
    final outcome = provider.outcomeModel;
    final analysis = provider.analysisResult;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: BaseeraColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: BaseeraColors.primaryGlow.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          content: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BaseeraColors.primaryGlow,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generating PDF...',
                style: GoogleFonts.outfit(
                    color: BaseeraColors.textPrimary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      // Outfit (Unicode-capable) font for the PDF
      final outfitRegular = await PdfGoogleFonts.outfitRegular();
      final outfitBold = await PdfGoogleFonts.outfitBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: outfitRegular,
          bold: outfitBold,
        ),
      );
      final now = DateTime.now();

      // Royal palette in PDF
      const headerBg = PdfColor.fromInt(0xFF0A0A12);
      const goldAccent = PdfColor.fromInt(0xFFD4A017);
      const primary = PdfColor.fromInt(0xFF6C3FE8);
      const success = PdfColor.fromInt(0xFF00C97A);
      const error = PdfColor.fromInt(0xFFFF4D6D);
      const body = PdfColor.fromInt(0xFF1A1A2E);
      const muted = PdfColor.fromInt(0xFFA89BC2);
      const divider = PdfColor.fromInt(0xFFE0E0E0);

      final headingStyle = pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: primary,
      );
      const labelStyle = pw.TextStyle(fontSize: 9, color: muted);
      const bodyStyle = pw.TextStyle(fontSize: 10, color: body);
      final boldBody = pw.TextStyle(
          fontSize: 10, fontWeight: pw.FontWeight.bold, color: body);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) {
            return [
              // Header bar
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: const pw.BoxDecoration(color: headerBg),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Baseera — Intelligence Report',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'AI-Powered Supply Chain Analysis',
                          style: const pw.TextStyle(
                              fontSize: 9, color: muted),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'AISeekho 2026',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: goldAccent,
                              fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                          style: const pw.TextStyle(fontSize: 8, color: muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Gold accent line below header
              pw.Container(height: 2, color: goldAccent),

              pw.SizedBox(height: 20),

              if (outcome != null) ...[
                pw.Text('OUTCOME SUMMARY', style: headingStyle),
                pw.SizedBox(height: 6),
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      left: pw.BorderSide(color: success, width: 3),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(
                      left: 12, top: 6, bottom: 6),
                  child: pw.Row(
                    children: [
                      _pdfMetricBox(
                        'Stockout Before',
                        '${outcome.beforeState["stockout_risk_pct"] ?? 87}%',
                        error,
                      ),
                      pw.SizedBox(width: 8),
                      _pdfMetricBox(
                        'Stockout After',
                        '${outcome.afterState["stockout_risk_pct"] ?? 12}%',
                        success,
                      ),
                      pw.SizedBox(width: 8),
                      _pdfMetricBox(
                        'Actions',
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

              if (analysis != null && analysis.keyInsights.isNotEmpty) ...[
                pw.Text('KEY INSIGHTS', style: headingStyle),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: divider, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: analysis.keyInsights
                        .map(
                          (insight) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Row(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('- ',
                                    style: pw.TextStyle(
                                        color: primary,
                                        fontWeight: pw.FontWeight.bold)),
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

              if (analysis != null &&
                  analysis.contradictions.isNotEmpty) ...[
                pw.Text('CONTRADICTIONS DETECTED', style: headingStyle),
                pw.SizedBox(height: 6),
                ...analysis.contradictions.map(
                  (c) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          left: pw.BorderSide(color: error, width: 3),
                          top: pw.BorderSide(color: divider, width: 0.5),
                          right: pw.BorderSide(color: divider, width: 0.5),
                          bottom: pw.BorderSide(color: divider, width: 0.5),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${c.sourceA}  vs  ${c.sourceB}',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: error),
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
                            style: const pw.TextStyle(
                                fontSize: 9, color: success),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
              ],

              if (analysis != null &&
                  analysis.actionChain.isNotEmpty) ...[
                pw.Text('ACTION CHAIN', style: headingStyle),
                pw.SizedBox(height: 6),
                ...analysis.actionChain.map(
                  (step) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 22,
                          height: 22,
                          decoration: const pw.BoxDecoration(
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
                              pw.Text(step.action, style: boldBody),
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

              // Footer
              pw.Divider(color: divider),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                    style: labelStyle,
                  ),
                  pw.Text('Powered by Baseera AI', style: labelStyle),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'Baseera_Report_${now.day}-${now.month}-${now.year}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: BaseeraColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                  color: BaseeraColors.success, width: 1),
            ),
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle,
                    color: BaseeraColors.success, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Report saved to Downloads',
                  style: GoogleFonts.outfit(
                    color: BaseeraColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
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
            backgroundColor: BaseeraColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                  color: BaseeraColors.error, width: 1),
            ),
            content: Row(
              children: [
                const Icon(LucideIcons.xCircle,
                    color: BaseeraColors.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PDF failed: $e',
                    style: GoogleFonts.outfit(
                      color: BaseeraColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
              style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColor.fromInt(0xFFA89BC2)),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// screens/sources_screen.dart
// Screen 2: Data Sources
// Royal dark theme: surface cards with purple left border, Lucide source icons,
// shield credibility badges, glowing contradiction card.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../main.dart';
import '../models/source_model.dart';
import '../providers/analysis_provider.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  static const _sourceNames = [
    'warehouse_stock.csv',
    'supplier_email.json',
    'sales_dashboard.json',
    'customer_complaints.json',
    'market_news_feed.json',
  ];

  static const _sourceLabels = [
    'Warehouse Stock',
    'Supplier Email',
    'Sales Dashboard',
    'Customer Complaints',
    'Market News Feed',
  ];

  // Lucide icon + accent color per source slot
  static const _sourceIconData = <_SourceIcon>[
    _SourceIcon(LucideIcons.fileSpreadsheet, BaseeraColors.gold),
    _SourceIcon(LucideIcons.fileJson, BaseeraColors.primaryGlow),
    _SourceIcon(LucideIcons.barChart2, BaseeraColors.primaryGlow),
    _SourceIcon(LucideIcons.mail, BaseeraColors.success),
    _SourceIcon(LucideIcons.newspaper, BaseeraColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();
    final result = provider.analysisResult;

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
              'Data Sources',
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
          if (provider.isFallbackMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BaseeraColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: BaseeraColors.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.alertTriangle,
                          color: BaseeraColors.warning, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'Demo',
                        style: GoogleFonts.outfit(
                          color: BaseeraColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, provider),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            final isProcessed = provider.sourcesProcessed[index];
            final isProcessing = provider.currentlyProcessingSource == index;
            final sourceData =
                result != null && result.sourcesSummary.length > index
                    ? result.sourcesSummary[index]
                    : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSourceCard(
                context: context,
                index: index,
                isProcessed: isProcessed,
                isProcessing: isProcessing,
                sourceData: sourceData,
              ),
            );
          }),
          const SizedBox(height: 8),
          if (result != null && result.contradictions.isNotEmpty) ...[
            _buildContradictionsSection(context, result.contradictions),
            const SizedBox(height: 16),
          ],
          if (result != null && result.keyInsights.isNotEmpty)
            _buildKeyInsights(context, result.keyInsights),
          const SizedBox(height: 16),
          if (result != null)
            _gradientButton(
              icon: LucideIcons.gitBranch,
              label: 'Execute Action Chain',
              onPressed: () => Navigator.pushNamed(context, '/action-chain'),
            )
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AnalysisProvider provider) {
    final result = provider.analysisResult;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '5 Sources Analyzed',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: BaseeraColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          result != null
              ? 'Analysis complete in ${result.latencyMs}ms · ${result.contradictions.length} contradiction(s) detected'
              : 'Loading data sources...',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: BaseeraColors.textSecondary,
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1.0,
              backgroundColor: BaseeraColors.border,
              valueColor:
                  const AlwaysStoppedAnimation(BaseeraColors.success),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceCard({
    required BuildContext context,
    required int index,
    required bool isProcessed,
    required bool isProcessing,
    required SourceModel? sourceData,
  }) {
    if (isProcessed) {
      return _buildProcessedCard(
        context: context,
        index: index,
        sourceData: sourceData,
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideX(begin: -0.1, end: 0);
    }
    if (isProcessing) return _buildShimmerCard();
    return _buildPendingCard(context, index);
  }

  Widget _cardShell({
    required Widget child,
    Color borderColor = BaseeraColors.primary,
    double leftBorderWidth = 4,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: BaseeraColors.surface,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: leftBorderWidth, color: borderColor),
            ),
            Padding(
              padding: EdgeInsets.only(left: leftBorderWidth),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context, int index) {
    final iconData = _sourceIconData[index];
    return _cardShell(
      borderColor: BaseeraColors.border,
      leftBorderWidth: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BaseeraColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BaseeraColors.border),
              ),
              child: Icon(iconData.icon,
                  color: iconData.color.withValues(alpha: 0.5), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sourceNames[index],
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: BaseeraColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Waiting...',
                    style: GoogleFonts.outfit(
                      color: BaseeraColors.textSecondary
                          .withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.clock,
                color: BaseeraColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: BaseeraColors.shimmerBase,
      highlightColor: BaseeraColors.shimmerHi,
      child: _cardShell(
        borderColor: BaseeraColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: BaseeraColors.shimmerHi,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 12,
                          color: BaseeraColors.shimmerHi,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 10,
                          color: BaseeraColors.shimmerHi,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 10,
                color: BaseeraColors.shimmerHi,
              ),
              const SizedBox(height: 6),
              Container(
                width: 200,
                height: 10,
                color: BaseeraColors.shimmerHi,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessedCard({
    required BuildContext context,
    required int index,
    required SourceModel? sourceData,
  }) {
    final credibility = sourceData?.credibility ?? SourceCredibility.medium;
    final cred = _credInfo(credibility);
    final iconData = _sourceIconData[index];

    return _cardShell(
      borderColor: BaseeraColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconData.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: iconData.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(iconData.icon, color: iconData.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sourceData?.name ?? _sourceNames[index],
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: BaseeraColors.textPrimary,
                        ),
                      ),
                      Text(
                        _sourceLabels[index],
                        style: GoogleFonts.outfit(
                          color: BaseeraColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCredibilityBadge(credibility, cred),
              ],
            ),
            if (sourceData != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: BaseeraColors.border),
              const SizedBox(height: 12),
              Text(
                sourceData.keyInsight,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: BaseeraColors.textPrimary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(LucideIcons.clock,
                      size: 13, color: BaseeraColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    sourceData.recency,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: BaseeraColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.checkCircle,
                      size: 14, color: BaseeraColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Processed',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: BaseeraColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCredibilityBadge(
    SourceCredibility credibility,
    _CredInfo info,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info.icon, color: info.color, size: 12),
          const SizedBox(width: 4),
          Text(
            credibility.label,
            style: GoogleFonts.outfit(
              color: info.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContradictionsSection(
    BuildContext context,
    List contradictions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.alertTriangle,
                color: BaseeraColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              '${contradictions.length} Contradiction(s) Detected',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BaseeraColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...contradictions.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BaseeraColors.redTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BaseeraColors.error, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: BaseeraColors.error.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _conflictSourceChip(c.sourceA)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(LucideIcons.arrowLeftRight,
                            size: 16, color: BaseeraColors.error),
                      ),
                      Flexible(child: _conflictSourceChip(c.sourceB)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.conflict,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: BaseeraColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BaseeraColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: BaseeraColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.checkCircle,
                            size: 16, color: BaseeraColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resolution',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: BaseeraColors.success,
                                ),
                              ),
                              Text(
                                c.resolution,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: BaseeraColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.award,
                                      size: 12,
                                      color: BaseeraColors.gold),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Winner: ${c.credibilityWinner}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: BaseeraColors.gold,
                                    ),
                                  ),
                                ],
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
          ),
        ),
      ],
    );
  }

  Widget _conflictSourceChip(String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BaseeraColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BaseeraColors.error.withValues(alpha: 0.4)),
      ),
      child: Text(
        source,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: BaseeraColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildKeyInsights(
    BuildContext context,
    List<String> insights,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.key,
                color: BaseeraColors.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              'Key Insights',
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
            children: insights
                .map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(LucideIcons.dot,
                              color: BaseeraColors.primaryGlow, size: 16),
                        ),
                        Expanded(
                          child: Text(
                            insight,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: BaseeraColors.textPrimary,
                              height: 1.4,
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

  _CredInfo _credInfo(SourceCredibility cred) {
    switch (cred) {
      case SourceCredibility.high:
        return const _CredInfo(BaseeraColors.success, LucideIcons.shieldCheck);
      case SourceCredibility.medium:
        return const _CredInfo(BaseeraColors.warning, LucideIcons.shield);
      case SourceCredibility.low:
        return const _CredInfo(BaseeraColors.error, LucideIcons.shieldOff);
      case SourceCredibility.stale:
        return const _CredInfo(
            BaseeraColors.textSecondary, LucideIcons.clock);
    }
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

class _SourceIcon {
  final IconData icon;
  final Color color;
  const _SourceIcon(this.icon, this.color);
}

class _CredInfo {
  final Color color;
  final IconData icon;
  const _CredInfo(this.color, this.icon);
}

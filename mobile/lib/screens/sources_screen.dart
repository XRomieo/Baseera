// screens/sources_screen.dart
// Screen 2: Data Sources
// Shows 5 source cards with shimmer loading, credibility badges,
// and a contradiction detection card at the bottom.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const _sourceIcons = ['📊', '📧', '📈', '⚠️', '📰'];
  static const _sourceLabels = [
    'Warehouse Stock',
    'Supplier Email',
    'Sales Dashboard',
    'Customer Complaints',
    'Market News Feed',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AnalysisProvider>();
    final result = provider.analysisResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sources'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (provider.isFallbackMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.warning),
                  ),
                  child: Text(
                    '⚠ Demo',
                    style: GoogleFonts.outfit(
                      color: colors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          _buildHeader(context, provider),
          const SizedBox(height: 16),

          // Source cards
          ...List.generate(5, (index) {
            final isProcessed = provider.sourcesProcessed[index];
            final isProcessing = provider.currentlyProcessingSource == index;
            final sourceData = result != null && result.sourcesSummary.length > index
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
                colors: colors,
              ),
            );
          }),

          const SizedBox(height: 8),

          // Contradictions section
          if (result != null && result.contradictions.isNotEmpty) ...[
            _buildContradictionsSection(context, result.contradictions, colors),
            const SizedBox(height: 16),
          ],

          // Key insights
          if (result != null && result.keyInsights.isNotEmpty)
            _buildKeyInsights(context, result.keyInsights, colors),

          const SizedBox(height: 16),

          // Next button
          if (result != null)
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/action-chain'),
              icon: const Icon(Icons.play_circle_filled_rounded),
              label: const Text('Execute Action Chain'),
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
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 4),
        Text(
          result != null
              ? 'Analysis complete in ${result.latencyMs}ms · ${result.contradictions.length} contradiction(s) detected'
              : 'Loading data sources...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
        if (result != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).extension<AppColors>()!.success,
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
    required AppColors colors,
  }) {
    // Processed always wins — even if currentlyProcessingSource still points here
    if (isProcessed) {
      return _buildProcessedCard(
        context: context,
        index: index,
        sourceData: sourceData,
        colors: colors,
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideX(begin: -0.1, end: 0);
    }

    if (isProcessing) {
      // Actively fetching — show shimmer
      return _buildShimmerCard();
    }

    // Not yet reached — grey placeholder
    return _buildPendingCard(context, index);
  }

  Widget _buildPendingCard(BuildContext context, int index) {
    return Card(
      child: ListTile(
        leading: Text(
          _sourceIcons[index],
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          _sourceNames[index],
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        subtitle: Text(
          'Waiting...',
          style: GoogleFonts.outfit(color: Colors.black38, fontSize: 13),
        ),
        trailing: const Icon(Icons.access_time, color: Colors.black26),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                color: Colors.white,
              ),
              const SizedBox(height: 6),
              Container(
                width: 200,
                height: 12,
                color: Colors.white,
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
    required AppColors colors,
  }) {
    final credibility = sourceData?.credibility ?? SourceCredibility.medium;
    final credColor = _credibilityColor(credibility, colors);
    final credIcon = _credibilityIcon(credibility);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Source icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _sourceIcons[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
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
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        _sourceLabels[index],
                        style: GoogleFonts.outfit(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Credibility badge
                _buildCredibilityBadge(
                  credibility,
                  credColor,
                  credIcon,
                ),
              ],
            ),
            if (sourceData != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                sourceData.keyInsight,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    sourceData.recency,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.check_circle, size: 16, color: colors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Processed',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: colors.success,
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
    Color color,
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            credibility.label,
            style: GoogleFonts.outfit(
              color: color,
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
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_rounded, color: colors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              '${contradictions.length} Contradiction(s) Detected',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...contradictions.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sources in conflict
                  Row(
                    children: [
                      Flexible(child: _conflictSourceChip(c.sourceA, colors)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.sync_alt_rounded,
                            size: 16, color: colors.error),
                      ),
                      Flexible(child: _conflictSourceChip(c.sourceB, colors)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.conflict,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: colors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: colors.success),
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
                                  color: colors.success,
                                ),
                              ),
                              Text(
                                c.resolution,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              Text(
                                '✓ Winner: ${c.credibilityWinner}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.success,
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
          ),
        ),
      ],
    );
  }

  Widget _conflictSourceChip(String source, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        source,
        style: GoogleFonts.outfit(
          fontSize: 11,
          color: colors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildKeyInsights(
    BuildContext context,
    List<String> insights,
    AppColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔑 Key Insights',
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
            children: insights
                .map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.black87,
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

  Color _credibilityColor(SourceCredibility cred, AppColors colors) {
    switch (cred) {
      case SourceCredibility.high:
        return colors.success;
      case SourceCredibility.medium:
        return colors.warning;
      case SourceCredibility.low:
        return colors.error;
      case SourceCredibility.stale:
        return const Color(0xFFE65100);
    }
  }

  String _credibilityIcon(SourceCredibility cred) {
    switch (cred) {
      case SourceCredibility.high:
        return '✓';
      case SourceCredibility.medium:
        return 'ℹ';
      case SourceCredibility.low:
        return '⚠';
      case SourceCredibility.stale:
        return '🕐';
    }
  }
}

// screens/home_screen.dart
// Screen 1: Home Dashboard
// Shows app name, "Run Analysis" button, status indicator.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/analysis_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final provider = context.watch<AnalysisProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              const Color(0xFF283593),
              const Color(0xFF3949AB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(provider.appState),
                    if (provider.isFallbackMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.warning),
                        ),
                        child: Text(
                          '⚠ Demo Mode',
                          style: GoogleFonts.outfit(
                            color: colors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // AI Icon
                    _buildAIIcon(colors)
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(begin: const Offset(0.8, 0.8)),

                    const SizedBox(height: 32),

                    // App name
                    Text(
                      'Baseera',
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 12),

                    Text(
                      'Multi-source AI analyst for\nsupply chain intelligence',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms),

                    const SizedBox(height: 12),

                    // Hackathon badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '🏆 AISeekho 2026 Hackathon',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms),
                  ],
                ),
              ),

              const Spacer(),

              // Feature pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _featurePill('🔍 5 Data Sources'),
                    _featurePill('🤖 Gemini AI'),
                    _featurePill('⚡ 4-Step Actions'),
                    _featurePill('🔄 Auto Recovery'),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms),

              const SizedBox(height: 40),

              // Run Analysis Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _buildRunButton(provider, context, colors),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms)
                  .slideY(begin: 0.5, end: 0),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIIcon(AppColors colors) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1 + _pulseController.value * 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3 + _pulseController.value * 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1 + _pulseController.value * 0.1),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Center(
            child: Text('🧠', style: TextStyle(fontSize: 56)),
          ),
        );
      },
    );
  }

  Widget _featurePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppState state) {
    String label;
    Color color;
    String icon;

    switch (state) {
      case AppState.idle:
        label = 'Ready';
        color = Colors.greenAccent;
        icon = '●';
      case AppState.analyzing:
        label = 'Analyzing...';
        color = Colors.amberAccent;
        icon = '◉';
      case AppState.analyzed:
        label = 'Analysis Complete';
        color = Colors.greenAccent;
        icon = '✓';
      case AppState.executing:
        label = 'Executing...';
        color = Colors.lightBlueAccent;
        icon = '◉';
      case AppState.executionComplete:
        label = 'Complete';
        color = Colors.greenAccent;
        icon = '✓';
      case AppState.error:
        label = 'Error';
        color = Colors.redAccent;
        icon = '✗';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(
    AnalysisProvider provider,
    BuildContext context,
    AppColors colors,
  ) {
    final bool isLoading = provider.appState == AppState.analyzing;
    final bool isComplete = provider.appState == AppState.analyzed ||
        provider.appState == AppState.executing ||
        provider.appState == AppState.executionComplete;

    if (isComplete) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/sources'),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('View Analysis Results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              provider.reset();
            },
            child: Text(
              'Run Again',
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () async {
                await provider.runAnalysis();
                if (context.mounted && provider.appState == AppState.analyzed) {
                  Navigator.pushNamed(context, '/sources');
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: colors.primary,
          disabledBackgroundColor: Colors.white60,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Analyzing 5 Sources...',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Run Analysis',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

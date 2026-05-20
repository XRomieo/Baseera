// screens/home_screen.dart
// Screen 1: Home Dashboard
// Royal dark theme: gradient title, pulsing Run button, radial purple spotlight.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysisProvider>();

    return Scaffold(
      backgroundColor: BaseeraColors.bg,
      body: Stack(
        children: [
          // Radial purple spotlight — smooth, banding-free
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, 0.55),
                      radius: 1.1,
                      colors: [
                        Color(0x556C3FE8),
                        Color(0x3D6C3FE8),
                        Color(0x266C3FE8),
                        Color(0x146C3FE8),
                        Color(0x086C3FE8),
                        Color(0x006C3FE8),
                      ],
                      stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(provider.appState),
                      if (provider.isFallbackMode)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: BaseeraColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: BaseeraColors.warning
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.alertTriangle,
                                  color: BaseeraColors.warning, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                'Demo Mode',
                                style: GoogleFonts.outfit(
                                  color: BaseeraColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Logo
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.85, 0.85)),

                const SizedBox(height: 24),

                // Title
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [BaseeraColors.gold, BaseeraColors.goldGlow],
                  ).createShader(rect),
                  child: Text(
                    'Baseera',
                    style: GoogleFonts.outfit(
                      fontSize: 46,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Multi-source AI analyst for\nsupply chain intelligence',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: BaseeraColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 16),

                // Hackathon badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: BaseeraColors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: BaseeraColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.award,
                          color: BaseeraColors.goldGlow, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'AISeekho 2026 Hackathon',
                        style: GoogleFonts.outfit(
                          color: BaseeraColors.goldGlow,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),

                const Spacer(),

                // Feature pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _featurePill(LucideIcons.eye, '5 Data Sources'),
                      _featurePill(LucideIcons.sparkles, 'Gemini AI'),
                      _featurePill(LucideIcons.zap, '4-Step Actions'),
                      _featurePill(LucideIcons.refreshCw, 'Auto Recovery'),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms),

                const SizedBox(height: 32),

                // Run Analysis Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildRunButton(provider, context),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms)
                    .slideY(begin: 0.5, end: 0),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: BaseeraColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BaseeraColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: BaseeraColors.primaryGlow, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: BaseeraColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AppState state) {
    String label;
    Color color;
    IconData icon;

    switch (state) {
      case AppState.idle:
        label = 'Ready';
        color = BaseeraColors.success;
        icon = LucideIcons.checkCircle;
      case AppState.analyzing:
        label = 'Analyzing...';
        color = BaseeraColors.goldGlow;
        icon = LucideIcons.loader;
      case AppState.analyzed:
        label = 'Analysis Complete';
        color = BaseeraColors.success;
        icon = LucideIcons.checkCircle;
      case AppState.executing:
        label = 'Executing...';
        color = BaseeraColors.primaryGlow;
        icon = LucideIcons.loader;
      case AppState.executionComplete:
        label = 'Complete';
        color = BaseeraColors.success;
        icon = LucideIcons.checkCircle;
      case AppState.error:
        label = 'Error';
        color = BaseeraColors.error;
        icon = LucideIcons.xCircle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(
    AnalysisProvider provider,
    BuildContext context,
  ) {
    final bool isLoading = provider.appState == AppState.analyzing;
    final bool isComplete = provider.appState == AppState.analyzed ||
        provider.appState == AppState.executing ||
        provider.appState == AppState.executionComplete;

    if (isComplete) {
      return Column(
        children: [
          _gradientButton(
            icon: LucideIcons.arrowRight,
            label: 'View Analysis Results',
            onPressed: () => Navigator.pushNamed(context, '/sources'),
            animated: false,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: provider.reset,
            child: Text(
              'Run Again',
              style: GoogleFonts.outfit(
                color: BaseeraColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (isLoading) {
      return _gradientButton(
        icon: LucideIcons.loader,
        label: 'Analyzing 5 Sources...',
        onPressed: null,
        animated: true,
        spinIcon: true,
      );
    }

    return _gradientButton(
      icon: LucideIcons.brain,
      label: 'Run Analysis',
      onPressed: () async {
        await provider.runAnalysis();
        if (context.mounted && provider.appState == AppState.analyzed) {
          Navigator.pushNamed(context, '/sources');
        }
      },
      animated: true,
    );
  }

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool animated,
    bool spinIcon = false,
  }) {
    Widget iconWidget = Icon(icon, color: Colors.white, size: 22);
    if (spinIcon) {
      if (!_spinController.isAnimating) _spinController.repeat();
      iconWidget = RotationTransition(
        turns: _spinController,
        child: iconWidget,
      );
    } else if (_spinController.isAnimating) {
      _spinController.stop();
    }

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: onPressed == null
                    ? [
                        BaseeraColors.primary.withValues(alpha: 0.6),
                        BaseeraColors.primaryGlow.withValues(alpha: 0.6),
                      ]
                    : const [
                        BaseeraColors.primary,
                        BaseeraColors.primaryGlow,
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x556C3FE8),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

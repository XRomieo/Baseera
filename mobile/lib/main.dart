// main.dart — Baseera Flutter App
// AISeekho 2026 Hackathon | Challenge 1: Autonomous Content-to-Action Agent
//
// App flow: Home → Sources → ActionChain → Outcome → (Run Again → Home)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/analysis_provider.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/action_chain_screen.dart';
import 'screens/outcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env (release builds use BASEERA_API_URL from this file).
  // Missing file is non-fatal — debug builds don't need it.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not bundled — fine for debug builds.
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: BaseeraColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const BaseeraApp());
}

class BaseeraColors {
  static const bg            = Color(0xFF0A0A12);
  static const surface       = Color(0xFF0F0F1E);
  static const primary       = Color(0xFF6C3FE8);
  static const primaryGlow   = Color(0xFF9B6DFF);
  static const gold          = Color(0xFFD4A017);
  static const goldGlow      = Color(0xFFFFD060);
  static const success       = Color(0xFF00C97A);
  static const error         = Color(0xFFFF4D6D);
  static const warning       = Color(0xFFFFA500);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA89BC2);
  static const border        = Color(0xFF2A2040);
  static const redTint       = Color(0xFF1A0A0E);
  static const greenTint     = Color(0xFF0A1A0E);
  static const shimmerBase   = Color(0xFF1A1530);
  static const shimmerHi     = Color(0xFF2A2040);
}

class BaseeraApp extends StatelessWidget {
  const BaseeraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ChangeNotifierProxyProvider<ApiService, AnalysisProvider>(
          create: (ctx) => AnalysisProvider(ctx.read<ApiService>()),
          update: (ctx, apiService, previous) =>
              previous ?? AnalysisProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Baseera',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: '/',
        routes: {
          '/': (ctx) => const SplashScreen(),
          '/home': (ctx) => const HomeScreen(),
          '/sources': (ctx) => const SourcesScreen(),
          '/action-chain': (ctx) => const ActionChainScreen(),
          '/outcome': (ctx) => const OutcomeScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final baseTextTheme = GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: BaseeraColors.textPrimary,
      displayColor: BaseeraColors.textPrimary,
    );

    const colorScheme = ColorScheme.dark(
      primary: BaseeraColors.primary,
      onPrimary: Colors.white,
      secondary: BaseeraColors.gold,
      onSecondary: Colors.black,
      error: BaseeraColors.error,
      onError: Colors.white,
      surface: BaseeraColors.surface,
      onSurface: BaseeraColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BaseeraColors.bg,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: BaseeraColors.textPrimary,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: BaseeraColors.textPrimary,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: BaseeraColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BaseeraColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: BaseeraColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: BaseeraColors.textPrimary,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: BaseeraColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BaseeraColors.bg,
        foregroundColor: BaseeraColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: BaseeraColors.primaryGlow),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: BaseeraColors.textPrimary,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BaseeraColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BaseeraColors.primaryGlow,
          side: const BorderSide(color: BaseeraColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BaseeraColors.primaryGlow,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: BaseeraColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BaseeraColors.border, width: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BaseeraColors.surface,
        side: const BorderSide(color: BaseeraColors.border, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: BaseeraColors.textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(color: BaseeraColors.primaryGlow),
      dividerColor: BaseeraColors.border,
      dividerTheme: const DividerThemeData(
        color: BaseeraColors.border,
        thickness: 0.5,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BaseeraColors.primaryGlow,
        linearTrackColor: BaseeraColors.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BaseeraColors.surface,
        contentTextStyle: GoogleFonts.outfit(
          color: BaseeraColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: BaseeraColors.border, width: 0.5),
        ),
      ),
      extensions: const [
        AppColors(
          success: BaseeraColors.success,
          warning: BaseeraColors.warning,
          error: BaseeraColors.error,
          primary: BaseeraColors.primary,
          primaryGlow: BaseeraColors.primaryGlow,
          gold: BaseeraColors.gold,
          goldGlow: BaseeraColors.goldGlow,
          textPrimary: BaseeraColors.textPrimary,
          textSecondary: BaseeraColors.textSecondary,
          border: BaseeraColors.border,
          surface: BaseeraColors.surface,
          bg: BaseeraColors.bg,
        ),
      ],
    );
  }
}

// Custom color extension for easy access
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color warning;
  final Color error;
  final Color primary;
  final Color primaryGlow;
  final Color gold;
  final Color goldGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color surface;
  final Color bg;

  const AppColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.primary,
    required this.primaryGlow,
    required this.gold,
    required this.goldGlow,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.surface,
    required this.bg,
  });

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? primary,
    Color? primaryGlow,
    Color? gold,
    Color? goldGlow,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? surface,
    Color? bg,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      primary: primary ?? this.primary,
      primaryGlow: primaryGlow ?? this.primaryGlow,
      gold: gold ?? this.gold,
      goldGlow: goldGlow ?? this.goldGlow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      surface: surface ?? this.surface,
      bg: bg ?? this.bg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldGlow: Color.lerp(goldGlow, other.goldGlow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
    );
  }
}

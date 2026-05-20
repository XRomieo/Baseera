// main.dart — Baseera Flutter App
// AISeekho 2026 Hackathon | Challenge 1: Autonomous Content-to-Action Agent
//
// App flow: Home → Sources → ActionChain → Outcome → (Run Again → Home)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/analysis_provider.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/action_chain_screen.dart';
import 'screens/outcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const BaseeraApp());
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
          '/': (ctx) => const HomeScreen(),
          '/sources': (ctx) => const SourcesScreen(),
          '/action-chain': (ctx) => const ActionChainScreen(),
          '/outcome': (ctx) => const OutcomeScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF1A237E); // Deep Blue
    const successColor = Color(0xFF2E7D32); // Green
    const errorColor = Color(0xFFC62828); // Red
    const warningColor = Color(0xFFF57F17); // Amber

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: successColor,
      error: errorColor,
      surface: const Color(0xFFF5F7FA),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      extensions: const [
        AppColors(
          success: successColor,
          warning: warningColor,
          error: errorColor,
          primary: primaryColor,
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

  const AppColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.primary,
  });

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? primary,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      primary: primary ?? this.primary,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────
/// COLORS
/// ─────────────────────────────────────────
class AppColors {
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFFF3EE);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color grey = Color(0xFF888888);
  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color dark = Color(0xFF1C1C1C);
  static const Color star = Color(0xFFFFC107);
  static const Color green = Color(0xFF4CAF50);
}

/// ─────────────────────────────────────────
/// THEME
/// ─────────────────────────────────────────
class AppTheme {
  /// 👉 FIX: expose colors through AppTheme (important)
  static const Color orange = AppColors.orange;
  static const Color white = AppColors.white;
  static const Color darkBg = AppColors.darkBg;
  static const Color greyText = AppColors.grey;

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.orange,
        ),
        scaffoldBackgroundColor: AppColors.lightBg,
        textTheme: GoogleFonts.nunitoTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: AppColors.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      );
}

/// ─────────────────────────────────────────
/// CONSTANTS (Supabase etc.)
/// ─────────────────────────────────────────
class AppConstants {
  // ✅ Aluth Supabase Project URL eka
  static const String supabaseUrl = 'https://uhliuwcpqpztjlujvqax.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVobGl1d2NwcXB6dGpsdWp2cWF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1Njc0NDAsImV4cCI6MjA5MjE0MzQ0MH0.qusVnUomSERG_m3-zqqasmfR8zKoSMriICBND9zuP-Q';
}
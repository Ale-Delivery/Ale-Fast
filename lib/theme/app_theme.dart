import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Ultra-Modern Minimalist Design Tokens ───────────────────────

class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────
  static const Color accent = Color(0xFFE63946); // Premium Red
  static const Color accentLight = Color(0xFFFDE8EA);
  static const Color accentDark = Color(0xFFC62828);

  // ── Surfaces ─────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF9F9FB); // Very light gray
  static const Color surface = Color(0xFFFFFFFF);

  // ── Text ─────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1A1A1A); // Deep charcoal
  static const Color muted = Color(0xFF8E8E93); // Medium gray
  static const Color hint = Color(0xFFC7C7CC); // Light gray
  static const Color inverse = Color(0xFFFFFFFF);

  // ── Borders & Dividers ───────────────────────────────────────
  static const Color border = Color(0xFFE5E5EA);
  static const Color divider = Color(0xFFF2F2F7);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);
  static const Color amber = Color(0xFFFF9500);
  static const Color purple = Color(0xFFAF52DE);
  static const Color star = Color(0xFFFF9500);

  // ── Legacy aliases (backward compat) ─────────────────────────
  static const Color orange = accent;
  static const Color orangeDark = accentDark;
  static const Color orangeLight = accentLight;
  static const Color lightBg = bg;
  static const Color lightSurface = surface;
  static const Color lightInk = ink;
  static const Color lightMuted = muted;
  static const Color lightHint = hint;
  static const Color darkBg = bg;
  static const Color darkCard = surface;
  static const Color darkEnd = bg;
  static const Color grey = muted;
  static const Color greyLight = border;
  static const Color dark = ink;
  static const Color lightBorder = border;
  static const Color blue = accent;
}

// ─── Gradient Presets ──────────────────────────────────────────

class AppGradients {
  AppGradients._();

  // Premium fiery red gradient: Deep Crimson → Vibrant Red
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFDC143C), Color(0xFFFF3B30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Even more vibrant for hero sections
  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFFDC143C), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient light = LinearGradient(
    colors: [Color(0xFFF9F9FB), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient avatar = LinearGradient(
    colors: [Color(0xFFDC143C), Color(0xFFFF3B30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statusReady = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF30B350)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glowing shadow for gradient buttons
  static List<BoxShadow> get glow => [
        BoxShadow(
          color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

// ─── Theme ─────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // Legacy aliases
  static const Color orange = AppColors.accent;
  static const Color white = AppColors.white;
  static const Color darkBg = AppColors.bg;
  static const Color greyText = AppColors.muted;

  static ThemeData get lightTheme {
    final baseText = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        onPrimary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: baseText.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.ink),
        bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.ink),
        bodySmall: baseText.bodySmall?.copyWith(color: AppColors.muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          shadowColor: const Color(0xFFFF3B30).withValues(alpha: 0.35),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: EdgeInsets.only(bottom: 12),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.bg,
        selectedColor: AppColors.accent,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        onPrimary: AppColors.white,
        surface: const Color(0xFF1C1C1E),
        onSurface: const Color(0xFFF2F2F7),
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      textTheme: baseText.copyWith(
        headlineLarge: baseText.headlineLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(color: Colors.white),
        bodyMedium: baseText.bodyMedium?.copyWith(color: Colors.white),
        bodySmall: baseText.bodySmall?.copyWith(color: AppColors.muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A3A3C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF2C2C2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        margin: EdgeInsets.only(bottom: 12),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

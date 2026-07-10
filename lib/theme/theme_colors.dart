import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get primaryColor => AppColors.accent;

  // ── Text ─────────────────────────────────────────────────────
  Color get textPrimary => isDark ? Colors.white : AppColors.ink;
  Color get textSecondary => isDark ? const Color(0xFFAEAEB2) : AppColors.ink.withValues(alpha: 0.7);
  Color get textMuted => isDark ? AppColors.muted : AppColors.muted;
  Color get textHint => isDark ? const Color(0xFF636366) : AppColors.hint;

  // ── Cards & Surfaces ────────────────────────────────────────
  Color get cardBg => isDark ? const Color(0xFF2C2C2E) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF3A3A3C) : AppColors.border;

  Color get inputBg => isDark ? const Color(0xFF2C2C2E) : Colors.white;

  Color get chipBg => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
  Color get chipActiveBg => AppColors.accent;

  Color get divider => isDark ? const Color(0xFF38383A) : AppColors.divider;

  Color get shimmerBase => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
  Color get shimmerHighlight => isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);

  Color get appBarBg => isDark ? Colors.black : Colors.white;

  // ── Shadows (minimalist soft) ───────────────────────────────
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
      ];

  List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];

  // ── Status Colors ───────────────────────────────────────────
  Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.amber;
      case 'accepted':
      case 'preparing':
        return AppColors.accent;
      case 'on_the_way':
      case 'out_for_delivery':
        return AppColors.purple;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return textMuted;
    }
  }
}

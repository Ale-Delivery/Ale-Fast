import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color orange = Color(0xFFFF6B35);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkInput = Color(0xFF0F3460);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightBg = Color(0xFFF0F2F5);
  static const Color greyText = Color(0xFF888888);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: orange),
        textTheme: GoogleFonts.nunitoTextTheme(),
        scaffoldBackgroundColor: lightBg,
      );
}

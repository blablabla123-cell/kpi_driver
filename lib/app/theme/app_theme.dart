import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: const Color(0xFF3D5AFE),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
        backgroundColor: base.colorScheme.surface,
        foregroundColor: base.colorScheme.onSurface,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: base.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF3D5AFE),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: false,
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}


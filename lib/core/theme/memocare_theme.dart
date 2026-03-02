import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'emotional_theme_extension.dart';
import 'memocare_colors.dart';

/// Main MemoCare Design System (Medical & Professional Theme)
/// Incorporates Material 3 and the Emotional Theme Extension.
class MemoCareTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MemoCareColors.primary,
        primary: MemoCareColors.primary,
        onPrimary: Colors.white,
        secondary: MemoCareColors.secondary,
        onSecondary: Colors.white,
        surface: MemoCareColors.surface,
        onSurface: MemoCareColors.txtPrimary,
        error: MemoCareColors.error,
        onError: Colors.white,
        background: MemoCareColors.background,
      ),

      // Global Text Styling
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: MemoCareColors.txtPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: MemoCareColors.txtPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 18,
          color: MemoCareColors.txtPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 16,
          color: MemoCareColors.txtSecondary,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: MemoCareColors.surface,
        foregroundColor: MemoCareColors.txtPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: MemoCareColors.surface,
        elevation: 2,
        shadowColor: MemoCareColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MemoCareColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MemoCareColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MemoCareColors.primaryLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MemoCareColors.primaryLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MemoCareColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),

      // Register Emotional Theme Extension
      extensions: const <ThemeExtension<dynamic>>[
        EmotionalThemeExtension.defaultPalette,
      ],
    );
  }

  static ThemeData get darkTheme {
    // Basic dark theme implementation, can be expanded
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MemoCareColors.primary,
        brightness: Brightness.dark,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        EmotionalThemeExtension
            .defaultPalette, // Keep same friendly colors even in dark mode for now
      ],
    );
  }
}

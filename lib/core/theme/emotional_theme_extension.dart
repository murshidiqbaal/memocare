import 'package:flutter/material.dart';
import 'emotional_colors.dart';

/// ThemeExtension for the Emotional/Memory palette.
/// Allows memory-specific screens to access the gentle palette via
/// Theme.of(context).extension<EmotionalThemeExtension>()
class EmotionalThemeExtension extends ThemeExtension<EmotionalThemeExtension> {
  final Color? primary;
  final Color? secondary;
  final Color? background;
  final Color? surface;
  final Color? textPrimary;
  final Color? textSecondary;
  final Color? success;
  final Color? warning;
  final Color? error;

  const EmotionalThemeExtension({
    this.primary,
    this.secondary,
    this.background,
    this.surface,
    this.textPrimary,
    this.textSecondary,
    this.success,
    this.warning,
    this.error,
  });

  @override
  EmotionalThemeExtension copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return EmotionalThemeExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  EmotionalThemeExtension lerp(
      ThemeExtension<EmotionalThemeExtension>? other, double t) {
    if (other is! EmotionalThemeExtension) {
      return this;
    }
    return EmotionalThemeExtension(
      primary: Color.lerp(primary, other.primary, t),
      secondary: Color.lerp(secondary, other.secondary, t),
      background: Color.lerp(background, other.background, t),
      surface: Color.lerp(surface, other.surface, t),
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t),
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t),
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
      error: Color.lerp(error, other.error, t),
    );
  }

  /// Default implementation using the EmotionalColors palette
  static const EmotionalThemeExtension defaultPalette = EmotionalThemeExtension(
    primary: EmotionalColors.primary,
    secondary: EmotionalColors.secondary,
    background: EmotionalColors.background,
    surface: EmotionalColors.surface,
    textPrimary: EmotionalColors.textPrimary,
    textSecondary: EmotionalColors.textSecondary,
    success: EmotionalColors.success,
    warning: EmotionalColors.warning,
    error: EmotionalColors.error,
  );
}

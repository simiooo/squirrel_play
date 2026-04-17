import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';

/// Application theme configuration.
///
/// Provides the dark theme for Squirrel Play with all design tokens applied.
/// This theme is optimized for a gaming console-like TV interface.
class AppTheme {
  AppTheme._();

  /// The dark theme for the application.
  ///
  /// Applies all design tokens including colors, typography, and component themes.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: _colorScheme,
      textTheme: _textTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      textButtonTheme: _textButtonTheme,
      iconTheme: _iconTheme,
      dividerTheme: _dividerTheme,
      dialogTheme: _dialogTheme,
      appBarTheme: _appBarTheme,
    );
  }

  /// The color scheme for the dark theme.
  static ColorScheme get _colorScheme {
    return const ColorScheme.dark(
      primary: AppColors.primaryAccent,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primaryAccentHover,
      secondary: AppColors.secondaryAccent,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.textPrimary,
    );
  }

  /// The text theme using Inter font family.
  static TextTheme get _textTheme {
    return TextTheme(
      // Display/Heading styles
      displayLarge: GoogleFonts.inter(
        fontSize: AppTypography.headingSize,
        fontWeight: AppTypography.bold,
        height: AppTypography.headingLineHeight / AppTypography.headingSize,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: AppTypography.headingSize * 0.875,
        fontWeight: AppTypography.bold,
        height: AppTypography.headingLineHeight / AppTypography.headingSize,
        color: AppColors.textPrimary,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.inter(
        fontSize: AppTypography.headingSize,
        fontWeight: AppTypography.bold,
        height: AppTypography.headingLineHeight / AppTypography.headingSize,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: AppTypography.headingSize * 0.875,
        fontWeight: AppTypography.bold,
        height: AppTypography.headingLineHeight / AppTypography.headingSize,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: AppTypography.headingSize * 0.75,
        fontWeight: AppTypography.bold,
        height: AppTypography.headingLineHeight / AppTypography.headingSize,
        color: AppColors.textPrimary,
      ),

      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: AppTypography.bodySize * 1.25,
        fontWeight: AppTypography.bold,
        height: AppTypography.bodyLineHeight / AppTypography.bodySize,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.bold,
        height: AppTypography.bodyLineHeight / AppTypography.bodySize,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: AppTypography.bodySize * 0.875,
        fontWeight: AppTypography.regular,
        height: AppTypography.bodyLineHeight / AppTypography.bodySize,
        color: AppColors.textSecondary,
      ),

      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.regular,
        height: AppTypography.bodyLineHeight / AppTypography.bodySize,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.regular,
        height: AppTypography.bodyLineHeight / AppTypography.bodySize,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: AppTypography.captionSize,
        fontWeight: AppTypography.light,
        height: AppTypography.captionLineHeight / AppTypography.captionSize,
        color: AppColors.textMuted,
      ),

      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.regular,
        height: AppTypography.bodyLineHeight / AppTypography.bodySize,
        color: AppColors.textSecondary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: AppTypography.captionSize,
        fontWeight: AppTypography.light,
        height: AppTypography.captionLineHeight / AppTypography.captionSize,
        color: AppColors.textMuted,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: AppTypography.captionSize * 0.875,
        fontWeight: AppTypography.light,
        height: AppTypography.captionLineHeight / AppTypography.captionSize,
        color: AppColors.textMuted,
      ),
    );
  }

  /// Card theme configuration.
  static CardThemeData get _cardTheme {
    return CardThemeData(
      color: AppColors.surface,
      elevation: AppElevations.rest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      margin: EdgeInsets.zero,
    );
  }

  /// Elevated button theme configuration.
  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(48.0, 48.0),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        elevation: AppElevations.rest,
      ),
    );
  }

  /// Text button theme configuration.
  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(48.0, 48.0),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
    );
  }

  /// Icon theme configuration.
  static IconThemeData get _iconTheme {
    return const IconThemeData(
      color: AppColors.textPrimary,
      size: 24.0,
    );
  }

  /// Divider theme configuration.
  static DividerThemeData get _dividerTheme {
    return const DividerThemeData(
      color: AppColors.surfaceElevated,
      thickness: 1.0,
      space: AppSpacing.lg,
    );
  }

  /// Dialog theme configuration.
  static DialogThemeData get _dialogTheme {
    return DialogThemeData(
      backgroundColor: AppColors.surface.withAlpha((AppColors.surfaceOpacity * 255).round()),
      elevation: AppElevations.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
    );
  }

  /// App bar theme configuration.
  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.surface.withAlpha((AppColors.surfaceOpacity * 255).round()),
      foregroundColor: AppColors.textPrimary,
      elevation: AppElevations.rest,
      centerTitle: true,
      toolbarHeight: AppSpacing.xxxxl,
      titleTextStyle: GoogleFonts.inter(
        fontSize: AppTypography.bodySize,
        fontWeight: AppTypography.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

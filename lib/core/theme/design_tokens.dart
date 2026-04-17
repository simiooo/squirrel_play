import 'package:flutter/material.dart';

/// Design tokens for the Squirrel Play application.
///
/// These tokens define the visual design language including colors,
/// typography, spacing, border radii, elevations, and animation parameters.
/// All values are derived from the design standards document.

/// Color palette tokens.
///
/// Colors are organized by function: background, surface, accent, text, and utility.
class AppColors {
  AppColors._();

  // Background Colors
  /// Primary background color - deep charcoal (#0D0D0F).
  static const Color background = Color(0xFF0D0D0F);

  /// Deep background color for gradient effects - near black (#08080A).
  static const Color backgroundDeep = Color(0xFF08080A);

  // Surface Colors
  /// Base surface color for cards and panels (#1A1A1E).
  static const Color surface = Color(0xFF1A1A1E);

  /// Opacity value for layered transparency effect (85%).
  static const double surfaceOpacity = 0.85;

  /// Elevated surface color for hover/focus states (#2A2A30).
  static const Color surfaceElevated = Color(0xFF2A2A30);

  // Accent Colors
  /// Primary accent color - vibrant orange (#FF6B2B).
  /// Used for focus rings, active states, and CTAs.
  static const Color primaryAccent = Color(0xFFFF6B2B);

  /// Primary accent hover color - lighter orange (#FF8A50).
  /// Used for pressed states.
  static const Color primaryAccentHover = Color(0xFFFF8A50);

  /// Secondary accent color - cool teal (#00C9A7).
  /// Used for success states and secondary actions.
  static const Color secondaryAccent = Color(0xFF00C9A7);

  // Text Colors
  /// Primary text color - pure white (#FFFFFF).
  /// Used for headings and focused elements.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text color - light gray (#B0B0B8).
  /// Used for descriptions and metadata.
  static const Color textSecondary = Color(0xFFB0B0B8);

  /// Muted text color - medium gray (#6B6B75).
  /// Used for timestamps and disabled states.
  static const Color textMuted = Color(0xFF6B6B75);

  // Utility Colors
  /// Error/destructive color - warm red (#FF4757).
  static const Color error = Color(0xFFFF4757);

  /// Success color - green (#00C9A7).
  static const Color success = Color(0xFF00C9A7);

  /// Warning color - amber (#FFB347).
  static const Color warning = Color(0xFFFFB347);

  /// Overlay color - black at 60% opacity for modal backgrounds.
  static const Color overlay = Color(0x99000000);
}

/// Typography tokens.
///
/// All text styles use the Inter font family with a 4px base grid.
/// Line heights are multiples of 4 for visual rhythm.
class AppTypography {
  AppTypography._();

  /// Font family name for Inter.
  static const String fontFamily = 'Inter';

  // Font Sizes
  /// Heading font size - 32px.
  static const double headingSize = 32.0;

  /// Body font size - 16px.
  static const double bodySize = 16.0;

  /// Caption font size - 12px.
  static const double captionSize = 12.0;

  /// Monospace font size - 14px.
  static const double monospaceSize = 14.0;

  // Line Heights
  /// Heading line height - 40px.
  static const double headingLineHeight = 40.0;

  /// Body line height - 24px.
  static const double bodyLineHeight = 24.0;

  /// Caption line height - 16px.
  static const double captionLineHeight = 16.0;

  /// Monospace line height - 20px.
  static const double monospaceLineHeight = 20.0;

  // Font Weights
  /// Light weight (w300) - for captions and metadata.
  static const FontWeight light = FontWeight.w300;

  /// Regular weight (w400) - for body text.
  static const FontWeight regular = FontWeight.w400;

  /// Bold weight (w700) - for headings.
  static const FontWeight bold = FontWeight.w700;
}

/// Spacing tokens.
///
/// All spacing values are multiples of 4px to maintain visual rhythm.
class AppSpacing {
  AppSpacing._();

  /// Extra small spacing - 4px.
  static const double xs = 4.0;

  /// Small spacing - 8px.
  static const double sm = 8.0;

  /// Medium spacing - 12px.
  static const double md = 12.0;

  /// Large spacing - 16px.
  static const double lg = 16.0;

  /// Extra large spacing - 24px.
  static const double xl = 24.0;

  /// Double extra large spacing - 32px.
  static const double xxl = 32.0;

  /// Triple extra large spacing - 48px.
  static const double xxxl = 48.0;

  /// Quadruple extra large spacing - 64px.
  static const double xxxxl = 64.0;
}

/// Border radius tokens.
class AppRadii {
  AppRadii._();

  /// Small border radius - 4px.
  static const double small = 4.0;

  /// Medium border radius - 8px.
  /// Used for cards and buttons.
  static const double medium = 8.0;

  /// Large border radius - 12px.
  /// Used for dialogs and panels.
  static const double large = 12.0;
}

/// Elevation tokens for shadow effects.
class AppElevations {
  AppElevations._();

  /// Resting elevation - minimal shadow.
  static const double rest = 2.0;

  /// Focus elevation - increased shadow for focused elements.
  static const double focus = 8.0;

  /// Elevated elevation - maximum shadow for popovers/modals.
  static const double elevated = 16.0;
}

/// Animation duration tokens in milliseconds.
class AppAnimationDurations {
  AppAnimationDurations._();

  /// Focus in animation duration - 200ms.
  static const Duration focusIn = Duration(milliseconds: 200);

  /// Focus out animation duration - 150ms.
  static const Duration focusOut = Duration(milliseconds: 150);

  /// Page enter animation duration - 300ms.
  static const Duration pageEnter = Duration(milliseconds: 300);

  /// Page exit animation duration - 200ms.
  static const Duration pageExit = Duration(milliseconds: 200);

  /// Background crossfade animation duration - 500ms.
  static const Duration crossfade = Duration(milliseconds: 500);

  /// Shimmer animation duration - 1500ms.
  static const Duration shimmer = Duration(milliseconds: 1500);

  /// Dialog open animation duration - 200ms.
  static const Duration dialogOpen = Duration(milliseconds: 200);

  /// Dialog close animation duration - 150ms.
  static const Duration dialogClose = Duration(milliseconds: 150);

  /// Card scroll animation duration - 250ms.
  static const Duration cardScroll = Duration(milliseconds: 250);

  /// Progress bar animation duration - 300ms.
  static const Duration progressBar = Duration(milliseconds: 300);
}

/// Animation curve tokens.
class AppAnimationCurves {
  AppAnimationCurves._();

  /// Ease out curve for focus animations.
  static const Curve focusIn = Curves.easeOut;

  /// Ease in curve for unfocus animations.
  static const Curve focusOut = Curves.easeIn;

  /// Ease out cubic curve for card focus in and page enter.
  static const Curve pageEnter = Curves.easeOutCubic;

  /// Ease in cubic curve for card focus out and page exit.
  static const Curve pageExit = Curves.easeInCubic;

  /// Ease in out curve for background crossfade.
  static const Curve crossfade = Curves.easeInOut;

  /// Ease out cubic curve for card scroll animations.
  static const Curve cardScroll = Curves.easeOutCubic;

  /// Ease in out curve for progress bar animations.
  static const Curve progressBar = Curves.easeInOut;

  /// Ease out back curve for dialog open (subtle bounce).
  static const Curve dialogOpen = Curves.easeOutBack;

  /// Ease in curve for dialog close.
  static const Curve dialogClose = Curves.easeIn;
}

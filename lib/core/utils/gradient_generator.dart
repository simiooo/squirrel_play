import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';

/// Generates deterministic gradients for games without hero images.
///
/// Uses the game ID hash to select from predefined gradient palettes,
/// ensuring the same game always gets the same gradient.
class GradientGenerator {
  GradientGenerator._();

  /// Predefined gradient palettes for variety.
  /// Each palette is a list of colors for the gradient.
  static final List<List<Color>> _palettes = [
    // Deep charcoal to slightly lighter with orange accent
    [const Color(0xFF0D0D0F), const Color(0xFF1A1A1E), const Color(0xFFFF6B2B)],
    // Dark blue to purple
    [const Color(0xFF0D0D1F), const Color(0xFF1A1A3E), const Color(0xFF6B2BFF)],
    // Dark green to teal
    [const Color(0xFF0D1F0D), const Color(0xFF1A3E1A), const Color(0xFF00C9A7)],
    // Dark red to orange
    [const Color(0xFF1F0D0D), const Color(0xFF3E1A1A), const Color(0xFFFF4757)],
    // Dark purple to pink
    [const Color(0xFF1F0D1F), const Color(0xFF3E1A3E), const Color(0xFFFF2B9D)],
    // Dark cyan to blue
    [const Color(0xFF0D1F1F), const Color(0xFF1A3E3E), const Color(0xFF2B9DFF)],
    // Dark yellow to amber
    [const Color(0xFF1F1F0D), const Color(0xFF3E3E1A), const Color(0xFFFFB800)],
    // Dark slate to silver
    [const Color(0xFF0D0D0F), const Color(0xFF2A2A30), const Color(0xFFB0B0B8)],
  ];

  /// Generates a deterministic gradient based on game ID.
  ///
  /// [gameId] - The unique identifier for the game
  ///
  /// Returns a [LinearGradient] that will always be the same for the same game ID.
  static LinearGradient generateForGame(String gameId) {
    // Use hash code to select a palette
    final hash = gameId.hashCode.abs();
    final paletteIndex = hash % _palettes.length;
    final palette = _palettes[paletteIndex];

    // Use additional hash bits for gradient direction
    final directionIndex = (hash ~/ _palettes.length) % 4;
    final begin = _getBeginAlignment(directionIndex);
    final end = _getEndAlignment(directionIndex);

    return LinearGradient(
      begin: begin,
      end: end,
      colors: palette,
      stops: const [0.0, 0.7, 1.0],
    );
  }

  /// Gets the begin alignment based on direction index.
  static Alignment _getBeginAlignment(int index) {
    switch (index) {
      case 0:
        return Alignment.topLeft;
      case 1:
        return Alignment.topRight;
      case 2:
        return Alignment.bottomLeft;
      case 3:
        return Alignment.bottomRight;
      default:
        return Alignment.topLeft;
    }
  }

  /// Gets the end alignment based on direction index.
  static Alignment _getEndAlignment(int index) {
    switch (index) {
      case 0:
        return Alignment.bottomRight;
      case 1:
        return Alignment.bottomLeft;
      case 2:
        return Alignment.topRight;
      case 3:
        return Alignment.topLeft;
      default:
        return Alignment.bottomRight;
    }
  }

  /// Generates a default gradient for when no game is focused.
  static LinearGradient get defaultGradient {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.background,
        AppColors.backgroundDeep,
      ],
    );
  }
}

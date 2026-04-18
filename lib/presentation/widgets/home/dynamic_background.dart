import 'package:flutter/material.dart';

import 'package:squirrel_play/core/utils/gradient_generator.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/presentation/widgets/cached_game_image.dart';

/// Dynamic background widget that crossfades between game hero images.
///
/// Features:
/// - Crossfade animation when game changes (500ms, easeInOut)
/// - Real hero image from metadata with cached_network_image
/// - Gradient fallback for games without hero images
/// - Deterministic gradients based on game ID
class DynamicBackground extends StatefulWidget {
  /// The game to display background for (null = show default gradient).
  final Game? game;

  /// Optional metadata for the game.
  final GameMetadata? metadata;

  /// Duration of the crossfade animation.
  final Duration crossfadeDuration;

  /// Curve for the crossfade animation.
  final Curve crossfadeCurve;

  /// Creates a DynamicBackground widget.
  const DynamicBackground({
    super.key,
    this.game,
    this.metadata,
    this.crossfadeDuration = const Duration(milliseconds: 500),
    this.crossfadeCurve = Curves.easeInOut,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.crossfadeDuration,
      switchInCurve: widget.crossfadeCurve,
      switchOutCurve: widget.crossfadeCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _buildBackground(),
    );
  }

  Widget _buildBackground() {
    final game = widget.game;

    // If no game, show default gradient
    if (game == null) {
      return Container(
        key: const ValueKey('default_background'),
        decoration: BoxDecoration(
          gradient: GradientGenerator.defaultGradient,
        ),
      );
    }

    // Check if game has hero image metadata
    final heroImageUrl = widget.metadata?.heroImageUrl;

    if (heroImageUrl != null && heroImageUrl.isNotEmpty) {
      // Show hero image with gradient overlay for text readability
      return Container(
        key: ValueKey('hero_${game.id}'),
        child: CachedGameImage(
          imageUrl: heroImageUrl,
          fit: BoxFit.cover,
          showOverlay: true,
        ),
      );
    }

    // Fallback to cover image if available
    final coverImageUrl = widget.metadata?.coverImageUrl;
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      return Container(
        key: ValueKey('cover_${game.id}'),
        child: CachedGameImage(
          imageUrl: coverImageUrl,
          fit: BoxFit.cover,
          showOverlay: true,
        ),
      );
    }

    // Show deterministic gradient based on game ID
    return Container(
      key: ValueKey('gradient_${game.id}'),
      decoration: BoxDecoration(
        gradient: GradientGenerator.generateForGame(game.id),
      ),
    );
  }
}

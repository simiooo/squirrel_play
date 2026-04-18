import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';

/// Game info overlay widget showing focused game metadata in Netflix style.
///
/// Displays:
/// - Featured label badge
/// - Game title (large, bold)
/// - Description excerpt (max 3 lines)
/// - Genre chips
/// - Rating (if available)
///
/// Positioned at bottom-left of the background area.
class GameInfoOverlay extends StatelessWidget {
  /// The game to display info for (null = show nothing).
  final Game? game;

  /// Optional metadata for the game.
  final GameMetadata? metadata;

  /// Whether the overlay is visible.
  final bool isVisible;

  /// Creates a GameInfoOverlay widget.
  const GameInfoOverlay({
    super.key,
    this.game,
    this.metadata,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || game == null) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Game title
          Text(
            game!.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 48,
                  height: 1.05,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Developer / publisher info
          if (metadata?.developer != null)
            Text(
              metadata!.developer!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withAlpha(204),
                    fontSize: 15,
                  ),
            ),

          if (metadata?.developer != null)
            const SizedBox(height: AppSpacing.sm),

          // Description
          _buildDescription(context),

          const SizedBox(height: AppSpacing.md),

          // Genre chips and rating row
          Row(
            children: [
              Expanded(
                child: _buildGenreChips(context),
              ),
              _buildRating(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final description = _getDescription(context);

    return Text(
      description,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary.withAlpha(220),
            fontSize: 18,
            height: 1.5,
          ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGenreChips(BuildContext context) {
    final genres = metadata?.genres ?? [];

    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(100),
            border: Border.all(
              color: AppColors.textSecondary.withAlpha(80),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Text(
            genre,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRating(BuildContext context) {
    final rating = metadata?.rating;

    if (rating == null || rating == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star_rounded,
          color: AppColors.primaryAccent,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
      ],
    );
  }

  /// Gets the description from game metadata.
  String _getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final description = metadata?.description;

    if (description != null && description.isNotEmpty) {
      return _stripHtml(description);
    }

    return l10n?.noDescriptionAvailable ?? 'No description available';
  }

  /// Strips HTML tags from a string.
  String _stripHtml(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

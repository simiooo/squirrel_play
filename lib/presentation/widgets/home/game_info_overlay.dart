import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/cached_game_image.dart';

/// Utility function to format time ago.
String formatTimeAgo(DateTime dateTime, AppLocalizations? l10n) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return l10n?.timeAgoJustNow ?? 'just now';
  } else if (difference.inHours < 1) {
    return l10n?.timeAgoMinutes(difference.inMinutes) ??
        '${difference.inMinutes} minutes ago';
  } else if (difference.inDays < 1) {
    return l10n?.timeAgoHours(difference.inHours) ??
        '${difference.inHours} hours ago';
  } else if (difference.inDays < 7) {
    return l10n?.timeAgoDays(difference.inDays) ??
        '${difference.inDays} days ago';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return l10n?.timeAgoWeeks(weeks) ?? '$weeks weeks ago';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return l10n?.timeAgoMonths(months) ?? '$months months ago';
  } else {
    final years = (difference.inDays / 365).floor();
    return l10n?.timeAgoYears(years) ?? '$years years ago';
  }
}

/// Game info overlay widget showing focused game metadata.
///
/// Displays:
/// - Game title (large, bold)
/// - Description excerpt (max 3 lines)
/// - Genre chips
/// - Rating (if available)
/// - Screenshots (horizontal scrollable thumbnails)
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              AppColors.background.withAlpha(230),
              AppColors.background.withAlpha(128),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Game title
            Text(
              game!.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            _buildDescription(context),
            const SizedBox(height: AppSpacing.md),

            // Play count and last played
            _buildPlayStats(context),
            const SizedBox(height: AppSpacing.md),

            // Genre chips and rating
            Row(
              children: [
                // Genre chips
                Expanded(
                  child: _buildGenreChips(context),
                ),
                // Rating
                _buildRating(context),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Screenshots
            _buildScreenshots(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final description = _getDescription(context);

    return Text(
      description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
        fontSize: 16,
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(179),
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          child: Text(
            genre,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
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
          Icons.star,
          color: AppColors.primaryAccent,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshots(BuildContext context) {
    final screenshots = metadata?.screenshots ?? [];

    if (screenshots.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show max 5 screenshots
    final displayScreenshots = screenshots.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Screenshots',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayScreenshots.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  child: CachedGameImage(
                    imageUrl: displayScreenshots[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayStats(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final game = this.game;
    if (game == null) return const SizedBox.shrink();

    final playCountText = game.playCount > 0
        ? (l10n?.gameInfoPlayCount(game.playCount) ??
            'Played ${game.playCount} times')
        : (l10n?.gameInfoPlayCountNever ?? 'Never played');

    final lastPlayedText = game.lastPlayedDate != null
        ? (l10n?.gameInfoLastPlayed(formatTimeAgo(game.lastPlayedDate!, l10n)) ??
            'Last played: ${formatTimeAgo(game.lastPlayedDate!, l10n)}')
        : (l10n?.gameInfoLastPlayedNever ?? 'Never played');

    return Row(
      children: [
        // Play count
        const Icon(
          Icons.play_circle_outline,
          color: AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          playCountText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // Last played
        const Icon(
          Icons.access_time,
          color: AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          lastPlayedText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
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
      // Strip HTML tags if present
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

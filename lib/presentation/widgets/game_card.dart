import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/presentation/widgets/cached_game_image.dart';

/// A reusable game card widget with focus animations.
///
/// Features:
/// - 2:3 aspect ratio per design spec
/// - Scale animation on focus (1.0 → 1.08)
/// - Glow/border effect on focus
/// - Sound hooks (playFocusMove on focus, playFocusSelect on press)
/// - Real cover image from metadata with cached_network_image
/// - Genre chips (max 3)
/// - Rating badge
/// - Context action (X button) for deletion and re-fetch
///
/// Note: Focus state comes exclusively from [focusNode.hasFocus].
/// The [isSelected] parameter is for a separate "selected" visual state
/// (e.g., multi-select mode) and uses a different visual treatment.
class GameCard extends StatefulWidget {
  /// Creates a game card.
  const GameCard({
    super.key,
    required this.focusNode,
    required this.game,
    required this.onPressed,
    this.onContextAction,
    this.onRefetchMetadata,
    this.onFavoriteToggle,
    this.metadata,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.placeholderColor,
    this.isSelected = false,
  });

  /// The focus node for this card.
  final FocusNode focusNode;

  /// The game entity to display.
  final Game game;

  /// Callback when the card is pressed/activated.
  final VoidCallback onPressed;

  /// Callback when the context action (X button) is triggered.
  final VoidCallback? onContextAction;

  /// Callback when re-fetch metadata is requested.
  final VoidCallback? onRefetchMetadata;

  /// Callback when favorite status is toggled.
  final VoidCallback? onFavoriteToggle;

  /// Optional metadata for the game.
  final GameMetadata? metadata;

  /// Whether metadata is currently loading.
  final bool isLoading;

  /// Whether there was an error loading metadata.
  final bool hasError;

  /// Error message to display.
  final String? errorMessage;

  /// Optional color for the placeholder gradient.
  final Color? placeholderColor;

  /// Whether this card is in "selected" state (for multi-select).
  ///
  /// This is different from focus state. When true, shows a checkmark
  /// indicator. Focus state is determined by [focusNode.hasFocus].
  final bool isSelected;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    final isFocused = widget.focusNode.hasFocus;

    // Play sound when gaining focus (debounced by SoundService)
    if (isFocused && !_wasFocused) {
      SoundService.instance.playFocusMove();
    }

    setState(() {
      _wasFocused = isFocused;
    });
  }

  void _handlePress() {
    // Play select sound immediately
    SoundService.instance.playFocusSelect();
    widget.onPressed();
  }

  void _handleContextAction() {
    if (widget.onContextAction != null) {
      SoundService.instance.playFocusSelect();
      widget.onContextAction!();
    }
  }

  void _handleRefetchMetadata() {
    if (widget.onRefetchMetadata != null) {
      SoundService.instance.playFocusSelect();
      widget.onRefetchMetadata!();
    }
  }

  void _handleFavoriteToggle() {
    if (widget.onFavoriteToggle != null) {
      SoundService.instance.playFocusSelect();
      widget.onFavoriteToggle!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final cardSize = CardDimensions.getSize(breakpoint);

    return Semantics(
      button: true,
      label: widget.game.title,
      hint: 'Game card - press A to select, X for options, Y to re-fetch metadata',
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handlePress();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: widget.focusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.gameButtonX ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                _handleContextAction();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.gameButtonY ||
                  event.logicalKey == LogicalKeyboardKey.keyF) {
                _handleRefetchMetadata();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.gameButtonY ||
                  event.logicalKey == LogicalKeyboardKey.keyY) {
                _handleFavoriteToggle();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedScale(
            scale: isFocused ? 1.08 : 1.0,
            duration: isFocused
                ? const Duration(milliseconds: 200)
                : const Duration(milliseconds: 150),
            curve: isFocused
                ? AppAnimationCurves.pageEnter
                : AppAnimationCurves.pageExit,
            child: GestureDetector(
              onTap: _handlePress,
              child: Container(
                width: cardSize.width,
                height: cardSize.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primaryAccent.withAlpha(128),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(64),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  border: isFocused
                      ? Border.all(
                          color: AppColors.primaryAccent,
                          width: 2,
                        )
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover image or placeholder
                        _buildCoverImage(),

                        // Gradient overlay for text readability
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(204),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  widget.game.title,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                // Genre chips
                                _buildGenreChips(),
                              ],
                            ),
                          ),
                        ),

                        // Rating badge (top right)
                        if (widget.metadata?.rating != null)
                          Positioned(
                            top: AppSpacing.sm,
                            right: AppSpacing.sm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent,
                                borderRadius: BorderRadius.circular(AppRadii.small),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.metadata!.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Selected indicator (checkmark)
                        if (widget.isSelected)
                          Positioned(
                            top: AppSpacing.sm,
                            left: AppSpacing.sm,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent,
                                borderRadius: BorderRadius.circular(AppRadii.small),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),

                        // Context action button (X) - visible when focused
                        if (isFocused && widget.onContextAction != null)
                          Positioned(
                            top: AppSpacing.sm,
                            left: widget.isSelected ? 40 : AppSpacing.sm,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(AppRadii.small),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),

                        // Favorite button (Y) - visible when focused
                        if (isFocused)
                          Positioned(
                            top: AppSpacing.sm,
                            right: AppSpacing.sm,
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.game.isFavorite
                                    ? AppColors.primaryAccent
                                    : AppColors.surface.withAlpha(179),
                                borderRadius: BorderRadius.circular(AppRadii.small),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Icon(
                                widget.game.isFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),

                        // Re-fetch button (Y) - visible when focused
                        if (isFocused && widget.onRefetchMetadata != null)
                          Positioned(
                            top: AppSpacing.sm,
                            left: widget.isSelected
                                ? (widget.onContextAction != null ? 72 : 40)
                                : (widget.onContextAction != null ? 40 : AppSpacing.sm),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.secondaryAccent,
                                borderRadius: BorderRadius.circular(AppRadii.small),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),

                        // Loading indicator
                        if (widget.isLoading)
                          Positioned(
                            top: AppSpacing.sm,
                            right: AppSpacing.sm,
                            child: Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withAlpha(179),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryAccent,
                                ),
                              ),
                            ),
                          ),

                        // Error indicator
                        if (widget.hasError)
                          Positioned(
                            top: AppSpacing.sm,
                            right: AppSpacing.sm,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(179),
                                borderRadius: BorderRadius.circular(AppRadii.small),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final url = widget.metadata?.coverImageUrl;

    if (url != null && url.isNotEmpty) {
      return CachedGameImage(
        imageUrl: url,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        placeholderColor: widget.placeholderColor,
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final baseColor = widget.placeholderColor ?? AppColors.surfaceElevated;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.3) ?? baseColor,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.videogame_asset_outlined,
          size: 48,
          color: AppColors.textMuted.withAlpha(128),
        ),
      ),
    );
  }

  Widget _buildGenreChips() {
    final genres = widget.metadata?.genres ?? [];

    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show max 3 genres
    final displayGenres = genres.take(3).toList();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: displayGenres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(128),
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          child: Text(
            genre,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }
}

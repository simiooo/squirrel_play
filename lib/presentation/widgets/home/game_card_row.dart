import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/game_card.dart';

/// Horizontal scrolling row of game cards.
///
/// Features:
/// - Focusable header with title
/// - Horizontal ListView with custom scroll physics
/// - Smooth scroll animation when navigating past visible cards
/// - Focus management integration with FocusTraversalService
/// - Responsive card count per breakpoint
class GameCardRow extends StatefulWidget {
  /// The home row data.
  final HomeRow row;

  /// Index of this row (for focus management).
  final int rowIndex;

  /// Index of the currently focused card in this row (-1 if header focused).
  final int? focusedCardIndex;

  /// Whether this row is currently focused.
  final bool isRowFocused;

  /// Callback when a card receives focus.
  final ValueChanged<int> onCardFocused;

  /// Callback when a card is selected/activated.
  final ValueChanged<int> onCardSelected;

  /// Callback when the row header receives focus.
  final VoidCallback onHeaderFocused;

  /// Callback when the row header is activated.
  final VoidCallback onHeaderActivated;

  /// Creates a GameCardRow widget.
  const GameCardRow({
    super.key,
    required this.row,
    required this.rowIndex,
    this.focusedCardIndex,
    this.isRowFocused = false,
    required this.onCardFocused,
    required this.onCardSelected,
    required this.onHeaderFocused,
    required this.onHeaderActivated,
  });

  @override
  State<GameCardRow> createState() => _GameCardRowState();
}

class _GameCardRowState extends State<GameCardRow> {
  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _cardFocusNodes = [];
  late FocusNode _headerFocusNode;

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode(debugLabel: 'RowHeader_${widget.row.id}');
    _initializeCardFocusNodes();

    // Register with focus traversal service for row navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusTraversalService.instance.registerRow(
        'row_${widget.row.id}',
        [_headerFocusNode, ..._cardFocusNodes],
      );
    });
  }

  @override
  void didUpdateWidget(GameCardRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle row data changes
    if (widget.row.games.length != oldWidget.row.games.length) {
      _disposeCardFocusNodes();
      _initializeCardFocusNodes();
    }

    // Scroll to focused card if needed
    if (widget.focusedCardIndex != null &&
        widget.focusedCardIndex != oldWidget.focusedCardIndex) {
      _scrollToCard(widget.focusedCardIndex!);
    }
  }

  @override
  void dispose() {
    FocusTraversalService.instance.unregisterRow('row_${widget.row.id}');
    for (final node in _cardFocusNodes) {
      node.dispose();
    }
    _headerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeCardFocusNodes() {
    for (int i = 0; i < widget.row.games.length; i++) {
      final node = FocusNode(debugLabel: 'Card_${widget.row.id}_$i');
      node.addListener(() => _onCardFocusChanged(i));
      _cardFocusNodes.add(node);
    }
  }

  void _disposeCardFocusNodes() {
    for (final node in _cardFocusNodes) {
      node.dispose();
    }
    _cardFocusNodes.clear();
  }

  void _onCardFocusChanged(int index) {
    if (_cardFocusNodes[index].hasFocus) {
      widget.onCardFocused(index);
      _scrollToCard(index);
    }
  }

  void _scrollToCard(int index) {
    if (!_scrollController.hasClients) return;

    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final cardWidth = CardDimensions.getWidth(breakpoint);
    final cardSpacing = AppSpacing.lg;
    final totalCardWidth = cardWidth + cardSpacing;

    final targetOffset = index * totalCardWidth;
    final viewportWidth = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Calculate the scroll offset to center the card
    var scrollOffset = targetOffset - (viewportWidth / 2) + (cardWidth / 2);

    // Clamp to valid range
    scrollOffset = scrollOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      scrollOffset,
      duration: AppAnimationDurations.cardScroll,
      curve: AppAnimationCurves.cardScroll,
    );
  }

  void _handleHeaderActivate() {
    SoundService.instance.playFocusSelect();
    widget.onHeaderActivated();
  }

  void _handleCardActivate(int index) {
    SoundService.instance.playFocusSelect();
    widget.onCardSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row header
        _buildHeader(context, l10n),
        const SizedBox(height: AppSpacing.md),

        // Card list
        SizedBox(
          height: _getCardHeight(context),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: widget.row.games.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.row.games.length - 1 ? AppSpacing.lg : 0,
                ),
                child: GameCard(
                  focusNode: _cardFocusNodes[index],
                  game: widget.row.games[index],
                  onPressed: () => _handleCardActivate(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Focus(
        focusNode: _headerFocusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            widget.onHeaderFocused();
          }
        },
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;

            return GestureDetector(
              onTap: _handleHeaderActivate,
              child: AnimatedContainer(
                duration: AppAnimationDurations.focusIn,
                curve: AppAnimationCurves.focusIn,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isFocused
                      ? AppColors.surfaceElevated
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  border: isFocused
                      ? Border.all(
                          color: AppColors.primaryAccent,
                          width: 2,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getRowTitle(l10n),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: isFocused
                                ? AppColors.primaryAccent
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    if (widget.row.isNavigable) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward,
                        color: isFocused
                            ? AppColors.primaryAccent
                            : AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getRowTitle(AppLocalizations? l10n) {
    switch (widget.row.type) {
      case HomeRowType.recentlyAdded:
        return l10n?.homeRowRecentlyAdded ?? 'Recently Added';
      case HomeRowType.allGames:
        return l10n?.homeRowAllGames ?? 'All Games';
      case HomeRowType.favorites:
        return l10n?.homeRowFavorites ?? 'Favorites';
      case HomeRowType.recentlyPlayed:
        return l10n?.homeRowRecentlyPlayed ?? 'Recently Played';
    }
  }

  double _getCardHeight(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    return CardDimensions.getHeight(breakpoint);
  }
}
import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/game_card.dart';

/// Horizontal scrolling row of game cards with Netflix-style layout.
///
/// Features:
/// - Focusable header with title
/// - Horizontal ListView with custom scroll physics
/// - Smooth scroll animation when navigating past visible cards
/// - Focus management integration with FocusTraversalService
/// - Responsive card count per breakpoint
/// - Optional "View All" button at the end when games exceed maxVisibleGames
class GameCardRow extends StatefulWidget {
  /// The home row data.
  final HomeRow row;

  /// Index of this row (for focus management).
  final int rowIndex;

  /// Index of the currently focused card in this row (-1 if header focused).
  final int? focusedCardIndex;

  /// Whether this row is currently focused.
  final bool isRowFocused;

  /// Maximum number of game cards to display before showing "View All" button.
  final int? maxVisibleGames;

  /// Callback when a card receives focus.
  final ValueChanged<int> onCardFocused;

  /// Callback when a card is selected/activated.
  final ValueChanged<int> onCardSelected;

  /// Callback when the row header receives focus.
  final VoidCallback onHeaderFocused;

  /// Callback when the row header is activated.
  final VoidCallback onHeaderActivated;

  /// Callback when "View All" button is pressed.
  final VoidCallback? onViewAllPressed;

  /// Creates a GameCardRow widget.
  const GameCardRow({
    super.key,
    required this.row,
    required this.rowIndex,
    this.focusedCardIndex,
    this.isRowFocused = false,
    this.maxVisibleGames,
    required this.onCardFocused,
    required this.onCardSelected,
    required this.onHeaderFocused,
    required this.onHeaderActivated,
    this.onViewAllPressed,
  });

  @override
  State<GameCardRow> createState() => _GameCardRowState();
}

class _GameCardRowState extends State<GameCardRow> {
  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _cardFocusNodes = [];
  FocusNode? _viewAllFocusNode;

  /// Games visible in this row (may be truncated by maxVisibleGames).
  List<Game> get _visibleGames {
    if (widget.maxVisibleGames != null &&
        widget.row.games.length > widget.maxVisibleGames!) {
      return widget.row.games.take(widget.maxVisibleGames!).toList();
    }
    return widget.row.games;
  }

  /// Whether to show the "View All" button.
  bool get _showViewAllButton =>
      widget.maxVisibleGames != null &&
      widget.row.games.length > widget.maxVisibleGames!;

  @override
  void initState() {
    super.initState();
    _initializeCardFocusNodes();
    if (_showViewAllButton) {
      _viewAllFocusNode = FocusNode(
        debugLabel: 'ViewAll_${widget.row.id}',
      );
    }

    // Register with focus traversal service for row navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nodes = List<FocusNode>.from(_cardFocusNodes);
      if (_viewAllFocusNode != null) {
        nodes.add(_viewAllFocusNode!);
      }
      FocusTraversalService.instance.registerRow(
        'row_${widget.row.id}',
        nodes,
      );

      // Auto-focus the initially focused card when the row is focused
      if (widget.isRowFocused &&
          widget.focusedCardIndex != null &&
          widget.focusedCardIndex! >= 0 &&
          widget.focusedCardIndex! < _cardFocusNodes.length) {
        _cardFocusNodes[widget.focusedCardIndex!].requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(GameCardRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle row data changes
    final oldVisibleCount = oldWidget.maxVisibleGames != null &&
            oldWidget.row.games.length > oldWidget.maxVisibleGames!
        ? oldWidget.maxVisibleGames!
        : oldWidget.row.games.length;
    final newVisibleCount = _visibleGames.length;

    if (newVisibleCount != oldVisibleCount) {
      _disposeCardFocusNodes();
      _initializeCardFocusNodes();

      // Handle view all button focus node
      if (_showViewAllButton && _viewAllFocusNode == null) {
        _viewAllFocusNode = FocusNode(
          debugLabel: 'ViewAll_${widget.row.id}',
        );
      } else if (!_showViewAllButton && _viewAllFocusNode != null) {
        _viewAllFocusNode!.dispose();
        _viewAllFocusNode = null;
      }

      // Re-register with the focus traversal service using updated nodes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusTraversalService.instance.unregisterRow(
          'row_${widget.row.id}',
        );
        final nodes = List<FocusNode>.from(_cardFocusNodes);
        if (_viewAllFocusNode != null) {
          nodes.add(_viewAllFocusNode!);
        }
        FocusTraversalService.instance.registerRow(
          'row_${widget.row.id}',
          nodes,
        );
      });
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
    _viewAllFocusNode?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeCardFocusNodes() {
    for (int i = 0; i < _visibleGames.length; i++) {
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

  void _handleCardActivate(int index) {
    SoundService.instance.playFocusSelect();
    widget.onCardSelected(index);
  }

  void _handleViewAllActivate() {
    SoundService.instance.playFocusSelect();
    widget.onViewAllPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: _getCardHeight(context),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: _visibleGames.length + (_showViewAllButton ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _visibleGames.length) {
            final isLastCard = index == _visibleGames.length - 1;
            final hasViewAllAfter = _showViewAllButton;

            return Padding(
              padding: EdgeInsets.only(
                right: isLastCard && !hasViewAllAfter ? 0 : AppSpacing.lg,
              ),
              child: GameCard(
                focusNode: _cardFocusNodes[index],
                game: _visibleGames[index],
                onPressed: () => _handleCardActivate(index),
              ),
            );
          } else {
            // View All button
            return Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              child: _buildViewAllButton(context, l10n),
            );
          }
        },
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context, AppLocalizations? l10n) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final cardWidth = CardDimensions.getWidth(breakpoint);
    final cardHeight = CardDimensions.getHeight(breakpoint);

    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleViewAllActivate();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _viewAllFocusNode,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            SoundService.instance.playFocusMove();
          }
        },
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;

            return GestureDetector(
              onTap: _handleViewAllActivate,
            child: AnimatedContainer(
              duration: AppAnimationDurations.focusIn,
              curve: AppAnimationCurves.focusIn,
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                color: isFocused
                    ? AppColors.surfaceElevated
                    : AppColors.surface.withAlpha(100),
                borderRadius: BorderRadius.circular(AppRadii.medium),
                border: isFocused
                    ? Border.all(
                        color: AppColors.primaryAccent,
                        width: 2,
                      )
                    : Border.all(
                        color: AppColors.textSecondary.withAlpha(60),
                        width: 1,
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isFocused ? 1.2 : 1.0,
                    duration: AppAnimationDurations.focusIn,
                    curve: AppAnimationCurves.focusIn,
                    child: Icon(
                      Icons.arrow_forward,
                      color: isFocused
                          ? AppColors.primaryAccent
                          : AppColors.textSecondary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n?.viewAllGames ?? 'View All',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFocused
                              ? AppColors.primaryAccent
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
  }

  double _getCardHeight(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    return CardDimensions.getHeight(breakpoint);
  }
}

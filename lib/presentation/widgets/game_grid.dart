import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/game_card.dart';

/// A responsive grid of game cards with virtualization.
///
/// Features:
/// - Responsive column count based on breakpoints with max/min card width
/// - Virtualized rendering via [GridView.builder] for performance
/// - Gamepad navigation support
/// - Focus management
/// - Game deletion support
class GameGrid extends StatefulWidget {
  /// Creates the game grid.
  const GameGrid({
    super.key,
    required this.games,
    required this.onGameSelected,
    required this.onGameDeleted,
    this.focusedIndex = 0,
  });

  /// List of games to display.
  final List<Game> games;

  /// Callback when a game is selected.
  final ValueChanged<Game> onGameSelected;

  /// Callback when a game is deleted.
  final ValueChanged<Game> onGameDeleted;

  /// Index of the initially focused game.
  final int focusedIndex;

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  List<List<FocusNode>> _gridFocusNodes = [];
  int _currentFocusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentFocusedIndex = widget.focusedIndex;
  }

  @override
  void didUpdateWidget(GameGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.games.length != oldWidget.games.length) {
      // Mark focus nodes for recreation on next build
      _unregisterGrid();
      _disposeFocusNodes();
      _gridFocusNodes = [];
    }
  }

  @override
  void dispose() {
    _unregisterGrid();
    _disposeFocusNodes();
    super.dispose();
  }

  void _createFocusNodes(int columns) {
    final rows = (widget.games.length / columns).ceil();

    _gridFocusNodes = [];
    for (int row = 0; row < rows; row++) {
      final rowNodes = <FocusNode>[];
      for (int col = 0; col < columns; col++) {
        final index = row * columns + col;
        if (index < widget.games.length) {
          rowNodes.add(
            FocusNode(debugLabel: 'GameCard_R${row}C$col'),
          );
        }
      }
      if (rowNodes.isNotEmpty) {
        _gridFocusNodes.add(rowNodes);
      }
    }
  }

  void _disposeFocusNodes() {
    for (final row in _gridFocusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
  }

  void _registerGrid() {
    if (_gridFocusNodes.isNotEmpty) {
      FocusTraversalService.instance.registerGrid('gameGrid', _gridFocusNodes);
    }
  }

  void _unregisterGrid() {
    FocusTraversalService.instance.unregisterGrid('gameGrid');
  }

  void _focusGameAtIndex(int index) {
    if (index < 0 || index >= widget.games.length) return;

    final columns = _gridFocusNodes.isNotEmpty ? _gridFocusNodes[0].length : 1;
    final row = index ~/ columns;
    final col = index % columns;

    if (row < _gridFocusNodes.length && col < _gridFocusNodes[row].length) {
      _gridFocusNodes[row][col].requestFocus();
    }
  }

  int _getColumnCount(double availableWidth) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final screenWidth = MediaQuery.of(context).size.width;

    const spacing = AppSpacing.lg;
    const maxCardWidth = 400.0;
    const minCardWidth = 160.0;

    // Account for GridView padding
    final effectiveWidth = availableWidth - AppSpacing.lg * 2;

    int baseCount;
    switch (breakpoint) {
      case ResponsiveLayout.compact:
        baseCount = 1;
      case ResponsiveLayout.medium:
        baseCount = 2;
      case ResponsiveLayout.expanded:
        baseCount = 3;
      case ResponsiveLayout.large:
        baseCount = screenWidth > 1920 ? 5 : 4;
    }

    var count = baseCount;

    // Increase columns if cards would exceed max width
    while (count < 8) {
      final totalSpacing = spacing * (count - 1);
      final cardWidth = (effectiveWidth - totalSpacing) / count;
      if (cardWidth <= maxCardWidth) break;
      count++;
    }

    // Decrease columns if cards would be too narrow
    while (count > 1) {
      final totalSpacing = spacing * (count - 1);
      final cardWidth = (effectiveWidth - totalSpacing) / count;
      if (cardWidth >= minCardWidth) break;
      count--;
    }

    return count;
  }

  void _handleGameSelected(Game game) {
    widget.onGameSelected(game);
  }

  void _handleGameDeleted(Game game) {
    widget.onGameDeleted(game);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _getColumnCount(constraints.maxWidth);

        // Determine if focus nodes need recreation
        final bool needsRecreation = _gridFocusNodes.isEmpty ||
            widget.games.isEmpty ||
            (_gridFocusNodes.isNotEmpty && _gridFocusNodes[0].length != columns) ||
            (_gridFocusNodes.length * columns < widget.games.length) ||
            ((_gridFocusNodes.length - 1) * columns +
                    _gridFocusNodes.last.length !=
                widget.games.length);

        if (needsRecreation && widget.games.isNotEmpty) {
          _unregisterGrid();
          _disposeFocusNodes();
          _createFocusNodes(columns);
          _registerGrid();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _focusGameAtIndex(
              _currentFocusedIndex.clamp(0, widget.games.length - 1),
            );
          });
        }

        if (widget.games.isEmpty) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.xl),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 16 / 9,
            crossAxisSpacing: AppSpacing.xl,
            mainAxisSpacing: AppSpacing.xl,
          ),
          itemCount: widget.games.length,
          itemBuilder: (context, index) {
            final game = widget.games[index];
            final row = index ~/ columns;
            final col = index % columns;
            final focusNode = _gridFocusNodes[row][col];

            return GameCard(
              focusNode: focusNode,
              game: game,
              expandToFit: true,
              onPressed: () => _handleGameSelected(game),
              onContextAction: () => _handleGameDeleted(game),
            );
          },
        );
      },
    );
  }
}

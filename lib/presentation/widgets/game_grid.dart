import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/game_card.dart';

/// A responsive grid of game cards.
///
/// Features:
/// - Responsive column count based on breakpoints
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
  late List<List<FocusNode>> _gridFocusNodes;
  int _currentFocusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentFocusedIndex = widget.focusedIndex;
    _createFocusNodes();

    // Register with focus traversal service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFocusNodes();
      // Focus the initial game
      _focusGameAtIndex(_currentFocusedIndex);
    });
  }

  @override
  void didUpdateWidget(GameGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.games.length != oldWidget.games.length) {
      // Rebuild focus nodes if game count changed
      _unregisterFocusNodes();
      _createFocusNodes();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerFocusNodes();
        _focusGameAtIndex(_currentFocusedIndex.clamp(0, widget.games.length - 1));
      });
    }
  }

  @override
  void dispose() {
    _unregisterFocusNodes();
    _disposeFocusNodes();
    super.dispose();
  }

  void _createFocusNodes() {
    final columns = _getColumnCount();
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

  void _registerFocusNodes() {
    if (_gridFocusNodes.isNotEmpty) {
      FocusTraversalService.instance.registerGrid('gameGrid', _gridFocusNodes);
      for (final row in _gridFocusNodes) {
        for (final node in row) {
          FocusTraversalService.instance.registerContentNode(node);
        }
      }
    }
  }

  void _unregisterFocusNodes() {
    FocusTraversalService.instance.unregisterGrid('gameGrid');
    for (final row in _gridFocusNodes) {
      for (final node in row) {
        FocusTraversalService.instance.unregisterContentNode(node);
      }
    }
  }

  void _focusGameAtIndex(int index) {
    if (index < 0 || index >= widget.games.length) return;

    final columns = _getColumnCount();
    final row = index ~/ columns;
    final col = index % columns;

    if (row < _gridFocusNodes.length && col < _gridFocusNodes[row].length) {
      _gridFocusNodes[row][col].requestFocus();
    }
  }

  int _getColumnCount() {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (breakpoint) {
      case ResponsiveLayout.compact:
        return 1;
      case ResponsiveLayout.medium:
        return 2;
      case ResponsiveLayout.expanded:
        return 3;
      case ResponsiveLayout.large:
        // Return 5 columns for screens wider than 1920px, 4 columns otherwise
        return screenWidth > 1920 ? 5 : 4;
    }
  }

  void _handleGameSelected(Game game) {
    widget.onGameSelected(game);
  }

  void _handleGameDeleted(Game game) {
    widget.onGameDeleted(game);
  }

  @override
  Widget build(BuildContext context) {
    final columns = _getColumnCount();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: _buildRows(columns),
          ),
        );
      },
    );
  }

  List<Widget> _buildRows(int columns) {
    final rows = <Widget>[];
    final rowCount = (widget.games.length / columns).ceil();

    for (int row = 0; row < rowCount; row++) {
      final rowWidgets = <Widget>[];

      for (int col = 0; col < columns; col++) {
        final index = row * columns + col;
        if (index >= widget.games.length) break;

        final game = widget.games[index];
        final focusNode = _gridFocusNodes[row][col];

        rowWidgets.add(
          Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            child: GameCard(
              focusNode: focusNode,
              game: game,
              onPressed: () => _handleGameSelected(game),
              onContextAction: () => _handleGameDeleted(game),
            ),
          ),
        );
      }

      if (rowWidgets.isNotEmpty) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: rowWidgets,
          ),
        );
      }
    }

    return rows;
  }
}

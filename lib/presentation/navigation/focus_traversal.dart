import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/data/services/gamepad_service.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// Service for managing focus traversal with gamepad and keyboard input.
///
/// This service delegates focus-tree traversal to Flutter's built-in
/// [FocusScope] mechanism where possible, and only handles what Flutter
/// cannot do natively:
/// - Cross-Scope wrapping (TopBar ↔ Content ↔ BottomNav)
/// - Row/grid directional navigation with gamepad/keyboard event routing
/// - Focus history and activation callbacks
/// - Sound effects on focus moves
class FocusTraversalService {
  /// Singleton instance.
  static final FocusTraversalService _instance = FocusTraversalService._internal();

  /// Gets the singleton instance.
  static FocusTraversalService get instance => _instance;

  /// When true, gamepad actions (except cancel/back) are suppressed.
  /// Used by the gamepad test page to prevent navigation while testing.
  static bool suppressActions = false;

  /// Internal constructor.
  FocusTraversalService._internal();

  /// Whether the service is initialized.
  bool _isInitialized = false;

  /// Reference to the gamepad service.
  GamepadService? _gamepadService;

  /// Subscription to gamepad actions.
  StreamSubscription<GamepadAction>? _gamepadSubscription;

  /// The focus scope node for the top bar container.
  FocusScopeNode? _topBarFocusNode;

  /// The focus scope node for the content area container.
  FocusScopeNode? _contentFocusNode;

  /// The focus scope node for the bottom nav container.
  FocusScopeNode? _bottomNavFocusNode;

  /// Registered row focus groups.
  final Map<String, List<FocusNode>> _rowGroups = {};

  /// Registered grid focus groups.
  final Map<String, List<List<FocusNode>>> _gridGroups = {};

  /// Focus history stack (max 10 entries).
  final List<FocusNode> _focusHistory = [];

  /// Maximum depth of focus history stack.
  static const int _maxHistoryDepth = 10;

  /// Callbacks registered for focus node activation.
  final Map<FocusNode, VoidCallback> _activationCallbacks = {};

  /// Stream controller for current focus node changes.
  final _currentFocusController = StreamController<FocusNode?>.broadcast();

  /// Gets the stream of current focus node changes.
  Stream<FocusNode?> get currentFocusStream => _currentFocusController.stream;

  /// Gets the currently focused node.
  FocusNode? get currentFocusNode =>
      WidgetsBinding.instance.focusManager.primaryFocus;

  /// Returns true if the current focus is inside a dialog scope.
  bool get isDialogOpen => _isFocusInsideDialog();

  /// Initializes the focus traversal service.
  ///
  /// Sets up keyboard and gamepad listeners for focus navigation.
  Future<void> initialize({GamepadService? gamepadService}) async {
    if (_isInitialized) {
      debugPrint('[FocusTraversalService] Already initialized');
      return;
    }

    debugPrint('[FocusTraversalService] Initializing...');

    _gamepadService = gamepadService;

    // Subscribe to gamepad actions if available
    if (_gamepadService != null) {
      _gamepadSubscription = _gamepadService!.actions.listen(_onGamepadAction);
      debugPrint('[FocusTraversalService] Subscribed to gamepad events');
    }

    // Set up keyboard handler
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    debugPrint('[FocusTraversalService] Keyboard handler registered');

    _isInitialized = true;
    debugPrint('[FocusTraversalService] Initialized successfully');
  }

  /// Disposes the service and cleans up resources.
  void dispose() {
    debugPrint('[FocusTraversalService] Disposing...');
    _gamepadSubscription?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _currentFocusController.close();
    _isInitialized = false;
  }

  /// Map of focus nodes to their registered listeners, for cleanup on unregister.
  final Map<FocusNode, VoidCallback> _registeredNodeListeners = {};

  /// Registers a row of focus nodes for horizontal navigation.
  void registerRow(String rowId, List<FocusNode> nodes) {
    _rowGroups[rowId] = nodes;
    for (final node in nodes) {
      void listener() => _onNodeFocusChanged(node);
      _registeredNodeListeners[node] = listener;
      node.addListener(listener);
    }
    debugPrint('[FocusTraversalService] Registered row "$rowId" with ${nodes.length} nodes');
  }

  /// Registers a 2D grid of focus nodes.
  void registerGrid(String gridId, List<List<FocusNode>> nodes) {
    _gridGroups[gridId] = nodes;
    for (final row in nodes) {
      for (final node in row) {
        void listener() => _onNodeFocusChanged(node);
        _registeredNodeListeners[node] = listener;
        node.addListener(listener);
      }
    }
    debugPrint(
      '[FocusTraversalService] Registered grid "$gridId" with '
      '${nodes.length} rows',
    );
  }

  /// Removes the registered listener from a focus node and the tracking map.
  void _removeNodeListener(FocusNode node) {
    final listener = _registeredNodeListeners.remove(node);
    if (listener != null) {
      node.removeListener(listener);
    }
  }

  /// Unregisters a row and removes all its node listeners.
  void unregisterRow(String rowId) {
    final nodes = _rowGroups.remove(rowId);
    if (nodes != null) {
      for (final node in nodes) {
        _removeNodeListener(node);
      }
    }
  }

  /// Unregisters a grid and removes all its node listeners.
  void unregisterGrid(String gridId) {
    final grid = _gridGroups.remove(gridId);
    if (grid != null) {
      for (final row in grid) {
        for (final node in row) {
          _removeNodeListener(node);
        }
      }
    }
  }

  /// Clears all row and grid registrations and removes all node listeners.
  void clearRowAndGridRegistrations() {
    for (final entry in _registeredNodeListeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _registeredNodeListeners.clear();
    _rowGroups.clear();
    _gridGroups.clear();
    debugPrint('[FocusTraversalService] Cleared row and grid registrations');
  }

  /// Sets the top bar container focus scope node.
  void setTopBarContainer(FocusScopeNode node) {
    _topBarFocusNode = node;
  }

  /// Sets the content area container focus scope node.
  void setContentContainer(FocusScopeNode node) {
    _contentFocusNode = node;
  }

  /// Sets the bottom nav container focus scope node.
  void setBottomNavContainer(FocusScopeNode node) {
    _bottomNavFocusNode = node;
  }

  /// Called when a node's focus state changes.
  void _onNodeFocusChanged(FocusNode node) {
    if (node.hasFocus) {
      _currentFocusController.add(node);
      _addToHistory(node);
    }
  }

  /// Adds a node to the focus history stack.
  void _addToHistory(FocusNode node) {
    // Don't add dialog nodes to history
    if (_isFocusInsideDialog()) {
      return;
    }

    // Don't add non-interactive nodes (e.g., Scrollable) to history
    if (!_isInteractiveFocusNode(node)) {
      return;
    }

    // Remove if already in history (to move to front)
    _focusHistory.remove(node);

    // Add to front
    _focusHistory.insert(0, node);

    // Trim to max depth
    if (_focusHistory.length > _maxHistoryDepth) {
      _focusHistory.removeLast();
    }
  }

  /// Clears the focus history stack.
  void clearHistory() {
    _focusHistory.clear();
    debugPrint('[FocusTraversalService] Focus history cleared');
  }

  /// Navigates back using focus history.
  ///
  /// Pops the most recent entry and requests focus on that node.
  /// Returns true if navigation occurred.
  bool goBack() {
    if (_focusHistory.isEmpty) {
      return false;
    }

    // Remove current node from history
    final current = currentFocusNode;
    if (current != null) {
      _focusHistory.remove(current);
    }

    // Get previous node
    if (_focusHistory.isEmpty) {
      return false;
    }

    final previousNode = _focusHistory.removeAt(0);
    previousNode.requestFocus();
    SoundService.instance.playFocusBack();
    debugPrint(
      '[FocusTraversalService] Navigated back to: '
      '${previousNode.debugLabel ?? "unnamed"}',
    );
    return true;
  }

  /// Checks whether the primary focus is inside a dialog scope by walking
  /// up the focus tree and looking for a [FocusScopeNode] that is not the
  /// top bar or content scope and has a label indicating a modal/dialog.
  bool _isFocusInsideDialog() {
    final node = WidgetsBinding.instance.focusManager.primaryFocus;
    if (node == null) return false;
    var current = node.parent;
    while (current != null) {
      if (current is FocusScopeNode &&
          current != _topBarFocusNode &&
          current != _contentFocusNode &&
          current != _bottomNavFocusNode) {
        final label = current.debugLabel ?? '';
        if (label.contains('ModalScope') || label.contains('Dialog')) {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }

  /// Registers an activation callback for a focus node.
  ///
  /// When [activateCurrentNode] is called, this callback will be invoked
  /// if the node is currently focused.
  void registerCallback(FocusNode node, VoidCallback callback) {
    _activationCallbacks[node] = callback;
  }

  /// Unregisters an activation callback.
  void unregisterCallback(FocusNode node) {
    _activationCallbacks.remove(node);
  }

  /// Handles gamepad actions for focus traversal.
  void _onGamepadAction(GamepadAction action) {
    debugPrint('[FocusTraversalService] Gamepad action: $action');

    // When suppressActions is true, only allow cancel/back actions
    // This is used by the gamepad test page to prevent navigation
    if (suppressActions) {
      switch (action) {
        case GamepadAction.cancel:
          _handleCancel();
          return;
        case GamepadAction.home:
          _handleHomeShortcut();
          return;
        default:
          // All other actions are suppressed
          debugPrint('[FocusTraversalService] Action suppressed (suppressActions=true)');
          return;
      }
    }

    switch (action) {
      case GamepadAction.navigateUp:
        moveFocus(TraversalDirection.up);
      case GamepadAction.navigateDown:
        moveFocus(TraversalDirection.down);
      case GamepadAction.navigateLeft:
        moveFocus(TraversalDirection.left);
      case GamepadAction.navigateRight:
        moveFocus(TraversalDirection.right);
      case GamepadAction.confirm:
        activateCurrentNode();
      case GamepadAction.cancel:
        _handleCancel();
      case GamepadAction.home:
        // Handle gamepad Back/Select button for home navigation
        _handleHomeShortcut();
        return;
      default:
        // Other actions not handled
        break;
    }
  }

  /// Handles keyboard events for focus traversal fallback.
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    // When focus is inside a dialog, let the dialog's KeyboardListener handle arrow keys
    if (_isFocusInsideDialog()) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowRight:
          return false;
      }
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        moveFocus(TraversalDirection.up);
        return true;
      case LogicalKeyboardKey.arrowDown:
        moveFocus(TraversalDirection.down);
        return true;
      case LogicalKeyboardKey.arrowLeft:
        moveFocus(TraversalDirection.left);
        return true;
      case LogicalKeyboardKey.arrowRight:
        moveFocus(TraversalDirection.right);
        return true;
      case LogicalKeyboardKey.enter:
        activateCurrentNode();
        return true;
      case LogicalKeyboardKey.escape:
        // When focus is inside a dialog, don't consume the event - let the dialog handle it
        if (_isFocusInsideDialog()) {
          return false;
        }
        _handleCancel();
        return true;
      case LogicalKeyboardKey.space:
        // X button / Context action (stub for future)
        debugPrint('[FocusTraversalService] Space key pressed (context action stub)');
        return true;
      case LogicalKeyboardKey.keyF:
        // Y button / Toggle favorite (stub for future)
        debugPrint('[FocusTraversalService] F key pressed (favorite stub)');
        return true;
      case LogicalKeyboardKey.keyH:
        // H key / Home shortcut
        _handleHomeShortcut();
        return true;
      default:
        return false;
    }
  }

  /// Handles home shortcut (H key or gamepad Back button).
  void _handleHomeShortcut() {
    debugPrint('[FocusTraversalService] Home shortcut triggered - navigating home');
    // Navigate to home route
    final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
    if (context != null && context.mounted) {
      SoundService.instance.playPageTransition();
      GoRouter.of(context).go('/');
    }
  }

  /// Handles cancel/back action.
  void _handleCancel() {
    // If focus is inside a dialog, let the dialog handle its own close logic
    if (_isFocusInsideDialog()) {
      return;
    }

    // Otherwise try router back navigation (GoRouter pop)
    final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
    if (context != null && context.mounted) {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        SoundService.instance.playFocusBack();
        router.pop();
        return;
      }
    }

    // No navigation possible (e.g., on root route)
    debugPrint('[FocusTraversalService] No route to navigate back');
  }

  /// Checks whether a focus node is an interactive element that should
  /// receive focus and display visual feedback.
  ///
  /// Returns false for Flutter internal nodes (Scrollable, ModalScope, etc.)
  /// and generic container scope nodes that don't have their own focus styling.
  bool _isInteractiveFocusNode(FocusNode node) {
    final label = node.debugLabel ?? '';

    // Skip Flutter internal focus nodes without visual feedback
    if (label.contains('Scrollable') ||
        label.contains('ModalScope') ||
        label.contains('NavigatorScope')) {
      return false;
    }

    // Skip generic Focus Scope nodes that are not our registered scopes
    // (these are container nodes, not interactive elements)
    if (node is FocusScopeNode &&
        node != _topBarFocusNode &&
        node != _contentFocusNode &&
        node != _bottomNavFocusNode) {
      return false;
    }

    return true;
  }

  /// Checks whether a node is a descendant of the given scope.
  bool _isDescendantOfScope(FocusNode? node, FocusScopeNode? scope) {
    if (node == null || scope == null) return false;
    // Walk up the focus tree to check ancestry
    var current = node.parent;
    while (current != null) {
      if (current == scope) return true;
      current = current.parent;
    }
    return false;
  }

  /// Checks if the current focus node is on a non-interactive scope node
  /// (e.g., _ModalScopeState Focus Scope) that shouldn't receive focus actions.
  ///
  /// Returns true if the focus is stuck on a scope node that belongs to
  /// Flutter's internal navigation machinery rather than user widgets.
  bool _isOnNonInteractiveScope(FocusNode? node) {
    if (node == null) return false;
    final label = node.debugLabel ?? '';
    // Modal scope nodes, focus scope nodes that aren't our registered nodes
    return label.contains('ModalScope') ||
           (label.contains('Focus Scope') &&
            node != _topBarFocusNode &&
            node != _contentFocusNode &&
            node != _bottomNavFocusNode);
  }

  /// Recovers focus when stuck on a non-interactive scope node.
  ///
  /// Tries to focus the most recently focused interactive node, or falls back
  /// to the first available interactive descendant of the appropriate scope.
  void _recoverFocusFromScope() {
    debugPrint('[FocusTraversalService] Recovering focus from scope node');

    // Try the most recent history entry that's still valid
    for (final node in _focusHistory) {
      if (node.hasFocus && _isInteractiveFocusNode(node)) {
        // Already on a valid node
        return;
      }
    }

    // Find a valid interactive node from history
    for (final node in _focusHistory) {
      if (_isInteractiveFocusNode(node)) {
        try {
          final context = node.context;
          if (context != null && context.mounted) {
            node.requestFocus();
            debugPrint(
              '[FocusTraversalService] Recovered focus to: '
              '${node.debugLabel ?? "unnamed"}',
            );
            return;
          }
        } catch (_) {
          // Node may be disposed
          continue;
        }
      }
    }

    // Fall back to first interactive descendant of content scope, then top bar scope
    if (_contentFocusNode != null) {
      final target = _findFirstInteractiveDescendant(_contentFocusNode!);
      if (target != null) {
        target.requestFocus();
        debugPrint(
          '[FocusTraversalService] Recovered focus to first content descendant: '
          '${target.debugLabel ?? "unnamed"}',
        );
        return;
      }
    }
    if (_topBarFocusNode != null) {
      final target = _findFirstInteractiveDescendant(_topBarFocusNode!);
      if (target != null) {
        target.requestFocus();
        debugPrint(
          '[FocusTraversalService] Recovered focus to first top bar descendant: '
          '${target.debugLabel ?? "unnamed"}',
        );
        return;
      }
    }

    // Fall back to first interactive descendant of bottom nav scope
    if (_bottomNavFocusNode != null) {
      final target = _findFirstInteractiveDescendant(_bottomNavFocusNode!);
      if (target != null) {
        target.requestFocus();
        debugPrint(
          '[FocusTraversalService] Recovered focus to first bottom nav descendant: '
          '${target.debugLabel ?? "unnamed"}',
        );
        return;
      }
    }
  }

  /// Moves focus to the next row from the current row.
  /// If there is no next row, wraps to the bottom nav.
  void _focusNextRow(String currentRowId) {
    debugPrint(
      '[FocusTraversalService] _focusNextRow from "$currentRowId"',
    );
    final rowIds = _rowGroups.keys.toList();
    final currentIndex = rowIds.indexOf(currentRowId);
    debugPrint(
      '[FocusTraversalService]   rowIds=$rowIds, currentIndex=$currentIndex',
    );
    if (currentIndex == -1 || currentIndex >= rowIds.length - 1) {
      debugPrint('[FocusTraversalService]   -> No next row, wrapping to bottom nav');
      wrapToBottomNav();
      return;
    }

    final nextRowId = rowIds[currentIndex + 1];
    final nextRowNodes = _rowGroups[nextRowId];
    debugPrint(
      '[FocusTraversalService]   -> Next row: "$nextRowId" with ${nextRowNodes?.length ?? 0} nodes',
    );
    if (nextRowNodes != null && nextRowNodes.isNotEmpty) {
      final target = nextRowNodes.first;
      target.requestFocus();
      debugPrint(
        '[FocusTraversalService]   -> Focused: ${target.debugLabel ?? "unnamed"}',
      );
      SoundService.instance.playFocusMove();
    }
  }

  /// Moves focus to the previous row from the current row.
  /// If there is no previous row, wraps to the top bar.
  void _focusPreviousRow(String currentRowId) {
    debugPrint(
      '[FocusTraversalService] _focusPreviousRow from "$currentRowId"',
    );
    final rowIds = _rowGroups.keys.toList();
    final currentIndex = rowIds.indexOf(currentRowId);
    debugPrint(
      '[FocusTraversalService]   rowIds=$rowIds, currentIndex=$currentIndex',
    );
    if (currentIndex <= 0) {
      debugPrint('[FocusTraversalService]   -> No previous row, wrapping to top bar');
      wrapToTopBar();
      return;
    }

    final previousRowId = rowIds[currentIndex - 1];
    final previousRowNodes = _rowGroups[previousRowId];
    debugPrint(
      '[FocusTraversalService]   -> Previous row: "$previousRowId" with ${previousRowNodes?.length ?? 0} nodes',
    );
    if (previousRowNodes != null && previousRowNodes.isNotEmpty) {
      final target = previousRowNodes.last;
      target.requestFocus();
      debugPrint(
        '[FocusTraversalService]   -> Focused: ${target.debugLabel ?? "unnamed"}',
      );
      SoundService.instance.playFocusMove();
    }
  }

  /// Moves focus in the specified direction.
  ///
  /// Uses Flutter's built-in focus traversal when possible, with custom
  /// logic for wrapping between top bar and content area, and for
  /// row/grid navigation.
  void moveFocus(TraversalDirection direction) {
    debugPrint('[FocusTraversalService] Moving focus: $direction');

    final currentNode = currentFocusNode;
    debugPrint(
      '[FocusTraversalService]   currentNode=${currentNode?.debugLabel ?? "null"}',
    );

    // If focus is stuck on a non-interactive scope, recover it first
    if (_isOnNonInteractiveScope(currentNode)) {
      debugPrint(
        '[FocusTraversalService]   currentNode is on non-interactive scope, recovering...',
      );
      _recoverFocusFromScope();
      return;
    }

    if (currentNode == null) {
      // No current focus - focus first available node
      _focusFirstAvailableNode();
      return;
    }

    // Try row navigation first if current node is in a row
    for (final entry in _rowGroups.entries) {
      final nodes = entry.value;
      final index = nodes.indexOf(currentNode);
      if (index != -1) {
        if (direction == TraversalDirection.left && index > 0) {
          nodes[index - 1].requestFocus();
          SoundService.instance.playFocusMove();
          return;
        } else if (direction == TraversalDirection.right && index < nodes.length - 1) {
          nodes[index + 1].requestFocus();
          SoundService.instance.playFocusMove();
          return;
        } else if (direction == TraversalDirection.up) {
          // Move to previous node in row, or to previous row if at start
          if (index > 0) {
            nodes[index - 1].requestFocus();
            SoundService.instance.playFocusMove();
            return;
          }
          _focusPreviousRow(entry.key);
          return;
        } else if (direction == TraversalDirection.down) {
          // Move to next node in row, or to next row if at end
          debugPrint(
            '[FocusTraversalService]   Row down from "${entry.key}" index=$index',
          );
          if (index < nodes.length - 1) {
            nodes[index + 1].requestFocus();
            SoundService.instance.playFocusMove();
            return;
          }
          _focusNextRow(entry.key);
          return;
        }
      }
    }

    // Try grid navigation if current node is in a grid
    for (final entry in _gridGroups.entries) {
      final grid = entry.value;
      for (int row = 0; row < grid.length; row++) {
        final col = grid[row].indexOf(currentNode);
        if (col != -1) {
          final moved = _moveFocusInGrid(grid, row, col, direction);
          if (moved) {
            return;
          }
          // If grid didn't handle the move and we're going up, wrap to top bar
          if (direction == TraversalDirection.up) {
            wrapToTopBar();
            return;
          }
        }
      }
    }

    // Try using Flutter's focus traversal for general navigation
    final moved = currentNode.focusInDirection(direction);
    if (moved) {
      final newNode = currentFocusNode;
      debugPrint(
        '[FocusTraversalService] Focus moved to: '
        '${newNode?.debugLabel ?? "unnamed"}',
      );

      // If focus landed on a non-interactive node, recover to a valid one
      if (newNode != null && !_isInteractiveFocusNode(newNode)) {
        debugPrint(
          '[FocusTraversalService] Focus landed on non-interactive node, '
          'recovering...',
        );
        _recoverFocusFromScope();
        return;
      }

      SoundService.instance.playFocusMove();
      return;
    }

    // Handle wrapping between top bar and content scopes
    // When focusInDirection fails and we're at a scope boundary
    if (direction == TraversalDirection.down &&
        _isDescendantOfScope(currentNode, _topBarFocusNode)) {
      wrapToContent();
      return;
    }

    if (direction == TraversalDirection.up &&
        _isDescendantOfScope(currentNode, _contentFocusNode)) {
      wrapToTopBar();
      return;
    }

    if (direction == TraversalDirection.down &&
        _isDescendantOfScope(currentNode, _contentFocusNode)) {
      wrapToBottomNav();
      return;
    }

    if (direction == TraversalDirection.up &&
        _isDescendantOfScope(currentNode, _bottomNavFocusNode)) {
      wrapToContent();
      return;
    }
  }

  /// Moves focus within a grid. Returns true if focus was moved.
  bool _moveFocusInGrid(
    List<List<FocusNode>> grid,
    int currentRow,
    int currentCol,
    TraversalDirection direction,
  ) {
    int newRow = currentRow;
    int newCol = currentCol;

    switch (direction) {
      case TraversalDirection.up:
        newRow = currentRow - 1;
      case TraversalDirection.down:
        newRow = currentRow + 1;
      case TraversalDirection.left:
        newCol = currentCol - 1;
      case TraversalDirection.right:
        newCol = currentCol + 1;
    }

    // Check bounds
    if (newRow >= 0 &&
        newRow < grid.length &&
        newCol >= 0 &&
        newCol < grid[newRow].length) {
      grid[newRow][newCol].requestFocus();
      SoundService.instance.playFocusMove();
      return true;
    }
    return false;
  }

  /// Moves focus within a row by delta.
  void moveFocusInRow(String rowId, int delta) {
    final nodes = _rowGroups[rowId];
    if (nodes == null || nodes.isEmpty) return;

    final currentNode = currentFocusNode;
    if (currentNode == null) return;

    final index = nodes.indexOf(currentNode);
    if (index == -1) return;

    final newIndex = (index + delta).clamp(0, nodes.length - 1);
    if (newIndex != index) {
      nodes[newIndex].requestFocus();
      SoundService.instance.playFocusMove();
    }
  }

  /// Moves focus within a grid by delta.
  void moveFocusInGrid(String gridId, int dx, int dy) {
    final grid = _gridGroups[gridId];
    if (grid == null || grid.isEmpty) return;

    final currentNode = currentFocusNode;
    if (currentNode == null) return;

    // Find current position
    for (int row = 0; row < grid.length; row++) {
      final col = grid[row].indexOf(currentNode);
      if (col != -1) {
        _moveFocusInGrid(grid, row, col, _directionFromDeltas(dx, dy));
        return;
      }
    }
  }

  TraversalDirection _directionFromDeltas(int dx, int dy) {
    if (dx > 0) return TraversalDirection.right;
    if (dx < 0) return TraversalDirection.left;
    if (dy > 0) return TraversalDirection.down;
    return TraversalDirection.up;
  }

  /// Wraps focus to the top bar.
  void wrapToTopBar() {
    debugPrint('[FocusTraversalService] Wrapping to top bar');
    if (_topBarFocusNode == null) return;

    // Find the most recently focused interactive descendant of the top bar scope
    FocusNode? targetNode;
    for (final node in _focusHistory) {
      if (_isDescendantOfScope(node, _topBarFocusNode) &&
          _isInteractiveFocusNode(node)) {
        // Check if node is still valid (not disposed)
        try {
          final context = node.context;
          if (context != null && context.mounted) {
            targetNode = node;
            break;
          }
        } catch (_) {
          // Node may be disposed, continue searching
          continue;
        }
      }
    }

    // Fall back to first interactive descendant of top bar scope
    targetNode ??= _findFirstInteractiveDescendant(_topBarFocusNode!);

    if (targetNode != null && targetNode != _topBarFocusNode) {
      targetNode.requestFocus();
      SoundService.instance.playFocusMove();
    } else {
      _topBarFocusNode!.requestFocus();
    }
  }

  /// Finds the first interactive descendant of a focus scope.
  FocusNode? _findFirstInteractiveDescendant(FocusScopeNode scope) {
    final descendants = scope.traversalDescendants.toList();
    debugPrint(
      '[FocusTraversalService] Scope ${scope.debugLabel} has ${descendants.length} descendants',
    );
    for (final node in descendants) {
      final label = node.debugLabel ?? 'unnamed';
      final interactive = _isInteractiveFocusNode(node);
      debugPrint(
        '[FocusTraversalService]   - $label (interactive=$interactive)',
      );
      if (interactive) {
        debugPrint(
          '[FocusTraversalService]   -> Selected: $label',
        );
        return node;
      }
    }
    debugPrint('[FocusTraversalService]   -> No interactive descendant found');
    return null;
  }

  /// Wraps focus to the content area.
  void wrapToContent() {
    debugPrint('[FocusTraversalService] Wrapping to content');
    if (_contentFocusNode == null) return;

    // Find the most recently focused interactive descendant of the content scope
    FocusNode? targetNode;
    for (final node in _focusHistory) {
      if (_isDescendantOfScope(node, _contentFocusNode) &&
          _isInteractiveFocusNode(node)) {
        // Check if node is still valid (not disposed)
        try {
          final context = node.context;
          if (context != null && context.mounted) {
            targetNode = node;
            break;
          }
        } catch (_) {
          // Node may be disposed, continue searching
          continue;
        }
      }
    }

    // Fall back to first interactive descendant of content scope
    targetNode ??= _findFirstInteractiveDescendant(_contentFocusNode!);

    if (targetNode != null && targetNode != _contentFocusNode) {
      targetNode.requestFocus();
      SoundService.instance.playFocusMove();
    } else {
      _contentFocusNode!.requestFocus();
    }
  }

  /// Wraps focus to the bottom nav.
  void wrapToBottomNav() {
    debugPrint('[FocusTraversalService] Wrapping to bottom nav');
    if (_bottomNavFocusNode == null) return;

    // Find the most recently focused interactive descendant of the bottom nav scope
    FocusNode? targetNode;
    for (final node in _focusHistory) {
      if (_isDescendantOfScope(node, _bottomNavFocusNode) &&
          _isInteractiveFocusNode(node)) {
        // Check if node is still valid (not disposed)
        try {
          final context = node.context;
          if (context != null && context.mounted) {
            targetNode = node;
            break;
          }
        } catch (_) {
          // Node may be disposed, continue searching
          continue;
        }
      }
    }

    // Fall back to first interactive descendant of bottom nav scope
    targetNode ??= _findFirstInteractiveDescendant(_bottomNavFocusNode!);

    if (targetNode != null && targetNode != _bottomNavFocusNode) {
      targetNode.requestFocus();
      SoundService.instance.playFocusMove();
    } else {
      _bottomNavFocusNode!.requestFocus();
    }
  }

  /// Activates the currently focused node.
  ///
  /// Uses [Actions.invoke] to trigger [ActivateAction] on the focused
  /// widget's context, or calls a registered callback if available.
  ///
  /// If the current focus is on a non-interactive scope node (e.g., a
  /// modal scope), recovers focus to a registered node first.
  void activateCurrentNode() {
    final currentNode = currentFocusNode;

    // If focus is stuck on a non-interactive scope, recover it first
    if (_isOnNonInteractiveScope(currentNode)) {
      debugPrint(
        '[FocusTraversalService] Focus stuck on scope node, recovering...',
      );
      _recoverFocusFromScope();
      return;
    }

    if (currentNode == null) {
      debugPrint('[FocusTraversalService] No node to activate');
      return;
    }

    debugPrint(
      '[FocusTraversalService] Activating node: '
      '${currentNode.debugLabel ?? "unnamed"}',
    );

    // Check for registered callback first
    final callback = _activationCallbacks[currentNode];
    if (callback != null) {
      callback();
      return;
    }

    // Try to find the context and invoke ActivateAction
    final context = currentNode.context;
    if (context != null && context.mounted) {
      try {
        final activated = Actions.invoke(context, const ActivateIntent()) != null;
        if (activated) {
          debugPrint('[FocusTraversalService] ActivateAction invoked successfully');
          return;
        }
      } catch (e) {
        // Actions.invoke throws when no Actions widget maps ActivateIntent
        // in the context (e.g., focus landed on a modal scope barrier).
        // This is expected — recover focus and try again.
        debugPrint(
          '[FocusTraversalService] ActivateIntent not handled for '
          '${currentNode.debugLabel ?? "unnamed"}: $e',
        );
      }
    }

    // Activation failed - log warning per contract (no consumeKeyboardToken fallback)
    debugPrint(
      '[FocusTraversalService] WARNING: Could not activate node '
      '${currentNode.debugLabel ?? "unnamed"} - no Actions handler or registered callback',
    );
  }

  /// Focuses the first available interactive node.
  void _focusFirstAvailableNode() {
    // Try content scope first, then top bar scope
    if (_contentFocusNode != null) {
      final target = _findFirstInteractiveDescendant(_contentFocusNode!);
      if (target != null) {
        target.requestFocus();
        return;
      }
    }
    if (_topBarFocusNode != null) {
      final target = _findFirstInteractiveDescendant(_topBarFocusNode!);
      if (target != null) {
        target.requestFocus();
        return;
      }
    }

    if (_bottomNavFocusNode != null) {
      final target = _findFirstInteractiveDescendant(_bottomNavFocusNode!);
      if (target != null) {
        target.requestFocus();
        return;
      }
    }
  }
}

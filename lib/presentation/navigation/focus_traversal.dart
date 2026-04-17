import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/data/services/gamepad_service.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// Service for managing focus traversal with gamepad and keyboard input.
///
/// This service manages a graph of [FocusNode]s for gamepad-driven navigation.
/// It provides methods to move focus in cardinal directions, handle row/grid
/// navigation, manage focus history, and trap focus in dialogs.
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

  /// The focus node for the top bar container.
  FocusNode? _topBarFocusNode;

  /// List of focus nodes in the top bar.
  final List<FocusNode> _topBarNodes = [];

  /// The focus node for the content area container.
  FocusNode? _contentFocusNode;

  /// List of focus nodes in the content area.
  final List<FocusNode> _contentNodes = [];

  /// Registered row focus groups.
  final Map<String, List<FocusNode>> _rowGroups = {};

  /// Registered grid focus groups.
  final Map<String, List<List<FocusNode>>> _gridGroups = {};

  /// Focus history stack (max 10 entries).
  final List<FocusNode> _focusHistory = [];

  /// Maximum depth of focus history stack.
  static const int _maxHistoryDepth = 10;

  /// Whether focus is currently trapped in a dialog.
  bool _isInDialogMode = false;

  /// The dialog's focus nodes when in dialog mode.
  List<FocusNode> _dialogNodes = [];

  /// The node that triggered the dialog (for restoring focus on close).
  FocusNode? _dialogTriggerNode;

  /// Optional callback invoked when cancel is pressed in dialog mode.
  VoidCallback? _dialogCancelCallback;

  /// Callbacks registered for focus node activation.
  final Map<FocusNode, VoidCallback> _activationCallbacks = {};

  /// Stream controller for current focus node changes.
  final _currentFocusController = StreamController<FocusNode?>.broadcast();

  /// Gets the stream of current focus node changes.
  Stream<FocusNode?> get currentFocusStream => _currentFocusController.stream;

  /// Gets the currently focused node.
  FocusNode? get currentFocusNode =>
      WidgetsBinding.instance.focusManager.primaryFocus;

  /// Returns true if focus is currently trapped in a dialog.
  bool isInDialogMode() => _isInDialogMode;

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

  /// Registers the top bar focus node.
  void registerTopBarNode(FocusNode node) {
    if (!_topBarNodes.contains(node)) {
      _topBarNodes.add(node);
      node.addListener(() => _onNodeFocusChanged(node));
      debugPrint(
        '[FocusTraversalService] Registered top bar node: '
        '${node.debugLabel ?? "unnamed"}',
      );
    }
  }

  /// Unregisters a top bar focus node.
  void unregisterTopBarNode(FocusNode node) {
    _topBarNodes.remove(node);
    node.removeListener(() => _onNodeFocusChanged(node));
  }

  /// Registers a content area focus node.
  void registerContentNode(FocusNode node) {
    if (!_contentNodes.contains(node)) {
      _contentNodes.add(node);
      node.addListener(() => _onNodeFocusChanged(node));
      debugPrint(
        '[FocusTraversalService] Registered content node: '
        '${node.debugLabel ?? "unnamed"}',
      );
    }
  }

  /// Unregisters a content area focus node.
  void unregisterContentNode(FocusNode node) {
    _contentNodes.remove(node);
    node.removeListener(() => _onNodeFocusChanged(node));
  }

  /// Registers a row of focus nodes for horizontal navigation.
  void registerRow(String rowId, List<FocusNode> nodes) {
    _rowGroups[rowId] = nodes;
    for (final node in nodes) {
      node.addListener(() => _onNodeFocusChanged(node));
    }
    debugPrint('[FocusTraversalService] Registered row "$rowId" with ${nodes.length} nodes');
  }

  /// Registers a 2D grid of focus nodes.
  void registerGrid(String gridId, List<List<FocusNode>> nodes) {
    _gridGroups[gridId] = nodes;
    for (final row in nodes) {
      for (final node in row) {
        node.addListener(() => _onNodeFocusChanged(node));
      }
    }
    debugPrint(
      '[FocusTraversalService] Registered grid "$gridId" with '
      '${nodes.length} rows',
    );
  }

  /// Unregisters a row.
  void unregisterRow(String rowId) {
    _rowGroups.remove(rowId);
  }

  /// Unregisters a grid.
  void unregisterGrid(String gridId) {
    _gridGroups.remove(gridId);
  }

  /// Clears all row and grid registrations.
  void clearAllRegistrations() {
    _rowGroups.clear();
    _gridGroups.clear();
    _contentNodes.clear();
    // Note: _topBarNodes is NOT cleared as the top bar persists across navigation
    debugPrint('[FocusTraversalService] Cleared content registrations (rows, grids, content nodes)');
  }

  /// Sets the top bar container focus node.
  void setTopBarContainer(FocusNode node) {
    _topBarFocusNode = node;
  }

  /// Sets the content area container focus node.
  void setContentContainer(FocusNode node) {
    _contentFocusNode = node;
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
    if (_isInDialogMode && _dialogNodes.contains(node)) {
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

  /// Enters dialog focus mode.
  ///
  /// When in dialog mode:
  /// - Focus is trapped within dialog elements
  /// - Arrow keys navigate within dialog only
  /// - Escape closes the dialog
  void enterDialogMode(
    String dialogId,
    List<FocusNode> dialogNodes,
    FocusNode? triggerNode, {
    VoidCallback? onCancel,
  }) {
    _isInDialogMode = true;
    _dialogNodes = dialogNodes;
    _dialogTriggerNode = triggerNode;
    _dialogCancelCallback = onCancel;
    debugPrint('[FocusTraversalService] Entered dialog mode: $dialogId');
  }

  /// Exits dialog focus mode.
  ///
  /// Restores focus to the element that opened the dialog.
  void exitDialogMode() {
    _isInDialogMode = false;
    _dialogNodes = [];
    _dialogCancelCallback = null;

    // Restore focus to trigger node
    if (_dialogTriggerNode != null) {
      _dialogTriggerNode!.requestFocus();
    }

    _dialogTriggerNode = null;
    debugPrint('[FocusTraversalService] Exited dialog mode');
  }

  /// Updates the dialog focus nodes while in dialog mode.
  ///
  /// Call this when the set of focusable elements inside a dialog changes
  /// (e.g., search results update).
  void updateDialogNodes(List<FocusNode> dialogNodes) {
    if (_isInDialogMode) {
      _dialogNodes = dialogNodes;
      debugPrint(
        '[FocusTraversalService] Updated dialog nodes: ${dialogNodes.length}',
      );
    }
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

    // In dialog mode, let the dialog's KeyboardListener handle arrow keys
    if (_isInDialogMode) {
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
        // In dialog mode, don't consume the event - let the dialog handle it
        if (_isInDialogMode) {
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
    // If in dialog mode, close the dialog
    if (_isInDialogMode) {
      SoundService.instance.playFocusBack();
      if (_dialogCancelCallback != null) {
        _dialogCancelCallback!();
      } else {
        exitDialogMode();
      }
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
            !_topBarNodes.contains(node) &&
            !_contentNodes.contains(node) &&
            !_dialogNodes.contains(node) &&
            node != _topBarFocusNode &&
            node != _contentFocusNode);
  }

  /// Recovers focus when stuck on a non-interactive scope node.
  ///
  /// Tries to focus the most recently focused registered node, or falls back
  /// to the first available registered node.
  void _recoverFocusFromScope() {
    debugPrint('[FocusTraversalService] Recovering focus from scope node');

    // Try the most recent history entry that's still valid
    for (final node in _focusHistory) {
      if (node.hasFocus &&
          !_isOnNonInteractiveScope(node) &&
          (_topBarNodes.contains(node) ||
           _contentNodes.contains(node) ||
           _dialogNodes.contains(node))) {
        // Already on a valid node
        return;
      }
    }

    // Find a valid node from history
    for (final node in _focusHistory) {
      if (!_isOnNonInteractiveScope(node)) {
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

    // Fall back to first available node
    _focusFirstAvailableNode();
  }

  /// Moves focus in the specified direction.
  ///
  /// Uses Flutter's built-in focus traversal when possible, with custom
  /// logic for wrapping between top bar and content area, and for
  /// row/grid navigation.
  void moveFocus(TraversalDirection direction) {
    debugPrint('[FocusTraversalService] Moving focus: $direction');

    final currentNode = currentFocusNode;

    // If focus is stuck on a non-interactive scope, recover it first
    if (_isOnNonInteractiveScope(currentNode)) {
      _recoverFocusFromScope();
      return;
    }

    if (currentNode == null) {
      // No current focus - focus first available node
      _focusFirstAvailableNode();
      return;
    }

    // If in dialog mode, only navigate within dialog
    if (_isInDialogMode) {
      _moveFocusInDialog(direction);
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
          // Pressing up from any row node wraps back to the top bar
          wrapToTopBar();
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

    // Try using Flutter's focus traversal
    final moved = currentNode.focusInDirection(direction);
    if (moved) {
      final newNode = currentFocusNode;
      debugPrint(
        '[FocusTraversalService] Focus moved to: '
        '${newNode?.debugLabel ?? "unnamed"}',
      );
      SoundService.instance.playFocusMove();
      return;
    }

    // Handle wrapping between top bar and content
    if (_topBarNodes.contains(currentNode) && direction == TraversalDirection.down) {
      wrapToContent();
      return;
    }

    if (_contentNodes.contains(currentNode) && direction == TraversalDirection.up) {
      wrapToTopBar();
      return;
    }
  }

  /// Moves focus within a dialog.
  void _moveFocusInDialog(TraversalDirection direction) {
    final currentNode = currentFocusNode;
    if (currentNode == null) return;

    final index = _dialogNodes.indexOf(currentNode);
    if (index == -1) return;

    switch (direction) {
      case TraversalDirection.left:
        if (index > 0) {
          _dialogNodes[index - 1].requestFocus();
          SoundService.instance.playFocusMove();
        }
      case TraversalDirection.right:
        if (index < _dialogNodes.length - 1) {
          _dialogNodes[index + 1].requestFocus();
          SoundService.instance.playFocusMove();
        }
      case TraversalDirection.up:
      case TraversalDirection.down:
        // In simple dialogs, up/down can also navigate
        if (direction == TraversalDirection.up && index > 0) {
          _dialogNodes[index - 1].requestFocus();
          SoundService.instance.playFocusMove();
        } else if (direction == TraversalDirection.down && index < _dialogNodes.length - 1) {
          _dialogNodes[index + 1].requestFocus();
          SoundService.instance.playFocusMove();
        }
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
    if (_topBarNodes.isNotEmpty) {
      // Focus the first node in the top bar
      _topBarNodes.first.requestFocus();
      SoundService.instance.playFocusMove();
    } else if (_topBarFocusNode != null) {
      _topBarFocusNode!.requestFocus();
    }
  }

  /// Wraps focus to the content area.
  void wrapToContent() {
    debugPrint('[FocusTraversalService] Wrapping to content');
    if (_contentNodes.isNotEmpty) {
      // Focus the first node in the content area
      _contentNodes.first.requestFocus();
      SoundService.instance.playFocusMove();
    } else if (_contentFocusNode != null) {
      _contentFocusNode!.requestFocus();
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

  /// Focuses the first available node.
  void _focusFirstAvailableNode() {
    if (_topBarNodes.isNotEmpty) {
      _topBarNodes.first.requestFocus();
    } else if (_contentNodes.isNotEmpty) {
      _contentNodes.first.requestFocus();
    }
  }
}

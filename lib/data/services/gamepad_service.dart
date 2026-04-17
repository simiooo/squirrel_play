import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';

/// Enum representing semantic gamepad actions.
///
/// These actions are mapped from normalized gamepad events and represent
/// the high-level interactions in the application.
enum GamepadAction {
  /// Navigate up (D-pad up or left stick up).
  navigateUp,

  /// Navigate down (D-pad down or left stick down).
  navigateDown,

  /// Navigate left (D-pad left or left stick left).
  navigateLeft,

  /// Navigate right (D-pad right or left stick right).
  navigateRight,

  /// Confirm/select action (A button / Cross).
  confirm,

  /// Cancel/back action (B button / Circle).
  cancel,

  /// Context action (X button / Square).
  contextAction,

  /// Toggle favorite (Y button / Triangle).
  toggleFavorite,

  /// Open menu (Start button).
  menu,

  /// Go to home (Back/Select button).
  home,
}

/// Dead zone threshold for analog sticks.
///
/// Values below this threshold are ignored to prevent stick drift.
const double _analogDeadzone = 0.5;

/// Service for handling gamepad/controller input.
///
/// Uses the `gamepads` package's normalized events stream which provides
/// platform-independent button/axis identifiers. This ensures correct
/// mapping regardless of platform-specific key numbering.
class GamepadService {
  /// Singleton instance.
  static final GamepadService _instance = GamepadService._internal();

  /// Gets the singleton instance.
  static GamepadService get instance => _instance;

  /// Internal constructor.
  GamepadService._internal();

  /// Stream controller for gamepad actions.
  final _actionController = StreamController<GamepadAction>.broadcast();

  /// Subscription to gamepad events.
  StreamSubscription<NormalizedGamepadEvent>? _gamepadSubscription;

  /// Whether the service is initialized.
  bool _isInitialized = false;

  /// Gets the stream of gamepad actions.
  Stream<GamepadAction> get actions => _actionController.stream;

  /// Whether a gamepad is currently connected.
  bool _isConnected = false;

  /// Gets whether a gamepad is connected.
  bool get isConnected => _isConnected;

  /// Stream controller for connection state changes.
  final _connectionController = StreamController<bool>.broadcast();

  /// Gets the stream of connection state changes.
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Timer for periodic gamepad polling (disconnect detection).
  Timer? _pollingTimer;

  /// Name of the currently connected gamepad.
  String? _gamepadName;

  /// Gets the name of the currently connected gamepad.
  String? get gamepadName => _gamepadName;

  /// Tracks the last active direction for each axis to debounce analog input.
  ///
  /// Only emits a direction change once when the stick crosses the deadzone,
  /// then suppresses repeated events until the stick returns to center.
  final Map<GamepadAxis, GamepadAction?> _lastAxisDirection = {};

  /// Tracks currently-pressed buttons to suppress repeated press events.
  ///
  /// Normalized button events have value 1.0 for press and 0.0 for release.
  final Set<GamepadButton> _pressedButtons = {};

  /// Initializes the gamepad service.
  ///
  /// Sets up listeners for normalized gamepad events and connection state.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[GamepadService] Already initialized');
      return;
    }

    debugPrint('[GamepadService] Initializing...');

    try {
      // Listen to normalized gamepad events (platform-independent)
      _gamepadSubscription = Gamepads.normalizedEvents.listen(
        _onGamepadEvent,
        onError: (error) {
          debugPrint('[GamepadService] Error receiving event: $error');
        },
      );

      // Check for existing gamepads
      final gamepads = await Gamepads.list();
      _isConnected = gamepads.isNotEmpty;
      debugPrint(
        '[GamepadService] Found ${gamepads.length} connected gamepads',
      );

      for (final gamepad in gamepads) {
        debugPrint(
          '[GamepadService] - ${gamepad.name} (ID: ${gamepad.id})',
        );
      }

      // Start polling timer for disconnect detection
      _startPollingTimer();

      _isInitialized = true;
      debugPrint('[GamepadService] Initialized successfully');
    } catch (e) {
      debugPrint('[GamepadService] Failed to initialize: $e');
      // Service still works even if gamepad support fails
      _isInitialized = true;
    }
  }

  /// Starts the polling timer for disconnect detection.
  ///
  /// Polls every 2 seconds to check if gamepads are still connected.
  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final gamepads = await Gamepads.list();
        final hasGamepad = gamepads.isNotEmpty;

        if (hasGamepad && !_isConnected) {
          // Gamepad connected
          _isConnected = true;
          _gamepadName = gamepads.first.name;
          _connectionController.add(true);
          debugPrint(
            '[GamepadService] Polling detected connection: $_gamepadName',
          );
        } else if (!hasGamepad && _isConnected) {
          // Gamepad disconnected
          _isConnected = false;
          _gamepadName = null;
          _connectionController.add(false);
          debugPrint('[GamepadService] Polling detected disconnection');
        }
      } catch (e) {
        debugPrint('[GamepadService] Error during polling: $e');
      }
    });
    debugPrint('[GamepadService] Started polling timer (2s interval)');
  }

  /// Disposes the service and cleans up resources.
  void dispose() {
    debugPrint('[GamepadService] Disposing...');
    _pollingTimer?.cancel();
    _gamepadSubscription?.cancel();
    _actionController.close();
    _connectionController.close();
    _isInitialized = false;
  }

  /// Handles incoming normalized gamepad events.
  void _onGamepadEvent(NormalizedGamepadEvent event) {
    // Handle button events
    if (event.button != null) {
      final action = _mapButtonToAction(event.button!, event.value);
      if (action != null) {
        debugPrint(
          '[GamepadService] Button: ${event.button} = ${event.value.toStringAsFixed(2)} → $action',
        );
        _actionController.add(action);
      }

      // Update connection state
      if (!_isConnected) {
        _isConnected = true;
        _connectionController.add(true);
        debugPrint('[GamepadService] Gamepad connected');
        // Try to get gamepad name
        Gamepads.list().then((gamepads) {
          if (gamepads.isNotEmpty) {
            _gamepadName = gamepads.first.name;
          }
        });
      }
      return;
    }

    // Handle axis (analog stick) events
    if (event.axis != null) {
      final action = _mapAxisToAction(event.axis!, event.value);
      if (action != null) {
        debugPrint(
          '[GamepadService] Axis: ${event.axis} = ${event.value.toStringAsFixed(2)} → $action',
        );
        _actionController.add(action);
      }

      // Update connection state
      if (!_isConnected) {
        _isConnected = true;
        _connectionController.add(true);
        debugPrint('[GamepadService] Gamepad connected');
        Gamepads.list().then((gamepads) {
          if (gamepads.isNotEmpty) {
            _gamepadName = gamepads.first.name;
          }
        });
      }
    }
  }

  /// Maps a normalized gamepad button to a semantic action.
  ///
  /// Only fires on initial button press (not hold or release).
  /// Uses _pressedButtons to track state and suppress repeats.
  GamepadAction? _mapButtonToAction(GamepadButton button, double value) {
    final isPressed = value >= 0.5;

    // Suppress repeated press events (already held down)
    if (isPressed && _pressedButtons.contains(button)) {
      return null;
    }

    // Track state transitions
    if (isPressed) {
      _pressedButtons.add(button);
    } else {
      _pressedButtons.remove(button);
      return null; // Don't emit on release
    }

    switch (button) {
      case GamepadButton.a:
        return GamepadAction.confirm;
      case GamepadButton.b:
        return GamepadAction.cancel;
      case GamepadButton.x:
        return GamepadAction.contextAction;
      case GamepadButton.y:
        return GamepadAction.toggleFavorite;
      case GamepadButton.dpadUp:
        return GamepadAction.navigateUp;
      case GamepadButton.dpadDown:
        return GamepadAction.navigateDown;
      case GamepadButton.dpadLeft:
        return GamepadAction.navigateLeft;
      case GamepadButton.dpadRight:
        return GamepadAction.navigateRight;
      case GamepadButton.start:
        return GamepadAction.menu;
      case GamepadButton.back:
        return GamepadAction.home;
      case GamepadButton.home:
        return GamepadAction.home;
      case GamepadButton.leftBumper:
      case GamepadButton.rightBumper:
      case GamepadButton.leftTrigger:
      case GamepadButton.rightTrigger:
      case GamepadButton.leftStick:
      case GamepadButton.rightStick:
      case GamepadButton.touchpad:
        // Not currently mapped
        return null;
    }
  }

  /// Maps a normalized gamepad axis to a semantic navigation action.
  ///
  /// Uses debouncing: only emits a direction change once when the stick
  /// crosses the deadzone threshold, then suppresses repeated events until
  /// the stick returns near center (below half the deadzone).
  GamepadAction? _mapAxisToAction(GamepadAxis axis, double value) {
    // Determine current direction based on deadzone
    GamepadAction? newDirection;
    if (value.abs() >= _analogDeadzone) {
      switch (axis) {
        case GamepadAxis.leftStickY:
          newDirection =
              value > 0 ? GamepadAction.navigateUp : GamepadAction.navigateDown;
        case GamepadAxis.leftStickX:
          newDirection =
              value > 0 ? GamepadAction.navigateRight : GamepadAction.navigateLeft;
        case GamepadAxis.rightStickY:
          newDirection =
              value > 0 ? GamepadAction.navigateUp : GamepadAction.navigateDown;
        case GamepadAxis.rightStickX:
          newDirection =
              value > 0 ? GamepadAction.navigateRight : GamepadAction.navigateLeft;
        case GamepadAxis.leftTrigger:
        case GamepadAxis.rightTrigger:
          // Triggers not mapped to navigation
          return null;
      }
    } else {
      // Stick returned near center — direction is null
      newDirection = null;
    }

    final lastDirection = _lastAxisDirection[axis];

    // Only emit if direction actually changed
    if (newDirection != lastDirection) {
      _lastAxisDirection[axis] = newDirection;
      return newDirection;
    }

    // Same direction as before — suppress (debounce)
    return null;
  }
}
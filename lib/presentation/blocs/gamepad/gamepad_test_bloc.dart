import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepads/gamepads.dart';

import 'package:squirrel_play/data/services/gamepad_service.dart';

// =============================================================================
// Events
// =============================================================================

/// Base event for gamepad test bloc.
abstract class GamepadTestEvent extends Equatable {
  const GamepadTestEvent();

  @override
  List<Object?> get props => [];
}

/// Event dispatched when gamepad test starts (auto-subscribed in constructor).
class GamepadTestStarted extends GamepadTestEvent {
  const GamepadTestStarted();
}

/// Event dispatched when a button state changes.
class GamepadButtonPressed extends GamepadTestEvent {
  const GamepadButtonPressed({
    required this.button,
    required this.pressed,
  });

  final GamepadButton button;
  final bool pressed;

  @override
  List<Object?> get props => [button, pressed];
}

/// Event dispatched when an axis value changes.
class GamepadAxisMoved extends GamepadTestEvent {
  const GamepadAxisMoved({
    required this.axis,
    required this.value,
  });

  final GamepadAxis axis;
  final double value;

  @override
  List<Object?> get props => [axis, value];
}

/// Event dispatched when gamepad is connected.
class GamepadConnectedEvent extends GamepadTestEvent {
  const GamepadConnectedEvent({this.gamepadName});

  final String? gamepadName;

  @override
  List<Object?> get props => [gamepadName];
}

/// Event dispatched when gamepad is disconnected.
class GamepadDisconnectedEvent extends GamepadTestEvent {
  const GamepadDisconnectedEvent();
}

// =============================================================================
// Input Log Entry
// =============================================================================

/// Represents a single input log entry.
class InputLogEntry extends Equatable {
  const InputLogEntry({
    required this.timestamp,
    required this.type,
    this.description,
    this.params,
  });

  final DateTime timestamp;
  final String type;
  final String? description;
  final Map<String, dynamic>? params;

  @override
  List<Object?> get props => [timestamp, type, description, params];
}

// =============================================================================
// State
// =============================================================================

/// State for gamepad test bloc.
class GamepadTestState extends Equatable {
  const GamepadTestState({
    this.isConnected = false,
    this.gamepadName,
    this.buttonStates = const {},
    this.axisValues = const {},
    this.inputLog = const [],
    this.lastUpdated,
  });

  final bool isConnected;
  final String? gamepadName;
  final Map<GamepadButton, bool> buttonStates;
  final Map<GamepadAxis, double> axisValues;
  final List<InputLogEntry> inputLog;
  final DateTime? lastUpdated;

  /// Computed getter for left stick position.
  Offset get leftStickPosition => Offset(
    axisValues[GamepadAxis.leftStickX] ?? 0.0,
    axisValues[GamepadAxis.leftStickY] ?? 0.0,
  );

  /// Computed getter for right stick position.
  Offset get rightStickPosition => Offset(
    axisValues[GamepadAxis.rightStickX] ?? 0.0,
    axisValues[GamepadAxis.rightStickY] ?? 0.0,
  );

  GamepadTestState copyWith({
    bool? isConnected,
    String? gamepadName,
    Map<GamepadButton, bool>? buttonStates,
    Map<GamepadAxis, double>? axisValues,
    List<InputLogEntry>? inputLog,
    DateTime? lastUpdated,
    bool clearGamepadName = false,
  }) {
    return GamepadTestState(
      isConnected: isConnected ?? this.isConnected,
      gamepadName: clearGamepadName ? null : (gamepadName ?? this.gamepadName),
      buttonStates: buttonStates ?? this.buttonStates,
      axisValues: axisValues ?? this.axisValues,
      inputLog: inputLog ?? this.inputLog,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    isConnected,
    gamepadName,
    buttonStates,
    axisValues,
    inputLog,
    lastUpdated,
  ];
}

// =============================================================================
// BLoC
// =============================================================================

/// BLoC for managing gamepad test state.
///
/// Subscribes to gamepad events and connection state to provide real-time
/// button states, axis values, and input logging for the gamepad test page.
class GamepadTestBloc extends Bloc<GamepadTestEvent, GamepadTestState> {
  GamepadTestBloc({
    GamepadService? gamepadService,
  })  : _gamepadService = gamepadService ?? GamepadService.instance,
        super(const GamepadTestState()) {
    // Register event handlers
    on<GamepadTestStarted>(_onStarted);
    on<GamepadButtonPressed>(_onButtonPressed);
    on<GamepadAxisMoved>(_onAxisMoved);
    on<GamepadConnectedEvent>(_onConnected);
    on<GamepadDisconnectedEvent>(_onDisconnected);

    // Auto-subscribe on creation
    add(const GamepadTestStarted());
  }

  final GamepadService _gamepadService;
  StreamSubscription<NormalizedGamepadEvent>? _normalizedEventSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  void _onStarted(GamepadTestStarted event, Emitter<GamepadTestState> emit) {
    debugPrint('[GamepadTestBloc] Starting...');

    // Subscribe to normalized gamepad events
    _normalizedEventSubscription = Gamepads.normalizedEvents.listen(
      _onNormalizedEvent,
      onError: (error) {
        debugPrint('[GamepadTestBloc] Error in normalized events: $error');
      },
    );

    // Subscribe to connection state changes
    _connectionSubscription = _gamepadService.connectionStream.listen(
      (isConnected) {
        if (isConnected) {
          add(GamepadConnectedEvent(gamepadName: _gamepadService.gamepadName));
        } else {
          add(const GamepadDisconnectedEvent());
        }
      },
      onError: (error) {
        debugPrint('[GamepadTestBloc] Error in connection stream: $error');
      },
    );

    // Check initial connection state
    if (_gamepadService.isConnected) {
      add(GamepadConnectedEvent(gamepadName: _gamepadService.gamepadName));
    }

    debugPrint('[GamepadTestBloc] Started');
  }

  void _onNormalizedEvent(NormalizedGamepadEvent event) {
    debugPrint('[GamepadTestBloc] Normalized event: $event');

    // Handle button events
    if (event.button != null) {
      final isPressed = event.value > 0.5;
      add(GamepadButtonPressed(button: event.button!, pressed: isPressed));
    }

    // Handle axis events
    if (event.axis != null) {
      add(GamepadAxisMoved(axis: event.axis!, value: event.value));
    }
  }

  void _onButtonPressed(
    GamepadButtonPressed event,
    Emitter<GamepadTestState> emit,
  ) {
    final updatedButtonStates = Map<GamepadButton, bool>.from(state.buttonStates)
      ..[event.button] = event.pressed;

    // Add to input log
    final logEntry = InputLogEntry(
      timestamp: DateTime.now(),
      type: 'BUTTON',
      description: '${event.button.name} ${event.pressed ? 'pressed' : 'released'}',
      params: {
        'buttonName': event.button.name,
        'pressed': event.pressed,
      },
    );
    final updatedLog = _addToLog(state.inputLog, logEntry);

    emit(state.copyWith(
      buttonStates: updatedButtonStates,
      inputLog: updatedLog,
    ));
  }

  void _onAxisMoved(
    GamepadAxisMoved event,
    Emitter<GamepadTestState> emit,
  ) {
    final updatedAxisValues = Map<GamepadAxis, double>.from(state.axisValues)
      ..[event.axis] = event.value;

    // Only log significant axis movements (avoid spam)
    final previousValue = state.axisValues[event.axis] ?? 0.0;
    final delta = (event.value - previousValue).abs();

    List<InputLogEntry> updatedLog = state.inputLog;
    if (delta > 0.2) {
      final logEntry = InputLogEntry(
        timestamp: DateTime.now(),
        type: 'AXIS',
        description: '${event.axis.name}: ${event.value.toStringAsFixed(2)}',
        params: {
          'axisName': event.axis.name,
          'axisValue': event.value,
        },
      );
      updatedLog = _addToLog(state.inputLog, logEntry);
    }

    emit(state.copyWith(
      axisValues: updatedAxisValues,
      inputLog: updatedLog,
    ));
  }

  void _onConnected(
    GamepadConnectedEvent event,
    Emitter<GamepadTestState> emit,
  ) {
    final logEntry = InputLogEntry(
      timestamp: DateTime.now(),
      type: 'CONNECT',
      description: 'Gamepad connected: ${event.gamepadName ?? 'Unknown'}',
      params: {
        'gamepadName': event.gamepadName,
      },
    );
    final updatedLog = _addToLog(state.inputLog, logEntry);

    emit(state.copyWith(
      isConnected: true,
      gamepadName: event.gamepadName,
      inputLog: updatedLog,
    ));
  }

  void _onDisconnected(
    GamepadDisconnectedEvent event,
    Emitter<GamepadTestState> emit,
  ) {
    final logEntry = InputLogEntry(
      timestamp: DateTime.now(),
      type: 'DISCONNECT',
      description: 'Gamepad disconnected',
      params: const {},
    );
    final updatedLog = _addToLog(state.inputLog, logEntry);

    emit(state.copyWith(
      isConnected: false,
      clearGamepadName: true,
      inputLog: updatedLog,
    ));
  }

  List<InputLogEntry> _addToLog(
    List<InputLogEntry> currentLog,
    InputLogEntry newEntry,
  ) {
    // Keep only last 50 entries
    final newLog = List<InputLogEntry>.from(currentLog)..add(newEntry);
    if (newLog.length > 50) {
      return newLog.sublist(newLog.length - 50);
    }
    return newLog;
  }

  @override
  Future<void> close() {
    debugPrint('[GamepadTestBloc] Closing - cancelling subscriptions...');
    _normalizedEventSubscription?.cancel();
    _connectionSubscription?.cancel();
    debugPrint('[GamepadTestBloc] Subscriptions cancelled');
    return super.close();
  }
}

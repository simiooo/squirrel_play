import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'package:squirrel_play/data/services/gamepad_service.dart';

/// Base state for gamepad cubit.
abstract class GamepadState extends Equatable {
  const GamepadState();

  @override
  List<Object?> get props => [];
}

/// State when a gamepad is connected.
class GamepadConnected extends GamepadState {
  const GamepadConnected({this.gamepadName});

  /// Optional name of the connected gamepad.
  final String? gamepadName;

  @override
  List<Object?> get props => [gamepadName];
}

/// State when no gamepad is connected.
class GamepadDisconnected extends GamepadState {
  const GamepadDisconnected();
}

/// Cubit for managing gamepad connection state.
///
/// Provides BLoC-level access to gamepad connection status for Sprint 2 UI components.
/// Initializes with [GamepadDisconnected] and updates when [GamepadService] detects
/// connection changes.
class GamepadCubit extends Cubit<GamepadState> {
  /// Creates a gamepad cubit.
  ///
  /// Optionally accepts a [GamepadService] instance. If not provided, the
  /// singleton instance will be used.
  GamepadCubit({GamepadService? gamepadService})
      : _gamepadService = gamepadService ?? GamepadService.instance,
        super(const GamepadDisconnected()) {
    _initialize();
  }

  final GamepadService _gamepadService;
  StreamSubscription<bool>? _connectionSubscription;

  void _initialize() {
    // Check initial connection state
    if (_gamepadService.isConnected) {
      emit(const GamepadConnected());
    }

    // Subscribe to connection state changes
    _connectionSubscription = _gamepadService.connectionStream.listen(
      (isConnected) {
        debugPrint('[GamepadCubit] Connection state changed: $isConnected');
        if (isConnected) {
          emit(const GamepadConnected());
        } else {
          emit(const GamepadDisconnected());
        }
      },
      onError: (error) {
        debugPrint('[GamepadCubit] Error in connection stream: $error');
      },
    );

    debugPrint('[GamepadCubit] Initialized');
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    debugPrint('[GamepadCubit] Closed');
    return super.close();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';

/// Service for launching game executables.
///
/// Implements the [GameLauncher] interface using Process.start() for
/// Windows executable launching. Uses fire-and-forget pattern where
/// the launch status returns to idle after 2 seconds.
class GameLauncherService implements GameLauncher {
  final _statusController = StreamController<LaunchStatus>.broadcast();
  LaunchStatus _currentStatus = LaunchStatus.idle;
  Timer? _resetTimer;

  @override
  Stream<LaunchStatus> get launchStatusStream => _statusController.stream;

  /// Gets the current launch status.
  LaunchStatus get currentStatus => _currentStatus;

  /// Launches a game executable using Process.start().
  ///
  /// [game] - The game to launch
  ///
  /// Returns a [LaunchResult] indicating success or failure.
  /// Status transitions: idle → launching → idle (after 2s delay)
  /// On error: idle → launching → error → idle (after 2s delay)
  @override
  Future<LaunchResult> launchGame(Game game) async {
    // Cancel any existing reset timer
    _resetTimer?.cancel();

    // Set status to launching
    _currentStatus = LaunchStatus.launching;
    _statusController.add(LaunchStatus.launching);

    try {
      // Verify executable exists
      final executableFile = File(game.executablePath);
      if (!await executableFile.exists()) {
        final error = 'Executable not found: ${game.executablePath}';
        _setErrorStatus(error);
        return LaunchResult(success: false, errorMessage: error);
      }

      // Get the working directory (parent folder of executable)
      final workingDirectory = executableFile.parent.path;

      // Launch the process (fire and forget)
      await Process.start(
        game.executablePath,
        [], // No arguments
        workingDirectory: workingDirectory,
        mode: ProcessStartMode.detached,
      );

      // Process started successfully
      // We don't wait for it to complete - fire and forget

      // Schedule status reset to idle after 2 seconds
      _scheduleResetToIdle();

      return const LaunchResult(success: true);
    } on ProcessException catch (e) {
      final error = 'Failed to launch process: ${e.message}';
      _setErrorStatus(error);
      return LaunchResult(success: false, errorMessage: error);
    } on FileSystemException catch (e) {
      final error = 'File system error: ${e.message}';
      _setErrorStatus(error);
      return LaunchResult(success: false, errorMessage: error);
    } catch (e) {
      final error = 'Unexpected error launching game: $e';
      _setErrorStatus(error);
      return LaunchResult(success: false, errorMessage: error);
    }
  }

  /// Sets error status and schedules reset to idle.
  void _setErrorStatus(String errorMessage) {
    _currentStatus = LaunchStatus.error;
    _statusController.add(LaunchStatus.error);

    // Schedule reset to idle after 2 seconds
    _scheduleResetToIdle();
  }

  /// Schedules status reset to idle after 2 seconds.
  void _scheduleResetToIdle() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      _currentStatus = LaunchStatus.idle;
      _statusController.add(LaunchStatus.idle);
    });
  }

  /// Disposes resources.
  void dispose() {
    _resetTimer?.cancel();
    _statusController.close();
  }
}

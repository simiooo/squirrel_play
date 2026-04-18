import 'package:squirrel_play/domain/entities/game.dart';

/// Abstract service interface for launching game executables.
///
/// Defines the contract for launching games and monitoring launch status.
abstract class GameLauncher {
  /// Launches the game executable (fire-and-forget).
  ///
  /// Returns immediately after process starts. Use [launchStatusStream]
  /// to monitor the launch progress.
  Future<LaunchResult> launchGame(Game game);

  /// Forcefully terminates a running game process.
  Future<void> stopGame(String gameId);

  /// Synchronous check for whether a game is currently tracked.
  bool isGameRunning(String gameId);

  /// Stream of running games updates.
  ///
  /// Emits a map of game IDs to their running process info.
  Stream<Map<String, RunningGameInfo>> get runningGamesStream;

  /// Stream of launch status updates.
  ///
  /// Emits status changes: idle → launching → idle (after 2s delay)
  /// On error: idle → launching → error → idle (after 2s delay)
  Stream<LaunchStatus> get launchStatusStream;
}

/// Result of a game launch attempt.
class LaunchResult {
  /// Whether the launch was successful.
  final bool success;

  /// Error message if launch failed.
  final String? errorMessage;

  /// Creates a LaunchResult.
  const LaunchResult({
    required this.success,
    this.errorMessage,
  });
}

/// Launch status for fire-and-forget launching.
///
/// - idle: No launch in progress
/// - launching: Launch process is starting
/// - error: Launch failed
///
/// Note: After successful launch, status returns to idle after 2 seconds.
enum LaunchStatus { idle, launching, error }

/// Information about a currently running game process.
class RunningGameInfo {
  /// Unique identifier of the game.
  final String gameId;

  /// Title of the game.
  final String title;

  /// When the game process started.
  final DateTime startTime;

  /// Process ID, if available.
  final int? pid;

  /// Creates a RunningGameInfo.
  const RunningGameInfo({
    required this.gameId,
    required this.title,
    required this.startTime,
    this.pid,
  });
}

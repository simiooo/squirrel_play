import 'dart:async';
import 'dart:io';

import 'package:squirrel_play/core/services/platform_info.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';

/// Service for launching game executables.
///
/// Implements the [GameLauncher] interface using Process.start() for
/// executable launching. Tracks running processes in memory and provides
/// lifecycle management (launch, monitor, stop).
///
/// For Steam games, launches via the `steam://rungameid/<appId>` protocol
/// instead of starting the executable directly, ensuring Steam runtime,
/// overlay, and cloud save integration.
class GameLauncherService implements GameLauncher {
  final PlatformInfo _platformInfo;
  final _statusController = StreamController<LaunchStatus>.broadcast();
  late final StreamController<Map<String, RunningGameInfo>> _runningGamesController;
  final Map<String, Process> _runningProcesses = {};
  final Map<String, RunningGameInfo> _runningGames = {};

  LaunchStatus _currentStatus = LaunchStatus.idle;
  Timer? _resetTimer;

  /// Creates a GameLauncherService.
  GameLauncherService({required PlatformInfo platformInfo})
      : _platformInfo = platformInfo {
    _runningGamesController =
        StreamController<Map<String, RunningGameInfo>>.broadcast(
      onListen: () {
        if (!_runningGamesController.isClosed) {
          _runningGamesController.add(Map.unmodifiable(_runningGames));
        }
      },
    );
  }

  @override
  Stream<LaunchStatus> get launchStatusStream => _statusController.stream;

  @override
  Stream<Map<String, RunningGameInfo>> get runningGamesStream =>
      _runningGamesController.stream;

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
      // Parse launch arguments
      final args = _parseLaunchArguments(game.launchArguments);

      late final Process process;

      if (game.platform == 'steam' && game.platformGameId != null) {
        // Launch via Steam protocol for proper Steam integration
        process = await _launchSteamGame(
          game.platformGameId!,
          game.launchArguments,
        );
      } else {
        // Verify executable exists
        final executableFile = File(game.executablePath);
        if (!await executableFile.exists()) {
          final error = 'Executable not found: ${game.executablePath}';
          _setErrorStatus(error);
          return LaunchResult(success: false, errorMessage: error);
        }

        // Get the working directory (parent folder of executable)
        final workingDirectory = executableFile.parent.path;

        // Launch the process (non-detached so we can track it)
        process = await Process.start(
          game.executablePath,
          args,
          workingDirectory: workingDirectory,
        );
      }

      // Track the running process
      _runningProcesses[game.id] = process;
      final info = RunningGameInfo(
        gameId: game.id,
        title: game.title,
        startTime: DateTime.now(),
        pid: process.pid,
      );
      _runningGames[game.id] = info;
      if (!_runningGamesController.isClosed) {
        _runningGamesController.add(Map.unmodifiable(_runningGames));
      }

      // Listen for process exit to clean up
      process.exitCode.then((_) {
        _runningProcesses.remove(game.id);
        _runningGames.remove(game.id);
        if (!_runningGamesController.isClosed) {
          _runningGamesController.add(Map.unmodifiable(_runningGames));
        }
      });

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

  /// Launches a Steam game via the `steam://rungameid/<appId>` protocol.
  ///
  /// Supports launch options via the Steam URL format:
  /// `steam://rungameid/<appId>//<launchOptions>`
  ///
  /// Uses platform-specific commands:
  /// - Windows: `cmd /c start steam://rungameid/<appId>`
  /// - Linux: `steam steam://rungameid/<appId>`
  /// - macOS: `open steam://rungameid/<appId>`
  Future<Process> _launchSteamGame(String appId, String? launchArgs) async {
    final args = _parseLaunchArguments(launchArgs);
    final steamUrl = _buildSteamUrl(appId, args);

    if (_platformInfo.isWindows) {
      // Use 'start' command to open the Steam URL protocol
      return Process.start('cmd', ['/c', 'start', '', steamUrl]);
    } else if (_platformInfo.isLinux) {
      return Process.start('steam', [steamUrl]);
    } else if (_platformInfo.isMacOS) {
      return Process.start('open', [steamUrl]);
    } else {
      throw UnsupportedError(
        'Steam launch not supported on this platform',
      );
    }
  }

  /// Builds the Steam URL for launching a game.
  ///
  /// Format without options: `steam://rungameid/<appId>`
  /// Format with options:   `steam://rungameid/<appId>//<options>`
  String _buildSteamUrl(String appId, List<String> launchArgs) {
    if (launchArgs.isNotEmpty) {
      return 'steam://rungameid/$appId//${launchArgs.join(' ')}';
    }
    return 'steam://rungameid/$appId';
  }

  /// Parses launch arguments string into a list of arguments.
  ///
  /// Uses simple space-delimited splitting.
  List<String> _parseLaunchArguments(String? arguments) {
    if (arguments == null || arguments.trim().isEmpty) {
      return [];
    }
    return arguments
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Stops a running game process.
  @override
  Future<void> stopGame(String gameId) async {
    final process = _runningProcesses[gameId];
    if (process != null) {
      process.kill();
      _runningProcesses.remove(gameId);
      _runningGames.remove(gameId);
      if (!_runningGamesController.isClosed) {
        _runningGamesController.add(Map.unmodifiable(_runningGames));
      }
    }
  }

  /// Checks whether a game is currently running.
  @override
  bool isGameRunning(String gameId) {
    return _runningProcesses.containsKey(gameId);
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
    _runningGamesController.close();
  }
}

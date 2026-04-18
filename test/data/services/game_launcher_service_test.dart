import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/data/services/game_launcher_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';

void main() {
  group('GameLauncherService', () {
    late GameLauncherService gameLauncherService;

    final testGame = Game(
      id: 'test-game-1',
      title: 'Test Game',
      executablePath: '/games/test_game.exe',
      addedDate: DateTime.now(),
    );

    setUp(() {
      gameLauncherService = GameLauncherService();
    });

    tearDown(() async {
      // Stop any lingering test processes
      await gameLauncherService.stopGame('test-game-1');
      await gameLauncherService.stopGame('test-game-2');
      gameLauncherService.dispose();
    });

    test('initial status is idle', () {
      expect(gameLauncherService.currentStatus, LaunchStatus.idle);
    });

    group('launchGame', () {
      test('returns failure result when executable does not exist', () async {
        final gameWithInvalidPath = Game(
          id: 'test-game-1',
          title: 'Test Game',
          executablePath: '/nonexistent/path/game.exe',
          addedDate: DateTime.now(),
        );

        final result = await gameLauncherService.launchGame(gameWithInvalidPath);

        expect(result.success, false);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('Executable not found'));
      });

      test('emits launching status when starting launch', () async {
        final statusValues = <LaunchStatus>[];
        final subscription = gameLauncherService.launchStatusStream.listen(
          statusValues.add,
        );

        // Wait a bit for initial state
        await Future.delayed(const Duration(milliseconds: 50));

        // Try to launch non-existent game (will fail but still emit launching)
        await gameLauncherService.launchGame(testGame);

        // Wait for status to update
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify launching was emitted
        expect(statusValues, contains(LaunchStatus.launching));

        await subscription.cancel();
      });

      test('emits error status when launch fails', () async {
        final statusValues = <LaunchStatus>[];
        final subscription = gameLauncherService.launchStatusStream.listen(
          statusValues.add,
        );

        // Wait a bit for initial state
        await Future.delayed(const Duration(milliseconds: 50));

        // Launch non-existent game
        await gameLauncherService.launchGame(testGame);

        // Wait for error status
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have emitted error
        expect(statusValues, contains(LaunchStatus.error));

        await subscription.cancel();
      });

      test('returns to idle after 2 seconds on error', () async {
        final statusValues = <LaunchStatus>[];
        final subscription = gameLauncherService.launchStatusStream.listen(
          statusValues.add,
        );

        // Wait a bit for initial state
        await Future.delayed(const Duration(milliseconds: 50));

        // Launch non-existent game
        await gameLauncherService.launchGame(testGame);

        // Wait for the 2-second timer to complete plus some buffer
        await Future.delayed(const Duration(seconds: 3));

        // Should have returned to idle after error
        expect(statusValues.last, LaunchStatus.idle);

        await subscription.cancel();
      }, timeout: const Timeout(Duration(seconds: 5)));

      test('launchGame passes parsed arguments to Process.start', () async {
        final game = Game(
          id: 'test-game-1',
          title: 'Test Game',
          executablePath: '/usr/bin/sleep',
          launchArguments: '0.2',
          addedDate: DateTime.now(),
        );

        final result = await gameLauncherService.launchGame(game);
        expect(result.success, isTrue);
        expect(gameLauncherService.isGameRunning('test-game-1'), isTrue);

        // Wait for process to exit naturally
        await Future.delayed(const Duration(milliseconds: 400));
        expect(gameLauncherService.isGameRunning('test-game-1'), isFalse);
      });

      test('launchGame with null launchArguments passes empty args', () async {
        final game = Game(
          id: 'test-game-1',
          title: 'Test Game',
          executablePath: '/usr/bin/true',
          addedDate: DateTime.now(),
        );

        final result = await gameLauncherService.launchGame(game);
        expect(result.success, isTrue);
      });
    });

    group('isGameRunning', () {
      test('returns false when no game is running', () {
        expect(gameLauncherService.isGameRunning('test-game-1'), isFalse);
      });

      test('returns true after successful launch', () async {
        final game = Game(
          id: 'test-game-1',
          title: 'Test Game',
          executablePath: '/usr/bin/sleep',
          launchArguments: '10',
          addedDate: DateTime.now(),
        );

        final result = await gameLauncherService.launchGame(game);
        expect(result.success, isTrue);
        expect(gameLauncherService.isGameRunning('test-game-1'), isTrue);
      });
    });

    group('stopGame', () {
      test('stopGame terminates a running process', () async {
        final game = Game(
          id: 'test-game-1',
          title: 'Test Game',
          executablePath: '/usr/bin/sleep',
          launchArguments: '10',
          addedDate: DateTime.now(),
        );

        await gameLauncherService.launchGame(game);
        expect(gameLauncherService.isGameRunning('test-game-1'), isTrue);

        await gameLauncherService.stopGame('test-game-1');
        expect(gameLauncherService.isGameRunning('test-game-1'), isFalse);
      });
    });

    group('runningGamesStream', () {
      test('emits empty map initially', () async {
        final values = <Map<String, RunningGameInfo>>[];
        final subscription = gameLauncherService.runningGamesStream.listen(
          values.add,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        expect(values, isNotEmpty);
        expect(values.first, isEmpty);

        await subscription.cancel();
      });

      test('emits game info after launch', () async {
        final values = <Map<String, RunningGameInfo>>[];
        final subscription = gameLauncherService.runningGamesStream.listen(
          values.add,
        );

        final game = Game(
          id: 'test-game-1',
          title: 'Test Game',
          executablePath: '/usr/bin/sleep',
          launchArguments: '10',
          addedDate: DateTime.now(),
        );

        await gameLauncherService.launchGame(game);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(values.last.containsKey('test-game-1'), isTrue);
        expect(values.last['test-game-1']!.title, equals('Test Game'));
        expect(values.last['test-game-1']!.pid, isNotNull);

        await subscription.cancel();
      });

      test('emits empty map after process exits naturally', () async {
        final values = <Map<String, RunningGameInfo>>[];
        final subscription = gameLauncherService.runningGamesStream.listen(
          values.add,
        );

        final game = Game(
          id: 'test-game-1',
          title: 'Test Game',
          executablePath: '/usr/bin/sleep',
          launchArguments: '0.2',
          addedDate: DateTime.now(),
        );

        await gameLauncherService.launchGame(game);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(values.last.containsKey('test-game-1'), isTrue);

        // Wait for process to exit naturally
        await Future.delayed(const Duration(milliseconds: 400));

        expect(values.last, isEmpty);

        await subscription.cancel();
      });
    });

    group('dispose', () {
      test('closes the status stream controller', () async {
        gameLauncherService.dispose();

        // Stream should be closed
        expect(
          () => gameLauncherService.launchStatusStream.first,
          throwsA(isA<StateError>()),
        );
      });

      test('closes the running games stream controller', () async {
        gameLauncherService.dispose();

        expect(
          () => gameLauncherService.runningGamesStream.first,
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

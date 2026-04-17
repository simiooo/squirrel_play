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

    tearDown(() {
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
    });
  });
}

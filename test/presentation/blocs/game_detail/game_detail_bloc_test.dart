import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/home_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';
import 'package:squirrel_play/presentation/blocs/game_detail/game_detail_bloc.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockMetadataRepository extends Mock implements MetadataRepository {}

class MockGameLauncher extends Mock implements GameLauncher {}

class MockHomeRepository extends Mock implements HomeRepository {}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
  });

  group('GameDetailBloc', () {
    late GameRepository gameRepository;
    late MetadataRepository metadataRepository;
    late GameLauncher gameLauncher;
    late HomeRepository homeRepository;
    late GameDetailBloc bloc;

    final testGame = Game(
      id: 'test-game-1',
      title: 'Test Game Title',
      executablePath: '/games/test.exe',
      addedDate: DateTime(2024, 1, 1),
      playCount: 5,
      lastPlayedDate: DateTime(2024, 6, 15),
      isFavorite: true,
    );

    setUp(() {
      gameRepository = MockGameRepository();
      metadataRepository = MockMetadataRepository();
      gameLauncher = MockGameLauncher();
      homeRepository = MockHomeRepository();

      when(() => gameLauncher.runningGamesStream)
          .thenAnswer((_) => Stream.value({}));
      when(() => gameLauncher.isGameRunning(any())).thenReturn(false);
      when(() => gameRepository.getGameById(any()))
          .thenAnswer((_) async => testGame);
      when(() => metadataRepository.getMetadataForGame(any()))
          .thenAnswer((_) async => null);
      when(() => gameRepository.incrementPlayCount(any()))
          .thenAnswer((_) async => testGame.copyWith(playCount: 6));
      when(() => gameRepository.updateLastPlayed(any(), any()))
          .thenAnswer((_) async => testGame);
      when(() => gameRepository.updateGame(any()))
          .thenAnswer((_) async => testGame);
      when(() => gameRepository.deleteGame(any()))
          .thenAnswer((_) async {});
      when(() => homeRepository.notifyGamesChanged())
          .thenAnswer((_) async {});

      bloc = GameDetailBloc(
        gameRepository: gameRepository,
        metadataRepository: metadataRepository,
        gameLauncher: gameLauncher,
        homeRepository: homeRepository,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is GameDetailLoading', () {
      expect(bloc.state, const GameDetailLoading());
    });

    group('GameDetailLoadRequested', () {
      blocTest<GameDetailBloc, GameDetailState>(
        'emits [GameDetailLoading, GameDetailLoaded] when load succeeds',
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailLoadRequested('test-game-1')),
        expect: () => [
          const GameDetailLoading(),
          isA<GameDetailLoaded>().having(
            (s) => s.game.id,
            'game id',
            'test-game-1',
          ),
        ],
        verify: (_) {
          verify(() => gameRepository.getGameById('test-game-1')).called(1);
        },
      );

      blocTest<GameDetailBloc, GameDetailState>(
        'emits [GameDetailLoading, GameDetailError] when game not found',
        setUp: () {
          when(() => gameRepository.getGameById(any()))
              .thenAnswer((_) async => null);
        },
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailLoadRequested('missing-id')),
        expect: () => [
          const GameDetailLoading(),
          const GameDetailError(type: GameDetailErrorType.gameNotFound),
        ],
      );

      blocTest<GameDetailBloc, GameDetailState>(
        'checks isGameRunning on load',
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailLoadRequested('test-game-1')),
        expect: () => [
          const GameDetailLoading(),
          isA<GameDetailLoaded>().having(
            (s) => s.isRunning,
            'isRunning',
            false,
          ),
        ],
        verify: (_) {
          verify(() => gameLauncher.isGameRunning('test-game-1')).called(1);
        },
      );
    });

    group('GameDetailLaunchRequested', () {
      blocTest<GameDetailBloc, GameDetailState>(
        'calls launchGame, incrementPlayCount, updateLastPlayed on success',
        setUp: () {
          when(() => gameLauncher.launchGame(any()))
              .thenAnswer((_) async => const LaunchResult(success: true));
        },
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: false,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailLaunchRequested()),
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.isRunning,
            'isRunning',
            true,
          ),
        ],
        verify: (_) {
          verify(() => gameLauncher.launchGame(testGame)).called(1);
          verify(() => gameRepository.incrementPlayCount('test-game-1'))
              .called(1);
          verify(() => gameRepository.updateLastPlayed(
                'test-game-1',
                any(),
              )).called(1);
        },
      );

      blocTest<GameDetailBloc, GameDetailState>(
        'emits launchError when launch throws',
        setUp: () {
          when(() => gameLauncher.launchGame(any()))
              .thenThrow(Exception('Launch failed'));
        },
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: false,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailLaunchRequested()),
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.launchError,
            'launchError',
            contains('Launch failed'),
          ),
        ],
      );

      blocTest<GameDetailBloc, GameDetailState>(
        'emits launchError when launch returns failure',
        setUp: () {
          when(() => gameLauncher.launchGame(any()))
              .thenAnswer((_) async => const LaunchResult(
                    success: false,
                    errorMessage: 'Steam not found',
                  ));
        },
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: false,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailLaunchRequested()),
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.launchError,
            'launchError',
            'Steam not found',
          ),
        ],
      );
    });

    group('GameDetailStopRequested', () {
      blocTest<GameDetailBloc, GameDetailState>(
        'calls stopGame and emits isRunning false',
        setUp: () {
          when(() => gameLauncher.stopGame(any()))
              .thenAnswer((_) async {});
        },
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: true,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailStopRequested()),
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.isRunning,
            'isRunning',
            false,
          ),
        ],
        verify: (_) {
          verify(() => gameLauncher.stopGame('test-game-1')).called(1);
        },
      );
    });

    group('GameDetailDeleteRequested', () {
      blocTest<GameDetailBloc, GameDetailState>(
        'calls deleteGame, notifies home repo, and emits GameDetailDeleted',
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: false,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(const GameDetailDeleteRequested()),
        expect: () => [
          const GameDetailDeleted(),
        ],
        verify: (_) {
          verify(() => gameRepository.deleteGame('test-game-1')).called(1);
          verify(() => homeRepository.notifyGamesChanged()).called(1);
        },
      );
    });

    group('GameDetailEditSaved', () {
      blocTest<GameDetailBloc, GameDetailState>(
        'calls updateGame, notifies home repo, and emits updated game',
        setUp: () {
          final updated = testGame.copyWith(title: 'Updated Title');
          when(() => gameRepository.updateGame(any()))
              .thenAnswer((_) async => updated);
        },
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: false,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(
          GameDetailEditSaved(testGame.copyWith(title: 'Updated Title')),
        ),
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.game.title,
            'title',
            'Updated Title',
          ),
        ],
        verify: (_) {
          verify(() => gameRepository.updateGame(any())).called(1);
          verify(() => homeRepository.notifyGamesChanged()).called(1);
        },
      );
    });

    group('GameDetailGameUpdated', () {
      blocTest<GameDetailBloc, GameDetailState>(
        'updates game in loaded state',
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: false,
        ),
        build: () => bloc,
        act: (bloc) => bloc.add(
          GameDetailGameUpdated(testGame.copyWith(title: 'New Title')),
        ),
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.game.title,
            'title',
            'New Title',
          ),
        ],
      );
    });

    group('RunningStateSubscription', () {
      blocTest<GameDetailBloc, GameDetailState>(
        'emits isRunning true when game appears in running games stream',
        setUp: () {
          when(() => gameLauncher.runningGamesStream).thenAnswer(
            (_) => Stream.value({
              'test-game-1': RunningGameInfo(
                gameId: 'test-game-1',
                title: 'Test Game Title',
                startTime: DateTime.now(),
              ),
            }),
          );
        },
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: false,
        ),
        build: () => GameDetailBloc(
          gameRepository: gameRepository,
          metadataRepository: metadataRepository,
          gameLauncher: gameLauncher,
          homeRepository: homeRepository,
        ),
        act: (bloc) async {
          // Wait for stream to emit
          await Future.delayed(const Duration(milliseconds: 50));
        },
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.isRunning,
            'isRunning',
            true,
          ),
        ],
      );

      blocTest<GameDetailBloc, GameDetailState>(
        'emits isRunning false when game is removed from running games stream',
        setUp: () {
          when(() => gameLauncher.runningGamesStream).thenAnswer(
            (_) => Stream.value({}),
          );
        },
        seed: () => GameDetailLoaded(
          game: testGame,
          isRunning: true,
        ),
        build: () => GameDetailBloc(
          gameRepository: gameRepository,
          metadataRepository: metadataRepository,
          gameLauncher: gameLauncher,
          homeRepository: homeRepository,
        ),
        act: (bloc) async {
          await Future.delayed(const Duration(milliseconds: 50));
        },
        expect: () => [
          isA<GameDetailLoaded>().having(
            (s) => s.isRunning,
            'isRunning',
            false,
          ),
        ],
      );
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/home_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';
import 'package:squirrel_play/presentation/blocs/home/home_bloc.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

class MockGameRepository extends Mock implements GameRepository {}

class MockMetadataRepository extends Mock implements MetadataRepository {}

class MockGameLauncher extends Mock implements GameLauncher {}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
  });

  group('HomeBloc', () {
    late HomeRepository homeRepository;
    late GameLauncher gameLauncher;
    late HomeBloc homeBloc;

    final testGames = [
      Game(
        id: 'game-1',
        title: 'Test Game 1',
        executablePath: '/games/game1.exe',
        addedDate: DateTime(2024, 1, 1),
        isFavorite: true,
      ),
      Game(
        id: 'game-2',
        title: 'Test Game 2',
        executablePath: '/games/game2.exe',
        addedDate: DateTime(2024, 1, 2),
      ),
      Game(
        id: 'game-3',
        title: 'Test Game 3',
        executablePath: '/games/game3.exe',
        addedDate: DateTime(2024, 1, 3),
      ),
    ];

    final testRows = [
      HomeRow(
        id: 'recently_added',
        titleKey: 'home.rows.recentlyAdded',
        games: testGames.reversed.toList(),
        type: HomeRowType.recentlyAdded,
      ),
      HomeRow(
        id: 'all_games',
        titleKey: 'home.rows.allGames',
        games: testGames,
        type: HomeRowType.allGames,
        isNavigable: true,
      ),
    ];

    late GameRepository gameRepository;
    late MetadataRepository metadataRepository;

    setUp(() {
      homeRepository = MockHomeRepository();
      gameRepository = MockGameRepository();
      metadataRepository = MockMetadataRepository();
      gameLauncher = MockGameLauncher();

      // Setup default mock behaviors
      when(() => homeRepository.getHomeRows())
          .thenAnswer((_) async => testRows);
      when(() => homeRepository.watchAllGames())
          .thenAnswer((_) => Stream.value(testGames));
      when(() => gameLauncher.launchStatusStream)
          .thenAnswer((_) => Stream.value(LaunchStatus.idle));
      when(() => gameLauncher.isGameRunning(any())).thenReturn(false);
      when(() => gameLauncher.runningGamesStream)
          .thenAnswer((_) => Stream.value({}));
      when(() => metadataRepository.getMetadataForGame(any()))
          .thenAnswer((_) async => null);
      when(() => gameRepository.incrementPlayCount(any()))
          .thenAnswer((_) async => testGames.first);
      when(() => gameRepository.updateLastPlayed(any(), any()))
          .thenAnswer((_) async => testGames.first);

      homeBloc = HomeBloc(
        homeRepository: homeRepository,
        gameRepository: gameRepository,
        metadataRepository: metadataRepository,
        gameLauncher: gameLauncher,
      );
    });

    tearDown(() {
      homeBloc.close();
    });

    test('initial state is HomeInitial', () {
      expect(homeBloc.state, const HomeInitial());
    });

    group('HomeLoadRequested', () {
      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeLoaded] when load succeeds',
        build: () => homeBloc,
        act: (bloc) => bloc.add(const HomeLoadRequested()),
        expect: () => [
          const HomeLoading(),
          isA<HomeLoaded>().having(
            (s) => s.rows.length,
            'rows length',
            2,
          ),
        ],
        verify: (_) {
          verify(() => homeRepository.getHomeRows()).called(1);
        },
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeEmpty] when no games exist',
        setUp: () {
          when(() => homeRepository.getHomeRows())
              .thenAnswer((_) async => []);
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(const HomeLoadRequested()),
        expect: () => [
          const HomeLoading(),
          const HomeEmpty(hasScanDirectories: false),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'emits [HomeLoading, HomeError] when load fails',
        setUp: () {
          when(() => homeRepository.getHomeRows())
              .thenThrow(Exception('Database error'));
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(const HomeLoadRequested()),
        expect: () => [
          const HomeLoading(),
          isA<HomeError>().having(
            (s) => s.message,
            'error message',
            contains('Database error'),
          ),
        ],
      );

      blocTest<HomeBloc, HomeState>(
        'sets initial focus to first game in first row',
        build: () => homeBloc,
        act: (bloc) => bloc.add(const HomeLoadRequested()),
        expect: () => [
          const HomeLoading(),
          isA<HomeLoaded>().having(
            (s) => s.focusedGame?.id,
            'focused game id',
            'game-3', // Most recently added
          ).having(
            (s) => s.focusedRowIndex,
            'focused row index',
            0,
          ).having(
            (s) => s.focusedCardIndex,
            'focused card index',
            0,
          ),
        ],
      );
    });

    group('HomeGameFocused', () {
      blocTest<HomeBloc, HomeState>(
        'updates focused game when in HomeLoaded state',
        seed: () => HomeLoaded(
          rows: testRows,
          focusedGame: testGames.first,
          focusedRowIndex: 0,
          focusedCardIndex: 0,
        ),
        build: () => homeBloc,
        act: (bloc) => bloc.add(HomeGameFocused(
          game: testGames[1],
          rowIndex: 1,
          cardIndex: 1,
        )),
        expect: () => [
          isA<HomeLoaded>().having(
            (s) => s.focusedGame?.id,
            'focused game id',
            'game-2',
          ).having(
            (s) => s.focusedRowIndex,
            'focused row index',
            1,
          ).having(
            (s) => s.focusedCardIndex,
            'focused card index',
            1,
          ),
        ],
      );
    });

    group('HomeGameLaunched', () {
      blocTest<HomeBloc, HomeState>(
        'sets isLaunching to true when game is launched',
        seed: () => HomeLoaded(
          rows: testRows,
          focusedGame: testGames.first,
          isLaunching: false,
        ),
        setUp: () {
          when(() => gameLauncher.launchGame(any()))
              .thenAnswer((_) async => const LaunchResult(success: true));
        },
        build: () => homeBloc,
        act: (bloc) => bloc.add(HomeGameLaunched(game: testGames.first)),
        expect: () => [
          isA<HomeLoaded>().having(
            (s) => s.isLaunching,
            'is launching',
            true,
          ),
        ],
        verify: (_) {
          verify(() => gameLauncher.launchGame(testGames.first)).called(1);
        },
      );
    });

    group('HomeGamesChanged', () {
      blocTest<HomeBloc, HomeState>(
        'reloads home rows when games change after initial load',
        seed: () => const HomeLoaded(rows: []),
        build: () => homeBloc,
        act: (bloc) => bloc.add(HomeGamesChanged(testGames)),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          const HomeLoading(),
          isA<HomeLoaded>(),
        ],
        verify: (_) {
          verify(() => homeRepository.getHomeRows()).called(1);
        },
      );
    });

    group('HomeLaunchStatusChanged', () {
      blocTest<HomeBloc, HomeState>(
        'updates isLaunching based on status',
        seed: () => HomeLoaded(
          rows: testRows,
          focusedGame: testGames.first,
          isLaunching: true,
        ),
        build: () => homeBloc,
        act: (bloc) => bloc.add(const HomeLaunchStatusChanged(LaunchStatus.idle)),
        expect: () => [
          isA<HomeLoaded>().having(
            (s) => s.isLaunching,
            'is launching',
            false,
          ),
        ],
      );
    });

    group('HomeRetryRequested', () {
      blocTest<HomeBloc, HomeState>(
        'reloads data when retry is requested',
        seed: () => HomeError(
          message: 'Failed to load',
          onRetry: () {},
        ),
        build: () => homeBloc,
        act: (bloc) => bloc.add(const HomeRetryRequested()),
        expect: () => [
          const HomeLoading(),
          isA<HomeLoaded>(),
        ],
      );
    });

    group('Stream Subscriptions', () {
      test('subscribes to watchAllGames stream on creation', () {
        verify(() => homeRepository.watchAllGames()).called(1);
      });

      test('subscribes to launchStatusStream on creation', () {
        verify(() => gameLauncher.launchStatusStream).called(1);
      });
    });
  });
}

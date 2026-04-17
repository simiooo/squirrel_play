import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:squirrel_play/data/repositories/metadata_repository_impl.dart';
import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_bloc.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_event.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_state.dart';

class MockMetadataRepository extends Mock implements MetadataRepository {}

class MockGameRepository extends Mock implements GameRepository {}

class MockMetadataRepositoryImpl extends Mock implements MetadataRepositoryImpl {}

void main() {
  group('MetadataBloc', () {
    late MetadataBloc bloc;
    late MockMetadataRepository mockMetadataRepository;
    late MockGameRepository mockGameRepository;

    setUp(() {
      mockMetadataRepository = MockMetadataRepository();
      mockGameRepository = MockGameRepository();
      
      bloc = MetadataBloc(
        metadataRepository: mockMetadataRepository,
        gameRepository: mockGameRepository,
      );
    });

    tearDown(() {
      bloc.close();
    });

    group('FetchMetadata', () {
      final gameId = 'game-123';
      final gameTitle = 'Test Game';
      final executablePath = '/games/test.exe';
      
      final metadata = GameMetadata(
        gameId: gameId,
        externalId: '12345',
        description: 'Test description',
        genres: const ['Action'],
        screenshots: const [],
        lastFetched: DateTime.now(),
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoading, MetadataLoaded] when fetch succeeds',
        build: () {
          when(() => mockMetadataRepository.getMetadataForGame(any()))
              .thenAnswer((_) async => null);
          when(() => mockMetadataRepository.fetchAndCacheMetadata(any(), any()))
              .thenAnswer((_) async => metadata);
          return bloc;
        },
        act: (bloc) => bloc.add(FetchMetadata(
          gameId: gameId,
          gameTitle: gameTitle,
          executablePath: executablePath,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataLoaded>(),
        ],
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoaded] immediately when cached metadata exists',
        build: () {
          when(() => mockMetadataRepository.getMetadataForGame(gameId))
              .thenAnswer((_) async => metadata);
          return bloc;
        },
        act: (bloc) => bloc.add(FetchMetadata(
          gameId: gameId,
          gameTitle: gameTitle,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataLoaded>(),
        ],
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoading, MetadataMatchRequired] when match confidence is low',
        build: () {
          when(() => mockMetadataRepository.getMetadataForGame(gameId))
              .thenAnswer((_) async => null);
          when(() => mockMetadataRepository.fetchAndCacheMetadata(gameId, gameTitle))
              .thenThrow(MetadataMatchRequiredException(
                gameId: gameId,
                gameTitle: gameTitle,
                alternatives: [
                  const MetadataAlternative(
                    gameId: '1',
                    gameName: 'Alternative',
                    confidence: 0.5,
                  ),
                ],
              ));
          return bloc;
        },
        act: (bloc) => bloc.add(FetchMetadata(
          gameId: gameId,
          gameTitle: gameTitle,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataMatchRequired>(),
        ],
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoading, MetadataError] when fetch fails',
        build: () {
          when(() => mockMetadataRepository.getMetadataForGame(gameId))
              .thenAnswer((_) async => null);
          when(() => mockMetadataRepository.fetchAndCacheMetadata(gameId, gameTitle))
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(FetchMetadata(
          gameId: gameId,
          gameTitle: gameTitle,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataError>(),
        ],
      );
    });

    group('BatchFetchMetadata', () {
      final gameId1 = 'game-1';
      final gameId2 = 'game-2';
      
      final game1 = Game(
        id: gameId1,
        title: 'Game 1',
        executablePath: '/games/game1.exe',
        addedDate: DateTime.now(),
      );

      final metadata1 = GameMetadata(
        gameId: gameId1,
        externalId: '1',
        genres: const [],
        screenshots: const [],
        lastFetched: DateTime.now(),
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataBatchProgress] for empty game list',
        build: () {
          return bloc;
        },
        act: (bloc) => bloc.add(const BatchFetchMetadata(gameIds: [])),
        expect: () => [
          isA<MetadataBatchProgress>().having(
            (s) => s.isComplete,
            'isComplete',
            true,
          ),
        ],
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits progress updates during batch fetch',
        build: () {
          when(() => mockGameRepository.getGameById(any()))
              .thenAnswer((_) async => game1);
          when(() => mockMetadataRepository.batchProgressStream)
              .thenAnswer((_) => Stream.fromIterable([
                const BatchMetadataProgress(
                  total: 2,
                  completed: 0,
                  failed: 0,
                  currentGame: 'Game 1',
                  isComplete: false,
                ),
                const BatchMetadataProgress(
                  total: 2,
                  completed: 1,
                  failed: 0,
                  currentGame: 'Game 2',
                  isComplete: false,
                ),
                const BatchMetadataProgress(
                  total: 2,
                  completed: 2,
                  failed: 0,
                  isComplete: true,
                ),
              ]));
          when(() => mockMetadataRepository.batchFetchMetadata(any()))
              .thenAnswer((_) async => [metadata1]);
          return bloc;
        },
        act: (bloc) => bloc.add(BatchFetchMetadata(gameIds: [gameId1, gameId2])),
        skip: 2, // Skip first two progress updates due to timing
        expect: () => [
          isA<MetadataBatchProgress>().having((s) => s.isComplete, 'isComplete', true),
        ],
      );
    });

    group('ManualSearch', () {
      const query = 'test game';
      
      final alternatives = [
        const MetadataAlternative(
          gameId: '1',
          gameName: 'Test Game 1',
          confidence: 0.9,
          coverImageUrl: 'https://example.com/1.jpg',
          releaseYear: '2023',
        ),
        const MetadataAlternative(
          gameId: '2',
          gameName: 'Test Game 2',
          confidence: 0.8,
        ),
      ];

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoading, MetadataSearchResults] when search succeeds',
        build: () {
          when(() => mockMetadataRepository.manualSearch(query))
              .thenAnswer((_) async => alternatives);
          return bloc;
        },
        act: (bloc) => bloc.add(const ManualSearch(query: query)),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataSearchResults>().having(
            (s) => s.results.length,
            'results length',
            2,
          ),
        ],
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoading, MetadataError] when search fails',
        build: () {
          when(() => mockMetadataRepository.manualSearch(query))
              .thenThrow(Exception('Search failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(const ManualSearch(query: query)),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataError>(),
        ],
      );
    });

    group('SelectMatch', () {
      final gameId = 'game-123';
      final externalId = '456';
      
      final metadata = GameMetadata(
        gameId: gameId,
        externalId: externalId,
        description: 'Selected game',
        genres: const ['RPG'],
        screenshots: const [],
        lastFetched: DateTime.now(),
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoading, MetadataLoaded] when match selection succeeds',
        build: () {
          when(() => mockMetadataRepository.updateMetadata(gameId, externalId))
              .thenAnswer((_) async => metadata);
          return bloc;
        },
        act: (bloc) => bloc.add(SelectMatch(
          gameId: gameId,
          externalId: externalId,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataLoaded>(),
        ],
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataLoading, MetadataError] when match selection fails',
        build: () {
          when(() => mockMetadataRepository.updateMetadata(gameId, externalId))
              .thenThrow(Exception('Update failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(SelectMatch(
          gameId: gameId,
          externalId: externalId,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataError>(),
        ],
      );
    });

    group('RetryFetch', () {
      final gameId = 'game-123';
      final gameTitle = 'Test Game';
      
      final metadata = GameMetadata(
        gameId: gameId,
        externalId: '12345',
        genres: const [],
        screenshots: const [],
        lastFetched: DateTime.now(),
      );

      blocTest<MetadataBloc, MetadataState>(
        'should retry fetch when RetryFetch is added',
        build: () {
          when(() => mockMetadataRepository.getMetadataForGame(gameId))
              .thenAnswer((_) async => null);
          when(() => mockMetadataRepository.fetchAndCacheMetadata(gameId, gameTitle))
              .thenAnswer((_) async => metadata);
          return bloc;
        },
        act: (bloc) => bloc.add(RetryFetch(
          gameId: gameId,
          gameTitle: gameTitle,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataLoaded>(),
        ],
      );
    });

    group('ClearMetadata', () {
      final gameId = 'game-123';

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataInitial] when clear succeeds',
        build: () {
          when(() => mockMetadataRepository.clearMetadata(gameId))
              .thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(ClearMetadata(gameId: gameId)),
        expect: () => [
          isA<MetadataInitial>(),
        ],
      );

      blocTest<MetadataBloc, MetadataState>(
        'emits [MetadataError] when clear fails',
        build: () {
          when(() => mockMetadataRepository.clearMetadata(gameId))
              .thenThrow(Exception('Clear failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(ClearMetadata(gameId: gameId)),
        expect: () => [
          isA<MetadataError>().having(
            (s) => s.isRetryable,
            'isRetryable',
            false,
          ),
        ],
      );
    });

    group('RefetchMetadata', () {
      final gameId = 'game-123';
      final gameTitle = 'Test Game';
      
      final metadata = GameMetadata(
        gameId: gameId,
        externalId: '12345',
        genres: const [],
        screenshots: const [],
        lastFetched: DateTime.now(),
      );

      blocTest<MetadataBloc, MetadataState>(
        'should clear and refetch metadata',
        build: () {
          when(() => mockMetadataRepository.clearMetadata(gameId))
              .thenAnswer((_) async {});
          when(() => mockMetadataRepository.getMetadataForGame(gameId))
              .thenAnswer((_) async => null);
          when(() => mockMetadataRepository.fetchAndCacheMetadata(gameId, gameTitle))
              .thenAnswer((_) async => metadata);
          return bloc;
        },
        act: (bloc) => bloc.add(RefetchMetadata(
          gameId: gameId,
          gameTitle: gameTitle,
        )),
        expect: () => [
          isA<MetadataLoading>(),
          isA<MetadataLoaded>(),
        ],
      );
    });

    group('State classes', () {
      test('MetadataInitial should be equatable', () {
        expect(const MetadataInitial(), equals(const MetadataInitial()));
      });

      test('MetadataLoading should be equatable', () {
        const state1 = MetadataLoading(gameId: '1', gameTitle: 'Game');
        const state2 = MetadataLoading(gameId: '1', gameTitle: 'Game');
        const state3 = MetadataLoading(gameId: '2', gameTitle: 'Other');

        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });

      test('MetadataLoaded should be equatable', () {
        final metadata = GameMetadata(
          gameId: '1',
          externalId: '123',
          genres: const [],
          screenshots: const [],
          lastFetched: DateTime.now(),
        );

        final state1 = MetadataLoaded(metadata: metadata);
        final state2 = MetadataLoaded(metadata: metadata);

        expect(state1, equals(state2));
      });

      test('MetadataMatchRequired should be equatable', () {
        const state1 = MetadataMatchRequired(
          gameId: '1',
          gameTitle: 'Game',
          alternatives: [],
        );
        const state2 = MetadataMatchRequired(
          gameId: '1',
          gameTitle: 'Game',
          alternatives: [],
        );

        expect(state1, equals(state2));
      });

      test('MetadataError should be equatable', () {
        const state1 = MetadataError(
          gameId: '1',
          message: 'Error',
          isRetryable: true,
        );
        const state2 = MetadataError(
          gameId: '1',
          message: 'Error',
          isRetryable: true,
        );

        expect(state1, equals(state2));
      });

      test('MetadataBatchProgress should calculate progress correctly', () {
        const state = MetadataBatchProgress(
          total: 10,
          completed: 5,
          failed: 2,
          isComplete: false,
        );

        expect(state.progress, equals(0.7));
        expect(state.remaining, equals(3));
      });

      test('MetadataSearchResults should be equatable', () {
        const state1 = MetadataSearchResults(
          query: 'test',
          results: [],
        );
        const state2 = MetadataSearchResults(
          query: 'test',
          results: [],
        );

        expect(state1, equals(state2));
      });
    });

    group('Event classes', () {
      test('FetchMetadata should be equatable', () {
        const event1 = FetchMetadata(
          gameId: '1',
          gameTitle: 'Game',
          executablePath: '/path',
        );
        const event2 = FetchMetadata(
          gameId: '1',
          gameTitle: 'Game',
          executablePath: '/path',
        );

        expect(event1, equals(event2));
      });

      test('BatchFetchMetadata should be equatable', () {
        const event1 = BatchFetchMetadata(gameIds: ['1', '2']);
        const event2 = BatchFetchMetadata(gameIds: ['1', '2']);

        expect(event1, equals(event2));
      });

      test('ManualSearch should be equatable', () {
        const event1 = ManualSearch(query: 'test');
        const event2 = ManualSearch(query: 'test');

        expect(event1, equals(event2));
      });

      test('SelectMatch should be equatable', () {
        const event1 = SelectMatch(gameId: '1', externalId: '123');
        const event2 = SelectMatch(gameId: '1', externalId: '123');

        expect(event1, equals(event2));
      });

      test('RetryFetch should be equatable', () {
        const event1 = RetryFetch(gameId: '1', gameTitle: 'Game');
        const event2 = RetryFetch(gameId: '1', gameTitle: 'Game');

        expect(event1, equals(event2));
      });

      test('ClearMetadata should be equatable', () {
        const event1 = ClearMetadata(gameId: '1');
        const event2 = ClearMetadata(gameId: '1');

        expect(event1, equals(event2));
      });

      test('RefetchMetadata should be equatable', () {
        const event1 = RefetchMetadata(gameId: '1', gameTitle: 'Game');
        const event2 = RefetchMetadata(gameId: '1', gameTitle: 'Game');

        expect(event1, equals(event2));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';
import 'package:squirrel_play/data/services/metadata/rawg_batch_search_service.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';

class MockRawgSource extends Mock implements RawgSource {}

class MockRawgApiClient extends Mock implements RawgApiClient {}

void main() {
  group('RawgBatchSearchService', () {
    late RawgBatchSearchService service;
    late MockRawgSource mockRawgSource;
    late MockRawgApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockRawgApiClient();
      mockRawgSource = MockRawgSource();

      when(() => mockRawgSource.isInitialized).thenReturn(true);
      when(() => mockRawgSource.apiClient).thenReturn(mockApiClient);
      when(() => mockRawgSource.initialize()).thenAnswer((_) async {});

      service = RawgBatchSearchService(rawgSource: mockRawgSource);
    });

    group('searchMultipleGamesSync', () {
      test('should process all games and return results', () async {
        when(() => mockApiClient.requestCount).thenReturn(0);
        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        ).thenAnswer((_) async => [
          const GameSearchResult(
            id: 1,
            name: 'Test Game',
            slug: 'test-game',
            released: '2023-01-01',
            backgroundImage: 'https://example.com/image.jpg',
            rating: 4.5,
          ),
        ]);

        final results = await service.searchMultipleGamesSync([
          'Test Game.exe',
          'Another Game.exe',
        ]);

        expect(results.length, equals(2));
        expect(results[0].success, isTrue);
        expect(results[0].match, isNotNull);
        expect(results[0].match!.gameName, equals('Test Game'));
        expect(results[1].success, isTrue);
      });

      test('should emit progress with correct counts', () async {
        when(() => mockApiClient.requestCount).thenReturn(0);
        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        ).thenAnswer((_) async => [
          const GameSearchResult(
            id: 1,
            name: 'Test Game',
            slug: 'test-game',
          ),
        ]);

        final progressUpdates = <BatchMetadataProgress>[];
        final stream = service.searchMultipleGames(['Test Game.exe']);

        await for (final progress in stream) {
          progressUpdates.add(progress);
        }

        expect(progressUpdates.length, equals(2));
        expect(progressUpdates[0].total, equals(1));
        // Progress is emitted AFTER processing, so first update shows 1 completed
        expect(progressUpdates[0].completed, equals(1));
        expect(progressUpdates[0].failed, equals(0));
        expect(progressUpdates[0].currentGame, equals('Test Game.exe'));
        expect(progressUpdates[0].isComplete, isFalse);

        expect(progressUpdates[1].total, equals(1));
        expect(progressUpdates[1].completed, equals(1));
        expect(progressUpdates[1].failed, equals(0));
        expect(progressUpdates[1].currentGame, isNull);
        expect(progressUpdates[1].isComplete, isTrue);
      });

      test('should respect free-plan request limit', () async {
        when(() => mockApiClient.requestCount).thenReturn(20000);

        final results = await service.searchMultipleGamesSync([
          'Test Game.exe',
        ]);

        expect(results.length, equals(1));
        expect(results[0].success, isFalse);
        expect(
          results[0].error,
          contains('free plan limit'),
        );
        verifyNever(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        );
      });

      test('should handle API not initialized', () async {
        when(() => mockRawgSource.isInitialized).thenReturn(false);
        when(() => mockRawgSource.initialize()).thenAnswer((_) async {});
        when(() => mockRawgSource.apiClient).thenReturn(null);

        final results = await service.searchMultipleGamesSync([
          'Test Game.exe',
        ]);

        expect(results.length, equals(1));
        expect(results[0].success, isFalse);
        expect(results[0].error, contains('not initialized'));
      });

      test('should handle empty cleaned name', () async {
        when(() => mockApiClient.requestCount).thenReturn(0);
        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        ).thenAnswer((_) async => []);

        final results = await service.searchMultipleGamesSync([
          '_',
        ]);

        expect(results.length, equals(1));
        expect(results[0].success, isFalse);
        expect(results[0].error, contains('empty'));
      });

      test('should handle no matches found', () async {
        when(() => mockApiClient.requestCount).thenReturn(0);
        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        ).thenAnswer((_) async => []);

        final results = await service.searchMultipleGamesSync([
          'NonExistentGame.exe',
        ]);

        expect(results.length, equals(1));
        expect(results[0].success, isFalse);
        expect(results[0].error, contains('No matches found'));
      });

      test('should mark low-confidence matches as non-auto-match', () async {
        when(() => mockApiClient.requestCount).thenReturn(0);
        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        ).thenAnswer((_) async => [
          const GameSearchResult(
            id: 1,
            name: 'Completely Different Name',
            slug: 'completely-different-name',
          ),
        ]);

        final results = await service.searchMultipleGamesSync([
          'MyGame.exe',
        ]);

        expect(results.length, equals(1));
        expect(results[0].success, isTrue);
        expect(results[0].match, isNotNull);
        expect(results[0].match!.isAutoMatch, isFalse);
      });
    });

    group('searchMultipleGames', () {
      test('should emit progress after each game', () async {
        when(() => mockApiClient.requestCount).thenReturn(0);
        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        ).thenAnswer((_) async => [
          const GameSearchResult(
            id: 1,
            name: 'Game',
            slug: 'game',
          ),
        ]);

        final progressList = <BatchMetadataProgress>[];
        await for (final progress
            in service.searchMultipleGames(['A.exe', 'B.exe', 'C.exe'])) {
          progressList.add(progress);
        }

        // Should emit: start A, start B, start C, complete
        expect(progressList.length, equals(4));
        expect(progressList[0].currentGame, equals('A.exe'));
        expect(progressList[1].currentGame, equals('B.exe'));
        expect(progressList[2].currentGame, equals('C.exe'));
        expect(progressList[3].isComplete, isTrue);
        expect(progressList[3].completed, equals(3));
      });
    });
  });
}

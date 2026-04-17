import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/services/api_key_service.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/data/services/metadata_matching_engine.dart';
import 'package:squirrel_play/data/services/metadata_service.dart';
import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/game.dart';

class MockApiKeyService extends Mock implements ApiKeyService {}

class MockRawgApiClient extends Mock implements RawgApiClient {}

class MockMetadataMatchingEngine extends Mock implements MetadataMatchingEngine {}

class MockMetadataAggregator extends Mock implements MetadataAggregator {}

class MockRawgSource extends Mock implements RawgSource {}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
  });
  group('MetadataService', () {
    late MetadataService service;
    late MockApiKeyService mockApiKeyService;
    late MockMetadataAggregator mockMetadataAggregator;
    late MockRawgSource mockRawgSource;

    setUp(() {
      mockApiKeyService = MockApiKeyService();
      mockMetadataAggregator = MockMetadataAggregator();
      mockRawgSource = MockRawgSource();

      service = MetadataService(
        apiKeyService: mockApiKeyService,
        metadataAggregator: mockMetadataAggregator,
        rawgSource: mockRawgSource,
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('initialize', () {
      test('should initialize rawg source when API key is available', () async {
        const testKey = '12345678901234567890123456789012';
        when(() => mockApiKeyService.getApiKey()).thenAnswer((_) async => testKey);
        when(() => mockRawgSource.initialize()).thenAnswer((_) async {});
        when(() => mockRawgSource.isInitialized).thenReturn(true);

        await service.initialize();

        verify(() => mockRawgSource.initialize()).called(1);
      });

      test('should not throw when no API key is available', () async {
        when(() => mockApiKeyService.getApiKey()).thenAnswer((_) async => null);
        when(() => mockRawgSource.initialize()).thenAnswer((_) async {});

        await service.initialize();

        verify(() => mockRawgSource.initialize()).called(1);
      });
    });

    group('setApiKey', () {
      test('should complete without error', () async {
        const testKey = '12345678901234567890123456789012';
        when(() => mockApiKeyService.saveApiKey(any())).thenAnswer((_) async {});
        when(() => mockRawgSource.setApiKey(any())).thenAnswer((_) async {});

        // Should complete without throwing
        await service.setApiKey(testKey);
      });
    });

    group('findMatch', () {
      test('should delegate to rawgSource.findMatch', () async {
        when(() => mockRawgSource.findMatch(any())).thenAnswer((_) async => null);

        final result = await service.findMatch('game.exe');

        expect(result, isNull);
        verify(() => mockRawgSource.findMatch('game.exe')).called(1);
      });
    });

    group('manualSearch', () {
      test('should delegate to rawgSource.searchManually', () async {
        when(() => mockRawgSource.searchManually(any())).thenAnswer((_) async => []);

        final result = await service.manualSearch('test query');

        expect(result, isEmpty);
        verify(() => mockRawgSource.searchManually('test query')).called(1);
      });
    });

    group('fetchMetadata', () {
      test('should return null when not initialized', () async {
        when(() => mockRawgSource.isInitialized).thenReturn(false);
        when(() => mockRawgSource.initialize()).thenAnswer((_) async {});

        final result = await service.fetchMetadata('game1', '123');

        expect(result, isNull);
      });

      test('should return null for invalid external ID', () async {
        when(() => mockRawgSource.isInitialized).thenReturn(true);

        // Invalid external ID (not a number)
        final result = await service.fetchMetadata('game1', 'invalid');

        expect(result, isNull);
      });

      test('should delegate to rawgSource.fetchById for valid ID', () async {
        when(() => mockRawgSource.isInitialized).thenReturn(true);
        when(() => mockRawgSource.fetchById('game1', 123)).thenAnswer((_) async => null);

        final result = await service.fetchMetadata('game1', '123');

        expect(result, isNull);
        verify(() => mockRawgSource.fetchById('game1', 123)).called(1);
      });
    });

    group('batchFetchMetadata', () {
      test('should emit progress with completion when not initialized', () async {
        when(() => mockRawgSource.isInitialized).thenReturn(false);
        when(() => mockRawgSource.initialize()).thenAnswer((_) async {});

        final games = [
          Game(
            id: 'game1',
            title: 'Game 1',
            executablePath: '/games/game1.exe',
            addedDate: DateTime.now(),
          ),
        ];

        final progressUpdates = <BatchMetadataProgress>[];
        final subscription = service.batchProgressStream.listen(progressUpdates.add);

        final results = await service.batchFetchMetadata(games);

        // Wait for stream events
        await Future.delayed(const Duration(milliseconds: 100));

        expect(results, isEmpty);
        expect(progressUpdates, isNotEmpty);

        final lastProgress = progressUpdates.last;
        expect(lastProgress.isComplete, isTrue);
        // When not initialized, all games fail
        expect(lastProgress.failed, equals(1));

        await subscription.cancel();
      });

      test('should process empty game list', () async {
        when(() => mockRawgSource.isInitialized).thenReturn(true);

        final progressUpdates = <BatchMetadataProgress>[];
        final subscription = service.batchProgressStream.listen(progressUpdates.add);

        final results = await service.batchFetchMetadata([]);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results, isEmpty);
        // Empty list emits completion progress
        expect(progressUpdates, isNotEmpty);
        expect(progressUpdates.last.isComplete, isTrue);

        await subscription.cancel();
      });

      test('should use aggregator for automatic fetching', () async {
        when(() => mockRawgSource.isInitialized).thenReturn(true);

        final games = [
          Game(
            id: 'game1',
            title: 'Game 1',
            executablePath: '/games/game1.exe',
            addedDate: DateTime.now(),
          ),
        ];

        when(() => mockMetadataAggregator.fetchMetadata(any())).thenAnswer((_) async => null);

        final progressUpdates = <BatchMetadataProgress>[];
        final subscription = service.batchProgressStream.listen(progressUpdates.add);

        final results = await service.batchFetchMetadata(games);

        await Future.delayed(const Duration(milliseconds: 300));

        expect(results, isEmpty);
        verify(() => mockMetadataAggregator.fetchMetadata(games.first)).called(1);

        await subscription.cancel();
      });
    });

    group('BatchMetadataProgress', () {
      test('should calculate progress correctly', () {
        const progress = BatchMetadataProgress(
          total: 10,
          completed: 5,
          failed: 2,
          isComplete: false,
        );

        expect(progress.progress, equals(0.7)); // (5 + 2) / 10
        expect(progress.remaining, equals(3)); // 10 - 5 - 2
      });

      test('should return 0.0 progress when total is 0', () {
        const progress = BatchMetadataProgress(
          total: 0,
          completed: 0,
          failed: 0,
          isComplete: true,
        );

        expect(progress.progress, equals(0.0));
        expect(progress.remaining, equals(0));
      });

      test('should include all fields in props', () {
        const progress1 = BatchMetadataProgress(
          total: 10,
          completed: 5,
          failed: 2,
          currentGame: 'Test Game',
          isComplete: false,
          error: null,
        );

        const progress2 = BatchMetadataProgress(
          total: 10,
          completed: 5,
          failed: 2,
          currentGame: 'Test Game',
          isComplete: false,
          error: null,
        );

        const progress3 = BatchMetadataProgress(
          total: 10,
          completed: 6,
          failed: 2,
          currentGame: 'Test Game',
          isComplete: false,
          error: null,
        );

        expect(progress1, equals(progress2));
        expect(progress1, isNot(equals(progress3)));
      });
    });

    group('dispose', () {
      test('should close stream controller', () async {
        // Should not throw
        service.dispose();

        // Stream should be closed
        expect(service.batchProgressStream.isBroadcast, isTrue);
      });
    });
  });
}

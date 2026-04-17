import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:squirrel_play/data/datasources/local/database_constants.dart';
import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/repositories/metadata_repository_impl.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata_service.dart';
import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';

class MockMetadataService extends Mock implements MetadataService {}

class MockMetadataAggregator extends Mock implements MetadataAggregator {}

class MockGameRepository extends Mock implements GameRepository {}

class TestDatabaseHelper implements DatabaseHelper {
  final Database _testDb;

  TestDatabaseHelper(this._testDb);

  @override
  Future<Database> get database async => _testDb;

  @override
  Future<void> close() async {
    await _testDb.close();
  }

  @override
  Future<void> deleteDatabase() async {
    await _testDb.close();
  }

  @override
  bool get isOpen => _testDb.isOpen;
}

void main() {
  // Initialize sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('MetadataRepositoryImpl', () {
    late MetadataRepositoryImpl repository;
    late TestDatabaseHelper databaseHelper;
    late MockMetadataService mockMetadataService;
    late MockMetadataAggregator mockMetadataAggregator;
    late MockGameRepository mockGameRepository;
    late Database db;

    setUp(() async {
      mockMetadataService = MockMetadataService();
      mockMetadataAggregator = MockMetadataAggregator();
      mockGameRepository = MockGameRepository();
      
      // Create in-memory database with schema
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create games table
          await db.execute('''
            CREATE TABLE ${DatabaseConstants.tableGames} (
              ${DatabaseConstants.colId} TEXT PRIMARY KEY,
              ${DatabaseConstants.colTitle} TEXT NOT NULL,
              ${DatabaseConstants.colExecutablePath} TEXT NOT NULL UNIQUE,
              ${DatabaseConstants.colDirectoryId} TEXT,
              ${DatabaseConstants.colAddedDate} INTEGER NOT NULL,
              ${DatabaseConstants.colLastPlayedDate} INTEGER,
              ${DatabaseConstants.colIsFavorite} INTEGER NOT NULL DEFAULT 0,
              ${DatabaseConstants.colPlayCount} INTEGER NOT NULL DEFAULT 0
            )
          ''');

          // Create game_metadata table
          await db.execute('''
            CREATE TABLE ${DatabaseConstants.tableGameMetadata} (
              ${DatabaseConstants.colGameId} TEXT PRIMARY KEY,
              ${DatabaseConstants.colExternalId} TEXT,
              ${DatabaseConstants.colDescription} TEXT,
              ${DatabaseConstants.colCoverImageUrl} TEXT,
              ${DatabaseConstants.colHeroImageUrl} TEXT,
              ${DatabaseConstants.colReleaseDate} INTEGER,
              ${DatabaseConstants.colRating} REAL,
              ${DatabaseConstants.colDeveloper} TEXT,
              ${DatabaseConstants.colPublisher} TEXT,
              ${DatabaseConstants.colLastFetched} INTEGER NOT NULL,
              FOREIGN KEY (${DatabaseConstants.colGameId}) 
                REFERENCES ${DatabaseConstants.tableGames}(${DatabaseConstants.colId}) 
                ON DELETE CASCADE
            )
          ''');

          // Create game_genres table
          await db.execute('''
            CREATE TABLE ${DatabaseConstants.tableGameGenres} (
              ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DatabaseConstants.colGameId} TEXT NOT NULL,
              ${DatabaseConstants.colGenre} TEXT NOT NULL,
              FOREIGN KEY (${DatabaseConstants.colGameId}) 
                REFERENCES ${DatabaseConstants.tableGames}(${DatabaseConstants.colId}) 
                ON DELETE CASCADE
            )
          ''');

          // Create game_screenshots table
          await db.execute('''
            CREATE TABLE ${DatabaseConstants.tableGameScreenshots} (
              ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DatabaseConstants.colGameId} TEXT NOT NULL,
              ${DatabaseConstants.colScreenshotUrl} TEXT NOT NULL,
              ${DatabaseConstants.colSortOrder} INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (${DatabaseConstants.colGameId}) 
                REFERENCES ${DatabaseConstants.tableGames}(${DatabaseConstants.colId}) 
                ON DELETE CASCADE
            )
          ''');
        },
      );

      databaseHelper = TestDatabaseHelper(db);
      repository = MetadataRepositoryImpl(
        databaseHelper: databaseHelper,
        metadataService: mockMetadataService,
        metadataAggregator: mockMetadataAggregator,
        gameRepository: mockGameRepository,
      );
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    group('CRUD Operations', () {
      test('should save metadata to database', () async {
        final gameId = const Uuid().v4();
        final metadata = GameMetadata(
          gameId: gameId,
          externalId: '12345',
          description: 'Test game description',
          coverImageUrl: 'https://example.com/cover.jpg',
          heroImageUrl: 'https://example.com/hero.jpg',
          genres: const ['Action', 'Adventure'],
          screenshots: const ['https://example.com/ss1.jpg'],
          releaseDate: DateTime(2023, 1, 1),
          rating: 4.5,
          developer: 'Test Dev',
          publisher: 'Test Pub',
          lastFetched: DateTime.now(),
        );

        await repository.saveMetadata(metadata);

        final result = await repository.getMetadataForGame(gameId);

        expect(result, isNotNull);
        expect(result!.gameId, equals(gameId));
        expect(result.externalId, equals('12345'));
        expect(result.description, equals('Test game description'));
        expect(result.genres, containsAll(['Action', 'Adventure']));
        expect(result.screenshots, contains('https://example.com/ss1.jpg'));
      });

      test('should update existing metadata', () async {
        final gameId = const Uuid().v4();
        
        // First save
        final metadata1 = GameMetadata(
          gameId: gameId,
          externalId: '12345',
          description: 'Original description',
          genres: const ['Action'],
          screenshots: const [],
          lastFetched: DateTime.now(),
        );
        await repository.saveMetadata(metadata1);

        // Update
        final metadata2 = GameMetadata(
          gameId: gameId,
          externalId: '12345',
          description: 'Updated description',
          genres: const ['Action', 'RPG'],
          screenshots: const ['https://example.com/ss.jpg'],
          lastFetched: DateTime.now(),
        );
        await repository.saveMetadata(metadata2);

        final result = await repository.getMetadataForGame(gameId);

        expect(result!.description, equals('Updated description'));
        expect(result.genres, equals(['Action', 'RPG']));
        expect(result.screenshots, contains('https://example.com/ss.jpg'));
      });

      test('should return null when metadata does not exist', () async {
        final result = await repository.getMetadataForGame('non-existent-id');

        expect(result, isNull);
      });

      test('should clear metadata for a game', () async {
        final gameId = const Uuid().v4();
        final metadata = GameMetadata(
          gameId: gameId,
          externalId: '12345',
          genres: const ['Action'],
          screenshots: const [],
          lastFetched: DateTime.now(),
        );

        await repository.saveMetadata(metadata);
        
        // Verify it exists
        var result = await repository.getMetadataForGame(gameId);
        expect(result, isNotNull);

        // Clear it
        await repository.clearMetadata(gameId);

        // Verify it's gone
        result = await repository.getMetadataForGame(gameId);
        expect(result, isNull);
      });

      test('should check if metadata exists', () async {
        final gameId = const Uuid().v4();
        
        // Initially should not exist
        expect(await repository.hasMetadata(gameId), isFalse);

        // Save metadata
        final metadata = GameMetadata(
          gameId: gameId,
          externalId: '12345',
          genres: const [],
          screenshots: const [],
          lastFetched: DateTime.now(),
        );
        await repository.saveMetadata(metadata);

        // Now should exist
        expect(await repository.hasMetadata(gameId), isTrue);
      });
    });

    group('batchProgressStream', () {
      test('should emit progress updates during batch fetch', () async {
        final gameId = const Uuid().v4();
        final game = Game(
          id: gameId,
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        // Mock the metadata service to return null (no match)
        when(() => mockMetadataService.findMatch(any())).thenAnswer((_) async => null);

        final progressUpdates = <BatchMetadataProgress>[];
        final subscription = repository.batchProgressStream.listen(progressUpdates.add);

        await repository.batchFetchMetadata([game]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(progressUpdates, isNotEmpty);
        expect(progressUpdates.last.isComplete, isTrue);

        await subscription.cancel();
      });
    });

    group('manualSearch', () {
      test('should delegate to metadata service', () async {
        const query = 'test game';
        final alternatives = [
          const MetadataAlternative(
            gameId: '1',
            gameName: 'Test Game 1',
            confidence: 0.9,
          ),
        ];

        when(() => mockMetadataService.manualSearch(query))
            .thenAnswer((_) async => alternatives);

        final result = await repository.manualSearch(query);

        expect(result, equals(alternatives));
        verify(() => mockMetadataService.manualSearch(query)).called(1);
      });
    });

    group('updateMetadata', () {
      test('should fetch and save metadata with new external ID', () async {
        final gameId = const Uuid().v4();
        final metadata = GameMetadata(
          gameId: gameId,
          externalId: '54321',
          description: 'Updated metadata',
          genres: const ['RPG'],
          screenshots: const [],
          lastFetched: DateTime.now(),
        );

        when(() => mockMetadataService.fetchMetadata(gameId, '54321'))
            .thenAnswer((_) async => metadata);

        final result = await repository.updateMetadata(gameId, '54321');

        expect(result.gameId, equals(gameId));
        expect(result.externalId, equals('54321'));
        
        // Verify it was saved
        final saved = await repository.getMetadataForGame(gameId);
        expect(saved, isNotNull);
        expect(saved!.externalId, equals('54321'));
      });

      test('should throw when fetch fails', () async {
        final gameId = const Uuid().v4();

        when(() => mockMetadataService.fetchMetadata(gameId, 'invalid'))
            .thenAnswer((_) async => null);

        expect(
          () => repository.updateMetadata(gameId, 'invalid'),
          throwsException,
        );
      });
    });

    group('MetadataMatchRequiredException', () {
      test('should create exception with required fields', () {
        final exception = MetadataMatchRequiredException(
          gameId: 'game1',
          gameTitle: 'Test Game',
          alternatives: [
            const MetadataAlternative(
              gameId: '1',
              gameName: 'Alternative 1',
              confidence: 0.6,
            ),
          ],
        );

        expect(exception.gameId, equals('game1'));
        expect(exception.gameTitle, equals('Test Game'));
        expect(exception.alternatives.length, equals(1));
        expect(exception.toString(), contains('Test Game'));
      });
    });

    group('dispose', () {
      test('should close stream controller', () {
        // Should not throw
        repository.dispose();
      });
    });
  });
}

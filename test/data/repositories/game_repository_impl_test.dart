import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/repositories/game_repository_impl.dart';
import 'package:squirrel_play/domain/entities/game.dart';

void main() {
  // Initialize sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('GameRepositoryImpl', () {
    late DatabaseHelper databaseHelper;
    late GameRepositoryImpl repository;

    setUp(() async {
      // Use in-memory database for testing
      databaseHelper = DatabaseHelper();
      // Override the database path to use in-memory
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create tables
          await db.execute('''
            CREATE TABLE games (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              executable_path TEXT NOT NULL UNIQUE,
              directory_id TEXT,
              added_date INTEGER NOT NULL,
              last_played_date INTEGER,
              is_favorite INTEGER NOT NULL DEFAULT 0,
              play_count INTEGER NOT NULL DEFAULT 0,
              launch_arguments TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE scan_directories (
              id TEXT PRIMARY KEY,
              path TEXT NOT NULL UNIQUE,
              added_date INTEGER NOT NULL,
              last_scanned_date INTEGER
            )
          ''');
        },
      );
      // Inject the test database
      databaseHelper = TestDatabaseHelper(db);
      repository = GameRepositoryImpl(databaseHelper: databaseHelper);
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    group('CRUD Operations', () {
      test('should add a game to the database', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        final result = await repository.addGame(game);

        expect(result.id, equals(game.id));
        expect(result.title, equals(game.title));
        expect(result.executablePath, equals(game.executablePath));
      });

      test('should retrieve all games from the database', () async {
        final game1 = Game(
          id: const Uuid().v4(),
          title: 'Game 1',
          executablePath: '/games/game1.exe',
          addedDate: DateTime.now(),
        );
        final game2 = Game(
          id: const Uuid().v4(),
          title: 'Game 2',
          executablePath: '/games/game2.exe',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game1);
        await repository.addGame(game2);

        final games = await repository.getAllGames();

        expect(games.length, equals(2));
        expect(games.map((g) => g.title), containsAll(['Game 1', 'Game 2']));
      });

      test('should retrieve a game by ID', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game);
        final result = await repository.getGameById(game.id);

        expect(result, isNotNull);
        expect(result!.id, equals(game.id));
        expect(result.title, equals(game.title));
      });

      test('should persist and retrieve launchArguments', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
          launchArguments: '-windowed --fullscreen',
        );

        await repository.addGame(game);
        final result = await repository.getGameById(game.id);

        expect(result, isNotNull);
        expect(result!.launchArguments, equals('-windowed --fullscreen'));
      });

      test('should return null when game ID does not exist', () async {
        final result = await repository.getGameById('non-existent-id');

        expect(result, isNull);
      });

      test('should retrieve a game by executable path', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game);
        final result = await repository.getGameByExecutablePath('/games/test.exe');

        expect(result, isNotNull);
        expect(result!.executablePath, equals('/games/test.exe'));
      });

      test('should update a game', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Original Title',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game);

        final updated = game.copyWith(title: 'Updated Title');
        await repository.updateGame(updated);

        final result = await repository.getGameById(game.id);
        expect(result!.title, equals('Updated Title'));
      });

      test('should delete a game from the database', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game);
        await repository.deleteGame(game.id);

        final result = await repository.getGameById(game.id);
        expect(result, isNull);
      });
    });

    group('Game Existence Check', () {
      test('should return true when game exists', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game);
        final exists = await repository.gameExists('/games/test.exe');

        expect(exists, isTrue);
      });

      test('should return false when game does not exist', () async {
        final exists = await repository.gameExists('/games/nonexistent.exe');

        expect(exists, isFalse);
      });
    });

    group('Game Operations', () {
      test('should toggle favorite status', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
          isFavorite: false,
        );

        await repository.addGame(game);
        final updated = await repository.toggleFavorite(game.id);

        expect(updated.isFavorite, isTrue);

        final updated2 = await repository.toggleFavorite(game.id);
        expect(updated2.isFavorite, isFalse);
      });

      test('should increment play count', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
          playCount: 0,
        );

        await repository.addGame(game);
        final updated = await repository.incrementPlayCount(game.id);

        expect(updated.playCount, equals(1));

        final updated2 = await repository.incrementPlayCount(game.id);
        expect(updated2.playCount, equals(2));
      });

      test('should update last played date', () async {
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game);

        final now = DateTime.now();
        final updated = await repository.updateLastPlayed(game.id, now);

        expect(updated.lastPlayedDate, isNotNull);
        expect(
          updated.lastPlayedDate!.millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch),
        );
      });
    });

    group('Directory Association', () {
      test('should get games by directory ID', () async {
        final directoryId = const Uuid().v4();

        final game1 = Game(
          id: const Uuid().v4(),
          title: 'Game 1',
          executablePath: '/games/game1.exe',
          directoryId: directoryId,
          addedDate: DateTime.now(),
        );
        final game2 = Game(
          id: const Uuid().v4(),
          title: 'Game 2',
          executablePath: '/games/game2.exe',
          directoryId: directoryId,
          addedDate: DateTime.now(),
        );
        final game3 = Game(
          id: const Uuid().v4(),
          title: 'Game 3',
          executablePath: '/games/game3.exe',
          directoryId: 'other-directory',
          addedDate: DateTime.now(),
        );

        await repository.addGame(game1);
        await repository.addGame(game2);
        await repository.addGame(game3);

        final result = await repository.getGamesByDirectoryId(directoryId);

        expect(result.length, equals(2));
        expect(result.map((g) => g.title), containsAll(['Game 1', 'Game 2']));
      });
    });

    group('Cascade Delete', () {
      test('should cascade delete metadata when game is deleted', () async {
        final db = await databaseHelper.database;
        
        // Enable foreign keys for cascade delete to work
        await db.execute('PRAGMA foreign_keys = ON');
        
        // Create game_metadata table with foreign key constraint
        await db.execute('''
          CREATE TABLE game_metadata (
            game_id TEXT PRIMARY KEY,
            external_id TEXT,
            description TEXT,
            cover_image_url TEXT,
            hero_image_url TEXT,
            release_date INTEGER,
            rating REAL,
            developer TEXT,
            publisher TEXT,
            last_fetched INTEGER NOT NULL,
            FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
          )
        ''');
        
        // Create a game
        final game = Game(
          id: const Uuid().v4(),
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );
        
        await repository.addGame(game);
        
        // Insert metadata for the game
        await db.insert('game_metadata', {
          'game_id': game.id,
          'external_id': '12345',
          'description': 'A test game',
          'cover_image_url': 'http://example.com/cover.jpg',
          'hero_image_url': 'http://example.com/hero.jpg',
          'release_date': DateTime.now().millisecondsSinceEpoch,
          'rating': 4.5,
          'developer': 'Test Developer',
          'publisher': 'Test Publisher',
          'last_fetched': DateTime.now().millisecondsSinceEpoch,
        });
        
        // Verify metadata exists
        final metadataBefore = await db.query(
          'game_metadata',
          where: 'game_id = ?',
          whereArgs: [game.id],
        );
        expect(metadataBefore.length, equals(1));
        
        // Delete the game
        await repository.deleteGame(game.id);
        
        // Verify game is deleted
        final deletedGame = await repository.getGameById(game.id);
        expect(deletedGame, isNull);
        
        // Verify metadata is also deleted (cascade)
        final metadataAfter = await db.query(
          'game_metadata',
          where: 'game_id = ?',
          whereArgs: [game.id],
        );
        expect(metadataAfter.length, equals(0));
      });
    });
  });
}

/// Test helper to inject a pre-configured database
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

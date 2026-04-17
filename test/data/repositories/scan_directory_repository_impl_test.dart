import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/repositories/scan_directory_repository_impl.dart';

void main() {
  // Initialize sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ScanDirectoryRepositoryImpl', () {
    late DatabaseHelper databaseHelper;
    late ScanDirectoryRepositoryImpl repository;

    setUp(() async {
      // Use in-memory database for testing
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
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

      databaseHelper = TestDatabaseHelper(db);
      repository = ScanDirectoryRepositoryImpl(
        databaseHelper: databaseHelper,
        uuid: const Uuid(),
      );
    });

    tearDown(() async {
      await databaseHelper.close();
    });

    group('CRUD Operations', () {
      test('should add a directory to the database', () async {
        final result = await repository.addDirectory('/games/steam');

        expect(result.path, equals('/games/steam'));
        expect(result.id, isNotEmpty);
        expect(result.addedDate, isNotNull);
      });

      test('should retrieve all directories from the database', () async {
        await repository.addDirectory('/games/steam');
        await repository.addDirectory('/games/gog');
        await repository.addDirectory('/games/epic');

        final directories = await repository.getAllDirectories();

        expect(directories.length, equals(3));
        expect(
          directories.map((d) => d.path),
          containsAll(['/games/steam', '/games/gog', '/games/epic']),
        );
      });

      test('should retrieve a directory by ID', () async {
        final added = await repository.addDirectory('/games/steam');
        final result = await repository.getDirectoryById(added.id);

        expect(result, isNotNull);
        expect(result!.id, equals(added.id));
        expect(result.path, equals('/games/steam'));
      });

      test('should return null when directory ID does not exist', () async {
        final result = await repository.getDirectoryById('non-existent-id');

        expect(result, isNull);
      });

      test('should retrieve a directory by path', () async {
        await repository.addDirectory('/games/steam');
        final result = await repository.getDirectoryByPath('/games/steam');

        expect(result, isNotNull);
        expect(result!.path, equals('/games/steam'));
      });

      test('should return null when directory path does not exist', () async {
        final result = await repository.getDirectoryByPath('/nonexistent/path');

        expect(result, isNull);
      });

      test('should delete a directory from the database', () async {
        final added = await repository.addDirectory('/games/steam');
        await repository.deleteDirectory(added.id);

        final result = await repository.getDirectoryById(added.id);
        expect(result, isNull);
      });
    });

    group('Directory Existence Check', () {
      test('should return true when directory exists', () async {
        await repository.addDirectory('/games/steam');
        final exists = await repository.directoryExists('/games/steam');

        expect(exists, isTrue);
      });

      test('should return false when directory does not exist', () async {
        final exists = await repository.directoryExists('/nonexistent/path');

        expect(exists, isFalse);
      });
    });

    group('Last Scanned Update', () {
      test('should update last scanned date', () async {
        final added = await repository.addDirectory('/games/steam');

        expect(added.lastScannedDate, isNull);

        final now = DateTime.now();
        final updated = await repository.updateLastScanned(added.id, now);

        expect(updated.lastScannedDate, isNotNull);
        expect(
          updated.lastScannedDate!.millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch),
        );
      });

      test('should throw exception when updating non-existent directory', () async {
        final now = DateTime.now();

        expect(
          () => repository.updateLastScanned('non-existent-id', now),
          throwsException,
        );
      });
    });

    group('Date Storage', () {
      test('should store and retrieve dates correctly', () async {
        final added = await repository.addDirectory('/games/steam');

        // Verify added_date is stored and retrieved correctly
        final retrieved = await repository.getDirectoryById(added.id);
        expect(retrieved!.addedDate.millisecondsSinceEpoch,
            equals(added.addedDate.millisecondsSinceEpoch));
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

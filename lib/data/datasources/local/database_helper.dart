import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite_common/sqflite.dart';

import 'package:squirrel_play/data/datasources/local/database_constants.dart';

/// Database helper class for managing SQLite database connections.
///
/// Handles database initialization, migration support, and provides
/// access to the database instance.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Singleton pattern
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Gets the database instance, initializing if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database with proper configuration.
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configures database settings before opening.
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates all database tables on first run.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Create tables
    batch.execute(DatabaseConstants.createGamesTable);
    batch.execute(DatabaseConstants.createGameMetadataTable);
    batch.execute(DatabaseConstants.createGameGenresTable);
    batch.execute(DatabaseConstants.createGameScreenshotsTable);
    batch.execute(DatabaseConstants.createScanDirectoriesTable);

    // Create indexes
    batch.execute(DatabaseConstants.createGamesDirectoryIdIndex);
    batch.execute(DatabaseConstants.createGamesExecutablePathIndex);

    await batch.commit();
  }

  /// Handles database migrations on version upgrade.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableGameMetadata} '
        'ADD COLUMN ${DatabaseConstants.colMetadataTitle} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableGameMetadata} '
        'ADD COLUMN ${DatabaseConstants.colCardImageUrl} TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableGameMetadata} '
        'ADD COLUMN ${DatabaseConstants.colLogoImageUrl} TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.tableGames} '
        'ADD COLUMN ${DatabaseConstants.colLaunchArguments} TEXT',
      );
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Deletes the entire database file.
  Future<void> deleteDatabase() async {
    await close();
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
  }

  /// Checks if the database is open.
  bool get isOpen => _database?.isOpen ?? false;
}

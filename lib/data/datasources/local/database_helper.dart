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
    // Migration logic for future versions
    // For now, just recreate tables if version changes
    if (oldVersion < newVersion) {
      // In production, proper migration scripts would be used
      // For now, we drop and recreate (development only)
      await _dropAllTables(db);
      await _onCreate(db, newVersion);
    }
  }

  /// Drops all tables (used for migrations/testing).
  Future<void> _dropAllTables(Database db) async {
    final batch = db.batch();

    batch.execute('DROP TABLE IF EXISTS ${DatabaseConstants.tableGameScreenshots}');
    batch.execute('DROP TABLE IF EXISTS ${DatabaseConstants.tableGameGenres}');
    batch.execute('DROP TABLE IF EXISTS ${DatabaseConstants.tableGameMetadata}');
    batch.execute('DROP TABLE IF EXISTS ${DatabaseConstants.tableGames}');
    batch.execute('DROP TABLE IF EXISTS ${DatabaseConstants.tableScanDirectories}');

    await batch.commit();
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

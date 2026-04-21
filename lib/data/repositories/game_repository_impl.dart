import 'package:sqflite_common/sqflite.dart';

import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/datasources/local/database_constants.dart';
import 'package:squirrel_play/data/models/game_model.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';

/// Concrete implementation of [GameRepository] using SQLite.
class GameRepositoryImpl implements GameRepository {
  final DatabaseHelper _databaseHelper;

  GameRepositoryImpl({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  @override
  Future<List<Game>> getAllGames() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(DatabaseConstants.tableGames);
    return maps.map((map) => _mapToEntity(GameModel.fromMap(map))).toList();
  }

  @override
  Future<Game?> getGameById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableGames,
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _mapToEntity(GameModel.fromMap(maps.first));
  }

  @override
  Future<Game?> getGameByExecutablePath(String path) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableGames,
      where: '${DatabaseConstants.colExecutablePath} = ?',
      whereArgs: [path],
    );
    if (maps.isEmpty) return null;
    return _mapToEntity(GameModel.fromMap(maps.first));
  }

  @override
  Future<Game> addGame(Game game) async {
    final db = await _databaseHelper.database;
    final model = _mapToModel(game);
    await db.insert(
      DatabaseConstants.tableGames,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return game;
  }

  @override
  Future<Game> updateGame(Game game) async {
    final db = await _databaseHelper.database;
    final model = _mapToModel(game);
    await db.update(
      DatabaseConstants.tableGames,
      model.toMap(),
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [game.id],
    );
    return game;
  }

  @override
  Future<void> deleteGame(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseConstants.tableGames,
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> gameExists(String executablePath) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableGames} '
      'WHERE ${DatabaseConstants.colExecutablePath} = ?',
      [executablePath],
    );
    return (result.first['count'] as int) > 0;
  }

  @override
  Future<List<Game>> getGamesByDirectoryId(String directoryId) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableGames,
      where: '${DatabaseConstants.colDirectoryId} = ?',
      whereArgs: [directoryId],
    );
    return maps.map((map) => _mapToEntity(GameModel.fromMap(map))).toList();
  }

  @override
  Future<Game> toggleFavorite(String id) async {
    final game = await getGameById(id);
    if (game == null) throw Exception('Game not found: $id');
    final updated = game.copyWith(isFavorite: !game.isFavorite);
    return updateGame(updated);
  }

  @override
  Future<Game> incrementPlayCount(String id) async {
    final game = await getGameById(id);
    if (game == null) throw Exception('Game not found: $id');
    final updated = game.copyWith(playCount: game.playCount + 1);
    return updateGame(updated);
  }

  @override
  Future<Game> updateLastPlayed(String id, DateTime date) async {
    final game = await getGameById(id);
    if (game == null) throw Exception('Game not found: $id');
    final updated = game.copyWith(lastPlayedDate: date);
    return updateGame(updated);
  }

  // Helper methods for mapping between entity and model
  Game _mapToEntity(GameModel model) {
    return Game(
      id: model.id,
      title: model.title,
      executablePath: model.executablePath,
      directoryId: model.directoryId,
      addedDate: model.addedDate,
      lastPlayedDate: model.lastPlayedDate,
      isFavorite: model.isFavorite,
      playCount: model.playCount,
      launchArguments: model.launchArguments,
      platform: model.platform,
      platformGameId: model.platformGameId,
    );
  }

  GameModel _mapToModel(Game entity) {
    return GameModel(
      id: entity.id,
      title: entity.title,
      executablePath: entity.executablePath,
      directoryId: entity.directoryId,
      addedDate: entity.addedDate,
      lastPlayedDate: entity.lastPlayedDate,
      isFavorite: entity.isFavorite,
      playCount: entity.playCount,
      launchArguments: entity.launchArguments,
      platform: entity.platform,
      platformGameId: entity.platformGameId,
    );
  }
}

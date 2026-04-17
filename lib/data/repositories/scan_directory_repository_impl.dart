import 'package:sqflite_common/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/datasources/local/database_constants.dart';
import 'package:squirrel_play/data/models/scan_directory_model.dart';
import 'package:squirrel_play/domain/entities/scan_directory.dart';
import 'package:squirrel_play/domain/repositories/scan_directory_repository.dart';

/// Concrete implementation of [ScanDirectoryRepository] using SQLite.
class ScanDirectoryRepositoryImpl implements ScanDirectoryRepository {
  final DatabaseHelper _databaseHelper;
  final Uuid _uuid;

  ScanDirectoryRepositoryImpl({
    required DatabaseHelper databaseHelper,
    Uuid? uuid,
  })  : _databaseHelper = databaseHelper,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<ScanDirectory>> getAllDirectories() async {
    final db = await _databaseHelper.database;
    final maps = await db.query(DatabaseConstants.tableScanDirectories);
    return maps
        .map((map) => _mapToEntity(ScanDirectoryModel.fromMap(map)))
        .toList();
  }

  @override
  Future<ScanDirectory?> getDirectoryById(String id) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableScanDirectories,
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _mapToEntity(ScanDirectoryModel.fromMap(maps.first));
  }

  @override
  Future<ScanDirectory?> getDirectoryByPath(String path) async {
    final db = await _databaseHelper.database;
    final maps = await db.query(
      DatabaseConstants.tableScanDirectories,
      where: '${DatabaseConstants.colPath} = ?',
      whereArgs: [path],
    );
    if (maps.isEmpty) return null;
    return _mapToEntity(ScanDirectoryModel.fromMap(maps.first));
  }

  @override
  Future<ScanDirectory> addDirectory(String path) async {
    final db = await _databaseHelper.database;
    final model = ScanDirectoryModel(
      id: _uuid.v4(),
      path: path,
      addedDate: DateTime.now(),
    );
    await db.insert(
      DatabaseConstants.tableScanDirectories,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return _mapToEntity(model);
  }

  @override
  Future<void> deleteDirectory(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseConstants.tableScanDirectories,
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<ScanDirectory> updateLastScanned(String id, DateTime date) async {
    final db = await _databaseHelper.database;
    final directory = await getDirectoryById(id);
    if (directory == null) throw Exception('Directory not found: $id');

    final updated = directory.copyWith(lastScannedDate: date);
    final model = _mapToModel(updated);

    await db.update(
      DatabaseConstants.tableScanDirectories,
      model.toMap(),
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [id],
    );

    return updated;
  }

  @override
  Future<bool> directoryExists(String path) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableScanDirectories} '
      'WHERE ${DatabaseConstants.colPath} = ?',
      [path],
    );
    return (result.first['count'] as int) > 0;
  }

  // Helper methods for mapping between entity and model
  ScanDirectory _mapToEntity(ScanDirectoryModel model) {
    return ScanDirectory(
      id: model.id,
      path: model.path,
      addedDate: model.addedDate,
      lastScannedDate: model.lastScannedDate,
    );
  }

  ScanDirectoryModel _mapToModel(ScanDirectory entity) {
    return ScanDirectoryModel(
      id: entity.id,
      path: entity.path,
      addedDate: entity.addedDate,
      lastScannedDate: entity.lastScannedDate,
    );
  }
}

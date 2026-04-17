import 'dart:async';
import 'dart:developer' as developer;

import 'package:sqflite_common/sqflite.dart';
import 'package:squirrel_play/data/datasources/local/database_constants.dart';
import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/models/game_metadata_model.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata_service.dart';
import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';

/// Concrete implementation of [MetadataRepository].
///
/// Handles CRUD operations for metadata in the local database
/// and coordinates with [MetadataService] and [MetadataAggregator] for API fetching.
class MetadataRepositoryImpl implements MetadataRepository {
  final DatabaseHelper _databaseHelper;
  final MetadataService _metadataService;
  final MetadataAggregator _metadataAggregator;
  final GameRepository _gameRepository;

  /// Stream controller for batch progress updates.
  final _batchProgressController = StreamController<BatchMetadataProgress>.broadcast();

  @override
  Stream<BatchMetadataProgress> get batchProgressStream => _batchProgressController.stream;

  MetadataRepositoryImpl({
    required DatabaseHelper databaseHelper,
    required MetadataService metadataService,
    required MetadataAggregator metadataAggregator,
    required GameRepository gameRepository,
  })  : _databaseHelper = databaseHelper,
        _metadataService = metadataService,
        _metadataAggregator = metadataAggregator,
        _gameRepository = gameRepository;

  @override
  Future<GameMetadata?> getMetadataForGame(String gameId) async {
    final db = await _databaseHelper.database;

    // Query metadata
    final metadataMaps = await db.query(
      DatabaseConstants.tableGameMetadata,
      where: '${DatabaseConstants.colGameId} = ?',
      whereArgs: [gameId],
    );

    if (metadataMaps.isEmpty) {
      return null;
    }

    final metadataModel = GameMetadataModel.fromMap(metadataMaps.first);

    // Query genres
    final genreMaps = await db.query(
      DatabaseConstants.tableGameGenres,
      where: '${DatabaseConstants.colGameId} = ?',
      whereArgs: [gameId],
    );
    final genres = genreMaps.map((m) => m[DatabaseConstants.colGenre] as String).toList();

    // Query screenshots
    final screenshotMaps = await db.query(
      DatabaseConstants.tableGameScreenshots,
      where: '${DatabaseConstants.colGameId} = ?',
      whereArgs: [gameId],
      orderBy: DatabaseConstants.colSortOrder,
    );
    final screenshots = screenshotMaps
        .map((m) => m[DatabaseConstants.colScreenshotUrl] as String)
        .toList();

    return _convertToEntity(metadataModel, genres, screenshots);
  }

  @override
  Future<GameMetadata> fetchAndCacheMetadata(
    String gameId,
    String gameTitle,
  ) async {
    // Get the game to check if it's a Steam game
    final game = await _gameRepository.getGameById(gameId);
    if (game == null) {
      throw Exception('Game not found: $gameId');
    }

    // Check if this is a Steam game by path or existing metadata
    final existingMetadata = await getMetadataForGame(gameId);
    final isSteamGame = _isSteamGame(game, existingMetadata);

    GameMetadata? metadata;

    if (isSteamGame) {
      // For Steam games, use the MetadataAggregator with priority: SteamLocal -> SteamStore -> RAWG
      developer.log(
        'MetadataRepository: Using aggregator for Steam game $gameTitle',
        name: 'MetadataRepositoryImpl',
      );
      metadata = await _metadataAggregator.fetchMetadata(
        game,
        externalId: existingMetadata?.externalId,
      );
    } else {
      // For non-Steam games, use the traditional RAWG-only flow
      developer.log(
        'MetadataRepository: Using RAWG flow for non-Steam game $gameTitle',
        name: 'MetadataRepositoryImpl',
      );
      final match = await _metadataService.findMatch(gameTitle);

      if (match == null) {
        throw Exception('No match found for game: $gameTitle');
      }

      if (!match.isAutoMatch) {
        throw MetadataMatchRequiredException(
          gameId: gameId,
          gameTitle: gameTitle,
          alternatives: match.alternatives,
        );
      }

      metadata = await _metadataService.fetchMetadata(gameId, match.gameId);
    }

    if (metadata == null) {
      throw Exception('Failed to fetch metadata for game: $gameTitle');
    }

    // Cache it
    await saveMetadata(metadata);

    return metadata;
  }

  /// Determines if a game is a Steam game based on executable path or metadata.
  bool _isSteamGame(Game game, GameMetadata? existingMetadata) {
    // Check executable path for Steam pattern
    if (game.executablePath.contains('/steamapps/common/')) {
      return true;
    }
    // Check existing metadata for steam: prefix
    if (existingMetadata?.externalId != null &&
        existingMetadata!.externalId!.startsWith('steam:')) {
      return true;
    }
    return false;
  }

  @override
  Future<List<GameMetadata>> batchFetchMetadata(List<Game> games) async {
    final results = <GameMetadata>[];
    var completed = 0;
    var failed = 0;

    for (var i = 0; i < games.length; i++) {
      final game = games[i];

      // Emit progress
      _batchProgressController.add(BatchMetadataProgress(
        total: games.length,
        completed: completed,
        failed: failed,
        currentGame: game.title,
        isComplete: false,
      ));

      try {
        // Check if already has metadata
        final existing = await getMetadataForGame(game.id);
        if (existing != null) {
          results.add(existing);
          completed++;
          continue;
        }

        // Check if this is a Steam game
        final isSteamGame = _isSteamGame(game, null);

        GameMetadata? metadata;
        if (isSteamGame) {
          // Use aggregator for Steam games
          metadata = await _metadataAggregator.fetchMetadata(game);
        } else {
          // Use traditional flow for non-Steam games
          metadata = await fetchAndCacheMetadata(game.id, game.title);
        }

        if (metadata != null) {
          results.add(metadata);
          completed++;
        } else {
          failed++;
        }
      } on MetadataMatchRequiredException {
        // Low confidence match - count as failed for now
        // User will need to manually match later
        failed++;
      } catch (e) {
        developer.log(
          'MetadataRepository: Error fetching metadata for ${game.title}: $e',
          name: 'MetadataRepositoryImpl',
        );
        failed++;
      }
    }

    // Emit completion
    _batchProgressController.add(BatchMetadataProgress(
      total: games.length,
      completed: completed,
      failed: failed,
      currentGame: null,
      isComplete: true,
    ));

    return results;
  }

  @override
  Future<GameMetadata> updateMetadata(String gameId, String newExternalId) async {
    // Fetch metadata with the new external ID
    final metadata = await _metadataService.fetchMetadata(gameId, newExternalId);

    if (metadata == null) {
      throw Exception('Failed to fetch metadata with ID: $newExternalId');
    }

    // Save the new metadata
    await saveMetadata(metadata);

    return metadata;
  }

  @override
  Future<void> clearMetadata(String gameId) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Delete metadata
      await txn.delete(
        DatabaseConstants.tableGameMetadata,
        where: '${DatabaseConstants.colGameId} = ?',
        whereArgs: [gameId],
      );

      // Delete genres
      await txn.delete(
        DatabaseConstants.tableGameGenres,
        where: '${DatabaseConstants.colGameId} = ?',
        whereArgs: [gameId],
      );

      // Delete screenshots
      await txn.delete(
        DatabaseConstants.tableGameScreenshots,
        where: '${DatabaseConstants.colGameId} = ?',
        whereArgs: [gameId],
      );
    });
  }

  @override
  Future<void> saveMetadata(GameMetadata metadata) async {
    final db = await _databaseHelper.database;
    final model = _convertToModel(metadata);

    await db.transaction((txn) async {
      // Insert or replace metadata
      await txn.insert(
        DatabaseConstants.tableGameMetadata,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Delete existing genres
      await txn.delete(
        DatabaseConstants.tableGameGenres,
        where: '${DatabaseConstants.colGameId} = ?',
        whereArgs: [metadata.gameId],
      );

      // Insert new genres
      for (final genre in metadata.genres) {
        await txn.insert(DatabaseConstants.tableGameGenres, {
          DatabaseConstants.colGameId: metadata.gameId,
          DatabaseConstants.colGenre: genre,
        });
      }

      // Delete existing screenshots
      await txn.delete(
        DatabaseConstants.tableGameScreenshots,
        where: '${DatabaseConstants.colGameId} = ?',
        whereArgs: [metadata.gameId],
      );

      // Insert new screenshots
      for (var i = 0; i < metadata.screenshots.length; i++) {
        await txn.insert(DatabaseConstants.tableGameScreenshots, {
          DatabaseConstants.colGameId: metadata.gameId,
          DatabaseConstants.colScreenshotUrl: metadata.screenshots[i],
          DatabaseConstants.colSortOrder: i,
        });
      }
    });
  }

  @override
  Future<bool> hasMetadata(String gameId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      DatabaseConstants.tableGameMetadata,
      where: '${DatabaseConstants.colGameId} = ?',
      whereArgs: [gameId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  @override
  Future<List<MetadataAlternative>> manualSearch(String query) async {
    return await _metadataService.manualSearch(query);
  }

  /// Converts a database model to a domain entity.
  GameMetadata _convertToEntity(
    GameMetadataModel model,
    List<String> genres,
    List<String> screenshots,
  ) {
    return GameMetadata(
      gameId: model.gameId,
      externalId: model.externalId,
      description: model.description,
      coverImageUrl: model.coverImageUrl,
      heroImageUrl: model.heroImageUrl,
      genres: genres,
      screenshots: screenshots,
      releaseDate: model.releaseDate,
      rating: model.rating,
      developer: model.developer,
      publisher: model.publisher,
      lastFetched: model.lastFetched,
    );
  }

  /// Converts a domain entity to a database model.
  GameMetadataModel _convertToModel(GameMetadata entity) {
    return GameMetadataModel(
      gameId: entity.gameId,
      externalId: entity.externalId,
      description: entity.description,
      coverImageUrl: entity.coverImageUrl,
      heroImageUrl: entity.heroImageUrl,
      releaseDate: entity.releaseDate,
      rating: entity.rating,
      developer: entity.developer,
      publisher: entity.publisher,
      lastFetched: entity.lastFetched,
    );
  }

  /// Disposes resources.
  void dispose() {
    _batchProgressController.close();
  }
}

/// Exception thrown when a match requires manual confirmation.
class MetadataMatchRequiredException implements Exception {
  final String gameId;
  final String gameTitle;
  final List<MetadataAlternative> alternatives;

  MetadataMatchRequiredException({
    required this.gameId,
    required this.gameTitle,
    required this.alternatives,
  });

  @override
  String toString() =>
      'MetadataMatchRequiredException: Low confidence match for $gameTitle';
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:sqflite_common/sqflite.dart';
import 'package:squirrel_play/data/datasources/local/database_constants.dart';
import 'package:squirrel_play/data/datasources/local/database_helper.dart';
import 'package:squirrel_play/data/models/game_metadata_model.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata/rawg_batch_search_service.dart';
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
  final RawgBatchSearchService? _rawgBatchSearchService;

  /// Stream controller for batch progress updates.
  final _batchProgressController = StreamController<BatchMetadataProgress>.broadcast();

  /// Stream controller for metadata change notifications.
  final _metadataChangeController = StreamController<String>.broadcast();

  @override
  Stream<BatchMetadataProgress> get batchProgressStream => _batchProgressController.stream;

  @override
  Stream<String> get metadataChanged => _metadataChangeController.stream;

  MetadataRepositoryImpl({
    required DatabaseHelper databaseHelper,
    required MetadataService metadataService,
    required MetadataAggregator metadataAggregator,
    required GameRepository gameRepository,
    RawgBatchSearchService? rawgBatchSearchService,
  })  : _databaseHelper = databaseHelper,
        _metadataService = metadataService,
        _metadataAggregator = metadataAggregator,
        _gameRepository = gameRepository,
        _rawgBatchSearchService = rawgBatchSearchService;

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

    GameMetadata? metadata;

    try {
      // Use the unified MetadataAggregator strategy:
      // Steam games: SteamLocal -> SteamStore -> RAWG
      // Non-Steam games: RAWG only
      developer.log(
        'MetadataRepository: Fetching metadata for $gameTitle',
        name: 'MetadataRepositoryImpl',
      );
      metadata = await _metadataAggregator.fetchMetadata(
        game,
        externalId: existingMetadata?.externalId,
      );
    } on RawgApiNotConfiguredException {
      // Propagate API not configured so callers can show configuration UI
      rethrow;
    } on MetadataMatchRequiredException {
      // Propagate match-required for manual selection
      rethrow;
    } catch (e) {
      developer.log(
        'MetadataRepository: Metadata fetch failed for $gameTitle: $e',
        name: 'MetadataRepositoryImpl',
      );
    }

    if (metadata != null) {
      // Cache successful fetch
      await saveMetadata(metadata);
      return metadata;
    }

    // All sources failed — save default metadata to avoid repeated fetches
    developer.log(
      'MetadataRepository: Using default metadata for $gameTitle',
      name: 'MetadataRepositoryImpl',
    );
    final defaultMetadata = GameMetadata(
      gameId: gameId,
      title: game.title,
      lastFetched: DateTime.now(),
    );
    await saveMetadata(defaultMetadata);
    return defaultMetadata;
  }

  /// Determines if a game is a Steam game based on executable path or metadata.
  bool _isSteamGame(Game game, GameMetadata? existingMetadata) {
    // Check executable path for Steam pattern
    final normalizedPath = game.executablePath.replaceAll('\\', '/');
    if (normalizedPath.contains('/steamapps/common/')) {
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

    // Pre-check existing metadata and categorize games
    final existingResults = <GameMetadata>[];
    final steamGames = <Game>[];
    final nonSteamGames = <Game>[];

    for (final game in games) {
      final existing = await getMetadataForGame(game.id);
      if (existing != null) {
        existingResults.add(existing);
        completed++;
      } else if (_isSteamGame(game, null)) {
        steamGames.add(game);
      } else {
        nonSteamGames.add(game);
      }
    }

    // Process Steam games one by one
    for (final game in steamGames) {
      _emitProgress(games.length, completed, failed, game.title);
      try {
        final metadata = await _metadataAggregator.fetchMetadata(game);
        if (metadata != null) {
          results.add(metadata);
          completed++;
        } else {
          failed++;
        }
      } catch (e) {
        developer.log(
          'MetadataRepository: Error fetching metadata for ${game.title}: $e',
          name: 'MetadataRepositoryImpl',
        );
        failed++;
      }
    }

    // Batch process non-Steam games
    if (nonSteamGames.isNotEmpty) {
      if (_rawgBatchSearchService != null) {
        final batchResults =
            await _rawgBatchSearchService.searchMultipleGamesSync(
          nonSteamGames.map((g) => g.title).toList(),
        );

        for (var i = 0; i < nonSteamGames.length; i++) {
          final game = nonSteamGames[i];
          final batchResult = batchResults[i];

          _emitProgress(games.length, completed, failed, game.title);

          try {
            if (batchResult.success &&
                batchResult.match != null &&
                batchResult.match!.isAutoMatch) {
              final metadata = await _metadataService.fetchMetadata(
                game.id,
                batchResult.match!.gameId,
              );
              if (metadata != null) {
                await saveMetadata(metadata);
                results.add(metadata);
                completed++;
              } else {
                failed++;
              }
            } else if (batchResult.success &&
                batchResult.match != null &&
                !batchResult.match!.isAutoMatch) {
              throw MetadataMatchRequiredException(
                gameId: game.id,
                gameTitle: game.title,
                alternatives: batchResult.match!.alternatives,
              );
            } else {
              failed++;
            }
          } on MetadataMatchRequiredException {
            failed++;
          } catch (e) {
            developer.log(
              'MetadataRepository: Error fetching metadata for '
              '${game.title}: $e',
              name: 'MetadataRepositoryImpl',
            );
            failed++;
          }
        }
      } else {
        // Fallback: process non-Steam games one by one
        for (final game in nonSteamGames) {
          _emitProgress(games.length, completed, failed, game.title);
          try {
            final metadata = await fetchAndCacheMetadata(game.id, game.title);
            results.add(metadata);
            completed++;
          } on MetadataMatchRequiredException {
            failed++;
          } catch (e) {
            developer.log(
              'MetadataRepository: Error fetching metadata for '
              '${game.title}: $e',
              name: 'MetadataRepositoryImpl',
            );
            failed++;
          }
        }
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

    return [...existingResults, ...results];
  }

  /// Emits a progress update via the batch progress stream.
  void _emitProgress(
    int total,
    int completed,
    int failed,
    String? currentGame,
  ) {
    _batchProgressController.add(BatchMetadataProgress(
      total: total,
      completed: completed,
      failed: failed,
      currentGame: currentGame,
      isComplete: false,
    ));
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

    _metadataChangeController.add(gameId);
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
      title: model.title,
      description: model.description,
      coverImageUrl: model.coverImageUrl,
      cardImageUrl: model.cardImageUrl,
      heroImageUrl: model.heroImageUrl,
      logoImageUrl: model.logoImageUrl,
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
      title: entity.title,
      description: entity.description,
      coverImageUrl: entity.coverImageUrl,
      cardImageUrl: entity.cardImageUrl,
      heroImageUrl: entity.heroImageUrl,
      logoImageUrl: entity.logoImageUrl,
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

/// Exception thrown when the RAWG API is not configured.
class RawgApiNotConfiguredException implements Exception {
  @override
  String toString() => 'RawgApiNotConfiguredException: RAWG API key is not configured';
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

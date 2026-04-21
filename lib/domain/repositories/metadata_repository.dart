import 'dart:async';

import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';

/// Abstract repository interface for metadata operations.
abstract class MetadataRepository {
  /// Gets metadata for a game from local cache.
  ///
  /// [gameId] is the internal game ID.
  /// Returns null if no metadata is cached.
  Future<GameMetadata?> getMetadataForGame(String gameId);

  /// Fetches and caches metadata for a game from the API.
  ///
  /// [gameId] is the internal game ID.
  /// [gameTitle] is the game title for matching.
  /// Returns the fetched metadata.
  Future<GameMetadata> fetchAndCacheMetadata(String gameId, String gameTitle);

  /// Fetches metadata for multiple games with progress callbacks.
  ///
  /// [games] is the list of games to fetch metadata for.
  /// Returns the list of successfully fetched metadata.
  Future<List<GameMetadata>> batchFetchMetadata(List<Game> games);

  /// Updates metadata with a manual external ID override.
  ///
  /// [gameId] is the internal game ID.
  /// [newExternalId] is the new RAWG game ID.
  /// Returns the updated metadata.
  Future<GameMetadata> updateMetadata(String gameId, String newExternalId);

  /// Clears cached metadata for a game.
  ///
  /// [gameId] is the internal game ID.
  Future<void> clearMetadata(String gameId);

  /// Saves metadata to the local cache.
  ///
  /// [metadata] is the metadata to save.
  Future<void> saveMetadata(GameMetadata metadata);

  /// Checks if a game has cached metadata.
  ///
  /// [gameId] is the internal game ID.
  Future<bool> hasMetadata(String gameId);

  /// Stream of batch progress updates.
  Stream<BatchMetadataProgress> get batchProgressStream;

  /// Stream of metadata change notifications.
  ///
  /// Emits the gameId whenever metadata is saved or cleared.
  Stream<String> get metadataChanged;

  /// Performs a manual search for games with a custom query.
  ///
  /// Used when automatic matching fails and user wants to search manually.
  Future<List<MetadataAlternative>> manualSearch(String query);
}

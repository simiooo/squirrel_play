import 'dart:async';
import 'dart:developer' as developer;

import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';
import 'package:squirrel_play/data/services/api_key_service.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';

/// Core service for orchestrating metadata fetching, matching, and caching.
///
/// Coordinates between the metadata aggregator, RAWG source, and repository.
class MetadataService {
  final MetadataAggregator _metadataAggregator;
  final RawgSource _rawgSource;

  /// Stream controller for batch progress updates.
  final _batchProgressController = StreamController<BatchMetadataProgress>.broadcast();

  /// Stream of batch progress updates.
  Stream<BatchMetadataProgress> get batchProgressStream => _batchProgressController.stream;

  MetadataService({
    required ApiKeyService apiKeyService,
    required MetadataAggregator metadataAggregator,
    required RawgSource rawgSource,
  })  : _metadataAggregator = metadataAggregator,
        _rawgSource = rawgSource;

  /// Initializes the service with API client if key is available.
  Future<void> initialize() async {
    // Initialize RAWG source
    await _rawgSource.initialize();
  }

  /// Checks if the RAWG API client is initialized and ready.
  bool get isInitialized => _rawgSource.isInitialized;

  /// Sets a new API key and reinitializes the client.
  Future<void> setApiKey(String apiKey) async {
    await _rawgSource.setApiKey(apiKey);
  }

  /// Finds the best matching game for a filename.
  ///
  /// Returns [MetadataMatchResult] with match details, or null if
  /// no API key is configured or no matches found.
  /// Delegates to RawgSource.findMatch().
  Future<MetadataMatchResult?> findMatch(String filename) async {
    return await _rawgSource.findMatch(filename);
  }

  /// Searches for games manually with a custom query.
  /// Delegates to RawgSource.searchManually().
  Future<List<MetadataAlternative>> manualSearch(String query) async {
    return await _rawgSource.searchManually(query);
  }

  /// Fetches full metadata for a game by its external ID.
  ///
  /// [externalId] is the external game ID (e.g., 'rawg:12345' or 'steam:730').
  /// Returns [GameMetadata] with all details, or null on error.
  ///
  /// Note: This method handles both prefixed IDs (steam:, rawg:) and
  /// plain numeric IDs (backward compatibility with RAWG).
  Future<GameMetadata?> fetchMetadata(String gameId, String externalId) async {
    if (!isInitialized) {
      await initialize();
      if (!isInitialized) return null;
    }

    try {
      // Parse the externalId to determine the source
      if (externalId.startsWith('steam:')) {
        // Steam ID - extract the numeric part
        final steamAppId = externalId.substring('steam:'.length);
        final appIdInt = int.tryParse(steamAppId);
        if (appIdInt == null) {
          developer.log(
            'MetadataService: Invalid Steam app ID: $steamAppId',
            name: 'MetadataService',
          );
          return null;
        }
        // For Steam games, we need a Game object to pass to the aggregator
        // This is a limitation - fetchMetadata is designed for manual selection
        // which typically uses RAWG. For Steam, the aggregator should be used
        // directly with the full Game object.
        developer.log(
          'MetadataService: Steam ID provided ($externalId) but fetchMetadata '
          'requires a Game object. Use MetadataAggregator for Steam games.',
          name: 'MetadataService',
        );
        return null;
      } else if (externalId.startsWith('rawg:')) {
        // RAWG ID with prefix - extract the numeric part
        final rawgId = externalId.substring('rawg:'.length);
        final gameIdInt = int.tryParse(rawgId);
        if (gameIdInt == null) {
          developer.log(
            'MetadataService: Invalid RAWG game ID: $rawgId',
            name: 'MetadataService',
          );
          return null;
        }
        return await _rawgSource.fetchById(gameId, gameIdInt);
      } else {
        // Plain numeric ID - backward compatibility, treat as RAWG
        final gameIdInt = int.tryParse(externalId);
        if (gameIdInt == null) {
          developer.log(
            'MetadataService: Invalid external ID: $externalId',
            name: 'MetadataService',
          );
          return null;
        }
        return await _rawgSource.fetchById(gameId, gameIdInt);
      }
    } catch (e) {
      developer.log(
        'MetadataService: Error fetching metadata: $e',
        name: 'MetadataService',
      );
      return null;
    }
  }

  /// Fetches metadata for multiple games with progress updates.
  ///
  /// Emits progress updates to [batchProgressStream].
  /// Now uses MetadataAggregator for each game.
  Future<List<GameMetadata>> batchFetchMetadata(
    List<Game> games, {
    Map<String, String>? externalIdOverrides,
  }) async {
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
        // Check for override (used for manual metadata selection)
        final externalId = externalIdOverrides?[game.id];

        GameMetadata? metadata;

        if (externalId != null) {
          // Use override ID directly (backward compatibility)
          metadata = await fetchMetadata(game.id, externalId);
        } else {
          // Use the aggregator for automatic fetching
          metadata = await _metadataAggregator.fetchMetadata(game);
        }

        if (metadata != null) {
          results.add(metadata);
          completed++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }

      // Small delay to respect rate limiting
      await Future.delayed(const Duration(milliseconds: 200));
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

  /// Disposes resources.
  void dispose() {
    _batchProgressController.close();
  }
}

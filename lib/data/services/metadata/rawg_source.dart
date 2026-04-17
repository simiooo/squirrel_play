import 'dart:developer' as developer;

import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';
import 'package:squirrel_play/data/services/api_key_service.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/metadata_matching_engine.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';

/// Metadata source for RAWG API.
///
/// Wraps the existing MetadataMatchingEngine and RawgApiClient
/// to provide metadata from RAWG.
class RawgSource implements MetadataSource {
  final ApiKeyService _apiKeyService;
  RawgApiClient? _apiClient;
  MetadataMatchingEngine? _matchingEngine;

  /// Gets the API client for direct access (used by MetadataService for backward compatibility).
  RawgApiClient? get apiClient => _apiClient;

  RawgSource({
    required ApiKeyService apiKeyService,
  }) : _apiKeyService = apiKeyService;

  /// Initializes the source with API client if key is available.
  Future<void> initialize() async {
    final apiKey = await _apiKeyService.getApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _initializeClient(apiKey);
    }
  }

  /// Sets a new API key and reinitializes the client.
  Future<void> setApiKey(String apiKey) async {
    await _apiKeyService.saveApiKey(apiKey);
    _initializeClient(apiKey);
  }

  /// Initializes the API client with the given key.
  void _initializeClient(String apiKey) {
    _apiClient = RawgApiClient(apiKey: apiKey);
    _matchingEngine = MetadataMatchingEngine(apiClient: _apiClient!);
  }

  /// Checks if the API client is initialized and ready.
  bool get isInitialized => _apiClient != null && _matchingEngine != null;

  @override
  MetadataSourceType get sourceType => MetadataSourceType.rawg;

  @override
  String get displayName => 'RAWG';

  @override
  Future<bool> canProvide(Game game, {String? externalId}) async {
    // RAWG can provide metadata for any game if API key is configured
    if (!isInitialized) {
      await initialize();
    }
    return isInitialized;
  }

  @override
  Future<GameMetadata?> fetch(Game game, {String? externalId}) async {
    if (!isInitialized) {
      await initialize();
      if (!isInitialized) {
        developer.log(
          'RawgSource: Not initialized - no API key',
          name: 'RawgSource',
        );
        return null;
      }
    }

    try {
      // Find a match for the game
      final filename = game.executablePath.split('/').last;
      final match = await _matchingEngine!.findBestMatch(filename);

      if (match == null || !match.isAutoMatch) {
        developer.log(
          'RawgSource: No auto-match found for ${game.title}',
          name: 'RawgSource',
        );
        return null;
      }

      // Fetch full metadata
      final gameIdInt = int.parse(match.gameId);

      final results = await Future.wait([
        _apiClient!.getGameDetails(gameIdInt),
        _apiClient!.getGameScreenshots(gameIdInt),
      ]);

      final details = results[0] as GameDetailResponse;
      final screenshots = results[1] as List<Screenshot>;

      developer.log(
        'RawgSource: Fetched metadata for ${game.title} (id: ${match.gameId})',
        name: 'RawgSource',
      );

      return _convertToGameMetadata(
        gameId: game.id,
        gameIdInt: gameIdInt,
        details: details,
        screenshots: screenshots,
      );
    } catch (e) {
      developer.log(
        'RawgSource: Error fetching metadata for ${game.title}: $e',
        name: 'RawgSource',
      );
      return null;
    }
  }

  /// Finds the best matching game for a filename.
  ///
  /// Returns [MetadataMatchResult] with match details, or null if
  /// no API key is configured or no matches found.
  Future<MetadataMatchResult?> findMatch(String filename) async {
    if (!isInitialized) {
      await initialize();
      if (!isInitialized) return null;
    }

    return await _matchingEngine!.findBestMatch(filename);
  }

  /// Searches for games manually with a custom query.
  Future<List<MetadataAlternative>> searchManually(String query) async {
    if (!isInitialized) {
      await initialize();
      if (!isInitialized) return [];
    }

    return await _matchingEngine!.searchManually(query);
  }

  /// Fetches metadata for a game by its RAWG game ID.
  ///
  /// [gameId] is the internal game ID.
  /// [rawgGameId] is the RAWG game ID.
  /// Returns [GameMetadata] or null on error.
  Future<GameMetadata?> fetchById(String gameId, int rawgGameId) async {
    if (!isInitialized) {
      await initialize();
      if (!isInitialized) return null;
    }

    try {
      final results = await Future.wait([
        _apiClient!.getGameDetails(rawgGameId),
        _apiClient!.getGameScreenshots(rawgGameId),
      ]);

      final details = results[0] as GameDetailResponse;
      final screenshots = results[1] as List<Screenshot>;

      return _convertToGameMetadata(
        gameId: gameId,
        gameIdInt: rawgGameId,
        details: details,
        screenshots: screenshots,
      );
    } catch (e) {
      developer.log(
        'RawgSource: Error fetching metadata by ID for $gameId: $e',
        name: 'RawgSource',
      );
      return null;
    }
  }

  /// Converts API response to domain entity.
  GameMetadata _convertToGameMetadata({
    required String gameId,
    required int gameIdInt,
    required GameDetailResponse details,
    required List<Screenshot> screenshots,
  }) {
    return GameMetadata(
      gameId: gameId,
      externalId: 'rawg:$gameIdInt',
      description: details.descriptionRaw ?? details.description,
      coverImageUrl: details.backgroundImage,
      heroImageUrl: details.backgroundImageAdditional ?? details.backgroundImage,
      genres: details.genres?.map((g) => g.name).toList() ?? [],
      screenshots: screenshots.map((s) => s.url).toList(),
      releaseDate: details.released != null
          ? DateTime.tryParse(details.released!)
          : null,
      rating: details.rating,
      developer: details.developers?.firstOrNull?.name,
      publisher: details.publishers?.firstOrNull?.name,
      lastFetched: DateTime.now(),
    );
  }
}

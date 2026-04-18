import 'dart:developer' as developer;

import 'package:squirrel_play/data/services/metadata/steam_local_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_store_source.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

/// Coordinates SteamLocalSource and SteamStoreSource to import and refresh
/// Steam game metadata.
///
/// Constructs CDN URLs for all Steam image types and merges sparse local
/// metadata with rich store metadata. Does not implement [MetadataSource];
/// it is used directly by [MetadataAggregator].
class SteamMetadataAdapter {
  final SteamLocalSource _steamLocalSource;
  final SteamStoreSource _steamStoreSource;

  SteamMetadataAdapter({
    required SteamLocalSource steamLocalSource,
    required SteamStoreSource steamStoreSource,
  })  : _steamLocalSource = steamLocalSource,
        _steamStoreSource = steamStoreSource;

  /// Imports complete metadata for a Steam game (initial discovery).
  ///
  /// Returns null for non-Steam games or when no appId can be determined.
  Future<GameMetadata?> importMetadata(Game game) async {
    if (!_isSteamGame(game)) {
      return null;
    }

    try {
      // Step 1: Get sparse metadata from local source
      final localMetadata = await _steamLocalSource.fetch(game);

      // Step 2: Extract appId from local metadata or game path
      final appId = _extractAppId(localMetadata, game);

      // Step 3: Apply rate limiting before store call
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 4: Fetch rich metadata from store source
      GameMetadata? storeMetadata;
      if (appId != null) {
        storeMetadata = await _steamStoreSource.fetch(
          game,
          externalId: 'steam:$appId',
        );
      } else {
        // Try store source without externalId (it may extract from path)
        storeMetadata = await _steamStoreSource.fetch(game);
      }

      // Step 5: Determine final appId (from local, path, or store result)
      final finalAppId = appId ?? _extractAppIdFromExternalId(storeMetadata);

      // If we have no appId and both sources returned null, nothing to return
      if (finalAppId == null && localMetadata == null && storeMetadata == null) {
        return null;
      }

      // Step 6: Merge metadata
      return _mergeMetadata(
        gameId: game.id,
        appId: finalAppId,
        local: localMetadata,
        store: storeMetadata,
      );
    } catch (e) {
      developer.log(
        'SteamMetadataAdapter: Error importing metadata for ${game.title}: $e',
        name: 'SteamMetadataAdapter',
      );
      return null;
    }
  }

  /// Re-fetches and returns updated metadata for a Steam game (refresh).
  ///
  /// Guarantees a fresh fetch from both sources and returns a new
  /// [GameMetadata] with updated [lastFetched].
  Future<GameMetadata?> refreshMetadata(Game game) async {
    // Refresh is identical to import - both sources are called anew
    return importMetadata(game);
  }

  /// Determines if a game is a Steam game based on executable path.
  bool _isSteamGame(Game game) {
    return game.executablePath.contains('/steamapps/common/');
  }

  /// Extracts the Steam app ID from local metadata or the game path.
  String? _extractAppId(GameMetadata? localMetadata, Game game) {
    // First check local metadata externalId
    if (localMetadata?.externalId != null &&
        localMetadata!.externalId!.startsWith('steam:')) {
      return localMetadata.externalId!.substring('steam:'.length);
    }

    // Fall back to path extraction
    return _extractAppIdFromPath(game.executablePath);
  }

  /// Extracts appId from a metadata object's externalId.
  String? _extractAppIdFromExternalId(GameMetadata? metadata) {
    if (metadata?.externalId != null &&
        metadata!.externalId!.startsWith('steam:')) {
      return metadata.externalId!.substring('steam:'.length);
    }
    return null;
  }

  /// Extracts appId from executable path using regex patterns.
  String? _extractAppIdFromPath(String path) {
    // Look for appmanifest pattern in path
    final appIdPattern = RegExp(r'appmanifest_(\d+)\.acf');
    final match = appIdPattern.firstMatch(path);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  /// Merges local and store metadata into a single [GameMetadata].
  ///
  /// CDN URLs take priority for image fields when [appId] is known.
  GameMetadata _mergeMetadata({
    required String gameId,
    required String? appId,
    required GameMetadata? local,
    required GameMetadata? store,
  }) {
    // Construct CDN URLs if appId is known
    String? cardImageUrl;
    String? coverImageUrl;
    String? heroImageUrl;
    String? logoImageUrl;

    if (appId != null) {
      final cdnBase = 'https://cdn.akamai.steamstatic.com/steam/apps/$appId';
      cardImageUrl = '$cdnBase/header.jpg';
      coverImageUrl = '$cdnBase/library_600x900.jpg';
      heroImageUrl = '$cdnBase/library_hero.jpg';
      logoImageUrl = '$cdnBase/logo.png';
    }

    // Use store data for fields, falling back to local where appropriate
    return GameMetadata(
      gameId: gameId,
      externalId: appId != null ? 'steam:$appId' : (store?.externalId ?? local?.externalId),
      title: store?.title,
      description: store?.description ?? local?.description,
      // CDN URLs take priority; fall back to store images when appId unavailable
      coverImageUrl: coverImageUrl ?? store?.coverImageUrl,
      cardImageUrl: cardImageUrl ?? store?.coverImageUrl,
      heroImageUrl: heroImageUrl ?? store?.heroImageUrl,
      logoImageUrl: logoImageUrl,
      genres: store?.genres ?? local?.genres ?? const [],
      screenshots: store?.screenshots ?? local?.screenshots ?? const [],
      releaseDate: store?.releaseDate ?? local?.releaseDate,
      developer: store?.developer ?? local?.developer,
      publisher: store?.publisher ?? local?.publisher,
      lastFetched: DateTime.now(),
    );
  }
}

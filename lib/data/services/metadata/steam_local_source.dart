import 'dart:developer' as developer;

import 'package:squirrel_play/data/services/metadata/metadata_source.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

/// Metadata source for Steam local manifest data.
///
/// Provides sparse metadata (name + CDN images) from Steam's local files.
/// Full metadata requires SteamStoreSource as a fallback.
class SteamLocalSource implements MetadataSource {
  final SteamManifestParser _manifestParser;

  SteamLocalSource({
    required SteamManifestParser manifestParser,
  }) : _manifestParser = manifestParser;

  @override
  MetadataSourceType get sourceType => MetadataSourceType.steamLocal;

  @override
  String get displayName => 'Steam Local';

  @override
  Future<bool> canProvide(Game game, {String? externalId}) async {
    // Check if game has existing metadata with steam: prefix
    if (externalId != null && externalId.startsWith('steam:')) {
      return true;
    }
    // Fall back to checking the executable path pattern
    return _isSteamGame(game);
  }

  /// Determines if a game is a Steam game based on executable path.
  bool _isSteamGame(Game game) {
    final normalizedPath = game.executablePath.replaceAll('\\', '/');
    return normalizedPath.contains('/steamapps/common/');
  }

  @override
  Future<GameMetadata?> fetch(Game game, {String? externalId}) async {
    if (!_isSteamGame(game) && (externalId == null || !externalId.startsWith('steam:'))) {
      return null;
    }

    try {
      final appId = await _extractAppId(game, externalId: externalId);
      if (appId == null) {
        developer.log(
          'SteamLocalSource: Could not extract appId for ${game.title}',
          name: 'SteamLocalSource',
        );
        return null;
      }

      // Construct CDN URLs
      final coverImageUrl =
          'https://cdn.akamai.steamstatic.com/steam/apps/$appId/header.jpg';
      final heroImageUrl =
          'https://cdn.akamai.steamstatic.com/steam/apps/$appId/library_hero.jpg';

      developer.log(
        'SteamLocalSource: Fetched metadata for ${game.title} (appId: $appId)',
        name: 'SteamLocalSource',
      );

      return GameMetadata(
        gameId: game.id,
        externalId: 'steam:$appId',
        description: null, // Sparse - SteamStoreSource provides this
        coverImageUrl: coverImageUrl,
        heroImageUrl: heroImageUrl,
        genres: const [], // Sparse - SteamStoreSource provides this
        screenshots: const [], // Sparse - SteamStoreSource provides this
        lastFetched: DateTime.now(),
      );
    } catch (e) {
      developer.log(
        'SteamLocalSource: Error fetching metadata for ${game.title}: $e',
        name: 'SteamLocalSource',
      );
      return null;
    }
  }

  /// Extracts the Steam app ID from the game.
  ///
  /// First checks if the game has existing metadata with steam: prefix,
  /// then falls back to extracting from the executable path.
  Future<String?> _extractAppId(Game game, {String? externalId}) async {
    // First check if externalId has steam: prefix
    if (externalId != null && externalId.startsWith('steam:')) {
      return externalId.substring('steam:'.length);
    }

    // Try to extract from executable path by finding the corresponding manifest
    final path = game.executablePath.replaceAll('\\', '/');

    // Parse the path to find the steamapps directory
    final steamappsIndex = path.indexOf('/steamapps/common/');
    if (steamappsIndex == -1) {
      return null;
    }

    final libraryPath = path.substring(0, steamappsIndex);
    final installDir = path
        .substring(steamappsIndex + '/steamapps/common/'.length)
        .split('/')
        .first;

    // Scan the library to find the manifest for this install dir
    final manifests = await _manifestParser.scanLibrary(libraryPath);

    for (final manifest in manifests) {
      if (manifest.installDir == installDir) {
        return manifest.appId;
      }
    }

    return null;
  }
}

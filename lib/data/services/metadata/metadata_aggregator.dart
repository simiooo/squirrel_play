import 'dart:developer' as developer;

import 'package:squirrel_play/data/services/metadata/metadata_source.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_metadata_adapter.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

/// Orchestrates multiple metadata sources with priority-based fetching.
///
/// For Steam games: tries SteamMetadataAdapter -> RawgSource
/// For non-Steam games: tries RawgSource only
class MetadataAggregator {
  final SteamMetadataAdapter _steamMetadataAdapter;
  final RawgSource _rawgSource;

  MetadataAggregator({
    required SteamMetadataAdapter steamMetadataAdapter,
    required RawgSource rawgSource,
  })  : _steamMetadataAdapter = steamMetadataAdapter,
        _rawgSource = rawgSource;

  /// Fetches metadata by trying sources in priority order.
  ///
  /// [externalId] is the optional existing external ID from game metadata
  /// (e.g., 'steam:730' or 'rawg:12345'). Used to determine which sources
  /// can provide metadata for this game.
  ///
  /// Returns null if all sources fail.
  Future<GameMetadata?> fetchMetadata(Game game, {String? externalId}) async {
    final isSteam = _isSteamGame(game) ||
        (externalId != null && externalId.startsWith('steam:'));

    developer.log(
      'MetadataAggregator: Fetching metadata for ${game.title} (Steam: $isSteam)',
      name: 'MetadataAggregator',
    );

    // For Steam games, try the adapter first
    if (isSteam) {
      try {
        developer.log(
          'MetadataAggregator: Trying SteamMetadataAdapter...',
          name: 'MetadataAggregator',
        );
        final metadata = await _steamMetadataAdapter.importMetadata(game);
        if (metadata != null) {
          // Check if Steam metadata is complete
          if (_isCompleteMetadata(metadata)) {
            developer.log(
              'MetadataAggregator: SteamMetadataAdapter succeeded '
              'with complete metadata',
              name: 'MetadataAggregator',
            );
            return metadata;
          }

          // Steam metadata is incomplete - try to fill in from RAWG
          developer.log(
            'MetadataAggregator: Steam metadata incomplete '
            '(missing description or images), falling back to RAWG...',
            name: 'MetadataAggregator',
          );

          try {
            final rawgMetadata = await _rawgSource.fetch(game);
            if (rawgMetadata != null) {
              final merged = _mergeMetadata(primary: metadata, fallback: rawgMetadata);
              developer.log(
                'MetadataAggregator: Merged Steam + RAWG metadata',
                name: 'MetadataAggregator',
              );
              return merged;
            }
          } catch (e) {
            developer.log(
              'MetadataAggregator: RAWG fallback failed: $e',
              name: 'MetadataAggregator',
            );
          }

          // RAWG fallback failed, return incomplete Steam metadata
          developer.log(
            'MetadataAggregator: Returning incomplete Steam metadata',
            name: 'MetadataAggregator',
          );
          return metadata;
        }
        developer.log(
          'MetadataAggregator: SteamMetadataAdapter returned null, '
          'falling back to RAWG...',
          name: 'MetadataAggregator',
        );
      } catch (e) {
        developer.log(
          'MetadataAggregator: SteamMetadataAdapter failed with error: $e',
          name: 'MetadataAggregator',
        );
      }
    }

    // Fall back to RAWG for non-Steam games or when adapter fails
    final sources = _getSourcePriorityList();

    for (final source in sources) {
      try {
        final canProvide = await source.canProvide(game, externalId: externalId);
        if (!canProvide) {
          developer.log(
            'MetadataAggregator: ${source.displayName} cannot provide metadata',
            name: 'MetadataAggregator',
          );
          continue;
        }

        developer.log(
          'MetadataAggregator: Trying ${source.displayName}...',
          name: 'MetadataAggregator',
        );

        final metadata = await source.fetch(game, externalId: externalId);

        if (metadata != null) {
          developer.log(
            'MetadataAggregator: ${source.displayName} succeeded',
            name: 'MetadataAggregator',
          );
          return metadata;
        }

        developer.log(
          'MetadataAggregator: ${source.displayName} returned null, trying next...',
          name: 'MetadataAggregator',
        );
      } catch (e) {
        developer.log(
          'MetadataAggregator: ${source.displayName} failed with error: $e',
          name: 'MetadataAggregator',
        );
        // Continue to next source
      }
    }

    developer.log(
      'MetadataAggregator: All sources failed for ${game.title}',
      name: 'MetadataAggregator',
    );
    return null;
  }

  /// Determines if a game is a Steam game based on executable path.
  bool _isSteamGame(Game game) {
    return game.executablePath.contains('/steamapps/common/');
  }

  /// Checks if metadata is considered complete.
  ///
  /// Metadata is incomplete if it is missing a description
  /// or missing both card and cover image URLs.
  bool _isCompleteMetadata(GameMetadata metadata) {
    final hasDescription =
        metadata.description != null && metadata.description!.isNotEmpty;
    final hasImages = (metadata.cardImageUrl != null &&
            metadata.cardImageUrl!.isNotEmpty) ||
        (metadata.coverImageUrl != null && metadata.coverImageUrl!.isNotEmpty);
    return hasDescription && hasImages;
  }

  /// Merges two metadata objects, keeping primary fields and filling
  /// in missing ones from fallback.
  ///
  /// Treats null or empty string as missing for text fields.
  GameMetadata _mergeMetadata({
    required GameMetadata primary,
    required GameMetadata fallback,
  }) {
    String? coalesce(String? primary, String? fallback) {
      if (primary != null && primary.isNotEmpty) return primary;
      if (fallback != null && fallback.isNotEmpty) return fallback;
      return null;
    }

    return GameMetadata(
      gameId: primary.gameId,
      externalId: primary.externalId,
      title: coalesce(primary.title, fallback.title),
      description: coalesce(primary.description, fallback.description),
      coverImageUrl: coalesce(primary.coverImageUrl, fallback.coverImageUrl),
      cardImageUrl: coalesce(primary.cardImageUrl, fallback.cardImageUrl),
      heroImageUrl: coalesce(primary.heroImageUrl, fallback.heroImageUrl),
      logoImageUrl: coalesce(primary.logoImageUrl, fallback.logoImageUrl),
      genres: primary.genres.isNotEmpty ? primary.genres : fallback.genres,
      screenshots: primary.screenshots.isNotEmpty
          ? primary.screenshots
          : fallback.screenshots,
      releaseDate: primary.releaseDate ?? fallback.releaseDate,
      rating: primary.rating ?? fallback.rating,
      developer: coalesce(primary.developer, fallback.developer),
      publisher: coalesce(primary.publisher, fallback.publisher),
      lastFetched: DateTime.now(),
    );
  }

  /// Returns the prioritized list of sources.
  ///
  /// Steam games are handled separately by [_steamMetadataAdapter], so this
  /// list only contains fallback sources.
  List<MetadataSource> _getSourcePriorityList() {
    return [_rawgSource];
  }
}

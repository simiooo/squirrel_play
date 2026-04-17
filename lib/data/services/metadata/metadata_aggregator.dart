import 'dart:developer' as developer;

import 'package:squirrel_play/data/services/metadata/metadata_source.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_local_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_store_source.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

/// Orchestrates multiple metadata sources with priority-based fetching.
///
/// For Steam games: tries SteamLocalSource -> SteamStoreSource -> RawgSource
/// For non-Steam games: tries RawgSource only
class MetadataAggregator {
  final SteamLocalSource _steamLocalSource;
  final SteamStoreSource _steamStoreSource;
  final RawgSource _rawgSource;

  MetadataAggregator({
    required SteamLocalSource steamLocalSource,
    required SteamStoreSource steamStoreSource,
    required RawgSource rawgSource,
  })  : _steamLocalSource = steamLocalSource,
        _steamStoreSource = steamStoreSource,
        _rawgSource = rawgSource;

  /// Fetches metadata by trying sources in priority order.
  ///
  /// [externalId] is the optional existing external ID from game metadata
  /// (e.g., 'steam:730' or 'rawg:12345'). Used to determine which sources
  /// can provide metadata for this game.
  ///
  /// Returns null if all sources fail.
  Future<GameMetadata?> fetchMetadata(Game game, {String? externalId}) async {
    final isSteam = _isSteamGame(game) || (externalId != null && externalId.startsWith('steam:'));
    final sources = _getSourcePriorityList(isSteam);

    developer.log(
      'MetadataAggregator: Fetching metadata for ${game.title} (Steam: $isSteam)',
      name: 'MetadataAggregator',
    );

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

  /// Returns the prioritized list of sources based on game type.
  List<MetadataSource> _getSourcePriorityList(bool isSteamGame) {
    if (isSteamGame) {
      // For Steam games: prioritize Steam sources
      return [_steamLocalSource, _steamStoreSource, _rawgSource];
    } else {
      // For non-Steam games: only use RAWG
      return [_rawgSource];
    }
  }
}

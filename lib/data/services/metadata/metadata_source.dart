import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';

/// Abstract interface for metadata sources.
///
/// Implementations provide metadata from different sources
/// (Steam local manifest, Steam Store API, RAWG API, etc.)
abstract class MetadataSource {
  /// Unique identifier for this source.
  MetadataSourceType get sourceType;

  /// Whether this source can provide metadata for the given game.
  ///
  /// For Steam sources, checks if executablePath contains '/steamapps/common/'
  /// or if externalId starts with 'steam:'.
  ///
  /// [externalId] is the optional existing external ID from game metadata
  /// (e.g., 'steam:730' or 'rawg:12345').
  Future<bool> canProvide(Game game, {String? externalId});

  /// Fetches metadata from this source.
  ///
  /// [externalId] is the optional existing external ID from game metadata
  /// (e.g., 'steam:730' or 'rawg:12345').
  ///
  /// Returns null if metadata cannot be fetched.
  Future<GameMetadata?> fetch(Game game, {String? externalId});

  /// Human-readable name for UI display.
  String get displayName;
}

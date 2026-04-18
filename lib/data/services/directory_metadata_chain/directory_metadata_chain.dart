import 'package:squirrel_play/data/services/directory_metadata_chain/default_metadata_handler.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/steam_directory_handler.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';

/// Builder class that wires the metadata chain of responsibility.
///
/// Creates the handler chain in the correct order:
/// [SteamDirectoryHandler] → [DefaultMetadataHandler]
class DirectoryMetadataChain {
  DirectoryMetadataChain._();

  /// Builds and returns the head of the metadata handler chain.
  ///
  /// The chain order is:
  /// 1. [SteamDirectoryHandler] — detects Steam library paths and parses manifests
  /// 2. [DefaultMetadataHandler] — falls back to filename-based title generation
  static GameMetadataHandler build({
    required SteamManifestParser manifestParser,
  }) {
    final steamHandler = SteamDirectoryHandler(
      manifestParser: manifestParser,
    );
    final defaultHandler = DefaultMetadataHandler();

    steamHandler.setNext(defaultHandler);

    return steamHandler;
  }
}

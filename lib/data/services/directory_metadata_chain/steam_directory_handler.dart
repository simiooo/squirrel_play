import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';

/// Handler that detects Steam library directories and extracts
/// official game metadata from appmanifest files.
///
/// Checks if the executable resides under a `steamapps/common/` path.
/// If so, it scans the Steam library for manifests and matches the
/// executable against manifest [possibleExecutablePaths].
class SteamDirectoryHandler extends GameMetadataHandler {
  final SteamManifestParser _manifestParser;

  /// Creates a [SteamDirectoryHandler] with the given [manifestParser].
  SteamDirectoryHandler({
    required SteamManifestParser manifestParser,
  }) : _manifestParser = manifestParser;

  @override
  Future<void> handle(DirectoryContext context) async {
    final normalizedDir = _normalizePath(context.directoryPath);

    // Check if this is inside a steamapps/common/ directory
    final steamappsIndex = _indexOfCaseInsensitive(normalizedDir, 'steamapps/common/');
    if (steamappsIndex == -1) {
      await super.handle(context);
      return;
    }

    // Extract the library path (everything before steamapps/)
    var libraryPath = normalizedDir.substring(0, steamappsIndex);
    // Trim trailing separator if present
    if (libraryPath.endsWith('/')) {
      libraryPath = libraryPath.substring(0, libraryPath.length - 1);
    }

    // Scan the library for manifests
    final manifests = await _manifestParser.scanLibrary(libraryPath);

    // Try to find a manifest whose possibleExecutablePaths contains our executable
    for (final manifest in manifests) {
      final normalizedExecutable = _normalizePath(context.executablePath);
      final normalizedPaths = manifest.possibleExecutablePaths.map(_normalizePath);

      if (normalizedPaths.contains(normalizedExecutable)) {
        context.title = manifest.name;
        context.steamAppId = manifest.appId;
        return; // Handled — do not pass to next handler
      }
    }

    // No matching manifest found — pass to next handler
    await super.handle(context);
  }

  /// Normalizes path separators to forward slashes for comparison.
  String _normalizePath(String input) {
    return input.replaceAll('\\', '/').toLowerCase();
  }

  /// Case-insensitive index of [pattern] within [source].
  /// Returns -1 if not found.
  int _indexOfCaseInsensitive(String source, String pattern) {
    final lowerSource = source.toLowerCase();
    final lowerPattern = pattern.toLowerCase();
    return lowerSource.indexOf(lowerPattern);
  }
}

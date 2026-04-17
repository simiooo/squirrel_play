import 'dart:convert';
import 'dart:io';

import 'package:squirrel_play/core/services/platform_info.dart';

/// Data class representing a parsed Steam app manifest.
class SteamManifestData {
  /// Steam application ID.
  final String appId;

  /// Game name.
  final String name;

  /// Installation directory name (within steamapps/common/).
  final String installDir;

  /// Library path where this game is installed.
  final String libraryPath;

  /// Installation size in bytes (StagingSize field).
  final int? installSize;

  /// List of possible executable paths found in the install directory.
  final List<String> possibleExecutablePaths;

  /// Platform path separator.
  final String pathSeparator;

  /// Creates a SteamManifestData instance.
  const SteamManifestData({
    required this.appId,
    required this.name,
    required this.installDir,
    required this.libraryPath,
    this.installSize,
    this.possibleExecutablePaths = const [],
    required this.pathSeparator,
  });

  /// Full installation path.
  String get installPath {
    return '$libraryPath${pathSeparator}steamapps${pathSeparator}common$pathSeparator$installDir';
  }

  /// Primary executable (first in the list) or null if none found.
  String? get primaryExecutable =>
      possibleExecutablePaths.isNotEmpty ? possibleExecutablePaths.first : null;

  /// Whether the game appears to be installed (has at least one executable).
  bool get isInstalled => possibleExecutablePaths.isNotEmpty;

  /// Creates a copy with the given fields replaced.
  SteamManifestData copyWith({
    String? appId,
    String? name,
    String? installDir,
    String? libraryPath,
    int? installSize,
    List<String>? possibleExecutablePaths,
    String? pathSeparator,
  }) {
    return SteamManifestData(
      appId: appId ?? this.appId,
      name: name ?? this.name,
      installDir: installDir ?? this.installDir,
      libraryPath: libraryPath ?? this.libraryPath,
      installSize: installSize ?? this.installSize,
      possibleExecutablePaths:
          possibleExecutablePaths ?? this.possibleExecutablePaths,
      pathSeparator: pathSeparator ?? this.pathSeparator,
    );
  }
}

/// Parser for Steam's appmanifest_*.acf files.
///
/// Extracts game information and discovers executables across platforms.
class SteamManifestParser {
  final PlatformInfo _platformInfo;

  /// Creates a SteamManifestParser with required dependencies.
  SteamManifestParser({
    required PlatformInfo platformInfo,
  }) : _platformInfo = platformInfo;

  /// Scans a library folder for all installed games.
  ///
  /// Returns a list of SteamManifestData for all found games.
  Future<List<SteamManifestData>> scanLibrary(String libraryPath) async {
    final manifests = <SteamManifestData>[];
    final steamappsPath = _joinPath(libraryPath, 'steamapps');
    final steamappsDir = Directory(steamappsPath);

    if (!await steamappsDir.exists()) {
      return manifests;
    }

    try {
      await for (final entity in steamappsDir.list()) {
        if (entity is File) {
          final fileName = entity.path.split(_platformInfo.pathSeparator).last;

          // Look for appmanifest_*.acf files
          if (fileName.startsWith('appmanifest_') &&
              fileName.endsWith('.acf')) {
            final manifest = await _parseManifestFile(
              entity.path,
              libraryPath,
            );
            if (manifest != null) {
              manifests.add(manifest);
            }
          }
        }
      }
    } catch (e) {
      // Log error but return what we found
    }

    return manifests;
  }

  /// Parses a single appmanifest file.
  ///
  /// Returns SteamManifestData or null if parsing fails.
  Future<SteamManifestData?> _parseManifestFile(
    String filePath,
    String libraryPath,
  ) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Remove BOM if present
      var contentBytes = bytes;
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        contentBytes = bytes.sublist(3);
      }

      // Decode content
      String content;
      try {
        content = utf8.decode(contentBytes);
      } catch (e) {
        content = latin1.decode(contentBytes);
      }

      // Normalize line endings
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // Extract fields
      final appId = _extractValue(content, 'appid');
      final name = _extractValue(content, 'name');
      final installDir = _extractValue(content, 'installdir');
      final stagingSizeStr = _extractValue(content, 'StagingSize');

      if (appId == null || name == null || installDir == null) {
        return null;
      }

      final installSize =
          stagingSizeStr != null ? int.tryParse(stagingSizeStr) : null;

      // Discover executables - build path: libraryPath/steamapps/common/installDir
      final commonPath = _joinPath(_joinPath(libraryPath, 'steamapps'), 'common');
      final installPath = _joinPath(commonPath, installDir);
      final executables = await _discoverExecutables(installPath);

      return SteamManifestData(
        appId: appId,
        name: name,
        installDir: installDir,
        libraryPath: libraryPath,
        installSize: installSize,
        possibleExecutablePaths: executables,
        pathSeparator: _platformInfo.pathSeparator,
      );
    } catch (e) {
      return null;
    }
  }

  /// Extracts a value from ACF content.
  ///
  /// Pattern: "key" "value"
  String? _extractValue(String content, String key) {
    final pattern = RegExp('"$key"\\s*"([^"]*)"', caseSensitive: false);
    final match = pattern.firstMatch(content);
    return match?.group(1);
  }

  /// Discovers executable files in the install directory.
  ///
  /// Platform-specific logic:
  /// - Windows: .exe files
  /// - Linux: files without extension with executable permissions
  /// - macOS: .app bundles or executables
  Future<List<String>> _discoverExecutables(String installPath) async {
    final executables = <String>[];
    final installDir = Directory(installPath);

    if (!await installDir.exists()) {
      return executables;
    }

    try {
      if (_platformInfo.isWindows) {
        // On Windows: look for .exe files
        await for (final entity in installDir.list(recursive: true)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.exe')) {
              // Skip common non-game executables
              final fileName = path.split(_platformInfo.pathSeparator).last;
              if (!_shouldSkipExecutable(fileName)) {
                executables.add(entity.path);
              }
            }
          }
        }
      } else if (_platformInfo.isLinux) {
        // On Linux: look for executable files (no extension, has execute permission)
        await for (final entity in installDir.list(recursive: true)) {
          if (entity is File) {
            final fileName = entity.path.split(_platformInfo.pathSeparator).last;
            // Skip files with common non-executable extensions
            if (_hasExecutableExtension(fileName)) {
              continue;
            }
            // Check if file has executable permission
            try {
              final stat = await entity.stat();
              // Check if any execute bit is set (owner, group, or other)
              final mode = stat.mode;
              if ((mode & 0x49) != 0) {
                // 0x49 = 0o111 (owner, group, other execute bits)
                if (!_shouldSkipExecutable(fileName.toLowerCase())) {
                  executables.add(entity.path);
                }
              }
            } catch (e) {
              // Skip files we can't stat
            }
          }
        }
      } else if (_platformInfo.isMacOS) {
        // On macOS: look for .app bundles and executables
        await for (final entity in installDir.list(recursive: true)) {
          if (entity is Directory) {
            // Check for .app bundles
            if (entity.path.endsWith('.app')) {
              // Find the actual executable inside the bundle
              final executablePath = await _findMacOSAppExecutable(entity.path);
              if (executablePath != null) {
                executables.add(executablePath);
              }
            }
          } else if (entity is File) {
            // Also check for plain executables
            final fileName = entity.path.split(_platformInfo.pathSeparator).last;
            if (!_hasExecutableExtension(fileName)) {
              try {
                final stat = await entity.stat();
                if ((stat.mode & 0x49) != 0) {
                  if (!_shouldSkipExecutable(fileName.toLowerCase())) {
                    executables.add(entity.path);
                  }
                }
              } catch (e) {
                // Skip files we can't stat
              }
            }
          }
        }
      }
    } catch (e) {
      // Return what we found
    }

    return executables;
  }

  /// Finds the executable inside a macOS .app bundle.
  Future<String?> _findMacOSAppExecutable(String appBundlePath) async {
    final infoPlistPath = _joinPath(appBundlePath, 'Contents/Info.plist');
    final infoPlistFile = File(infoPlistPath);

    if (await infoPlistFile.exists()) {
      try {
        final content = await infoPlistFile.readAsString();
        // Extract CFBundleExecutable value
        final pattern = RegExp(
          '<key>CFBundleExecutable</key>\\s*<string>([^<]*)</string>',
        );
        final match = pattern.firstMatch(content);
        final executableName = match?.group(1);

        if (executableName != null) {
          final executablePath =
              _joinPath(appBundlePath, 'Contents/MacOS/$executableName');
          if (await File(executablePath).exists()) {
            return executablePath;
          }
        }
      } catch (e) {
        // Fall through to default
      }
    }

    // Fallback: look for any executable in MacOS directory
    final macOSDir = Directory(_joinPath(appBundlePath, 'Contents/MacOS'));
    if (await macOSDir.exists()) {
      try {
        await for (final entity in macOSDir.list()) {
          if (entity is File) {
            return entity.path;
          }
        }
      } catch (e) {
        // No executable found
      }
    }

    return null;
  }

  /// Checks if a filename has a non-executable extension.
  bool _hasExecutableExtension(String fileName) {
    final nonExecutableExtensions = {
      '.txt',
      '.md',
      '.pdf',
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.bmp',
      '.ico',
      '.so',
      '.dll',
      '.dylib',
      '.xml',
      '.json',
      '.ini',
      '.cfg',
      '.log',
      '.zip',
      '.tar',
      '.gz',
      '.7z',
      '.rar',
    };

    final lowerFileName = fileName.toLowerCase();
    return nonExecutableExtensions.any((ext) => lowerFileName.endsWith(ext));
  }

  /// Checks if an executable should be skipped (common non-game executables).
  bool _shouldSkipExecutable(String fileName) {
    final skipPatterns = {
      'setup',
      'install',
      'uninstall',
      'unins',
      'redist',
      'vcredist',
      'dxsetup',
      'dotnet',
      'launcher',
      'crash',
      'report',
      'update',
      'updater',
      'patch',
      'config',
      'settings',
      'readme',
      'eula',
      'license',
      'steam',
    };

    final lowerFileName = fileName.toLowerCase();
    return skipPatterns.any((pattern) => lowerFileName.contains(pattern));
  }

  /// Joins path components using the platform separator.
  String _joinPath(String a, String b) {
    final separator = _platformInfo.pathSeparator;
    if (a.endsWith(separator)) {
      return '$a$b';
    }
    return '$a$separator$b';
  }
}

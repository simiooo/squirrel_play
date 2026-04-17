import 'dart:convert';
import 'dart:io';

import 'package:squirrel_play/core/services/platform_info.dart';

/// Parser for Steam's libraryfolders.vdf file.
///
/// Extracts library folder paths from Steam's VDF (Valve Data Format) files.
/// Handles BOM, different line endings, and Unicode characters.
class SteamLibraryParser {
  final PlatformInfo _platformInfo;

  /// Creates a SteamLibraryParser with the given platform info.
  SteamLibraryParser({required PlatformInfo platformInfo})
      : _platformInfo = platformInfo;

  /// Parses the libraryfolders.vdf file at the given Steam path.
  ///
  /// Returns a list of library folder paths. The first path is always
  /// the main Steam installation's steamapps directory.
  Future<List<String>> parseLibraryFolders(String steamPath) async {
    final vdfPath = _joinPath(steamPath, 'steamapps/libraryfolders.vdf');
    final file = File(vdfPath);

    if (!await file.exists()) {
      // Fallback: return just the main steamapps directory
      return [_joinPath(steamPath, 'steamapps')];
    }

    try {
      final content = await file.readAsBytes();
      return _parseVdfContent(content);
    } catch (e) {
      // If parsing fails, return just the main steamapps directory
      return [_joinPath(steamPath, 'steamapps')];
    }
  }

  /// Parses VDF content from bytes.
  ///
  /// Handles BOM, line endings, and extracts path values.
  List<String> _parseVdfContent(List<int> bytes) {
    // Remove UTF-8 BOM if present
    var contentBytes = bytes;
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      contentBytes = bytes.sublist(3);
    }

    // Decode as UTF-8
    String content;
    try {
      content = utf8.decode(contentBytes);
    } catch (e) {
      // Fallback to latin-1 if UTF-8 fails
      content = latin1.decode(contentBytes);
    }

    // Normalize line endings to LF
    content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final paths = <String>[];
    final lines = content.split('\n');

    // Parse VDF format to extract path values
    // VDF format: "key" "value" or nested sections with {}
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Look for "path" "value" pattern
      final pathMatch = _extractPathValue(line);
      if (pathMatch != null) {
        paths.add(_normalizePath(pathMatch));
      }
    }

    return paths;
  }

  /// Extracts a path value from a VDF line.
  ///
  /// Pattern: "path" "\\some\\path\\here"
  /// Returns the unescaped path or null if not found.
  String? _extractPathValue(String line) {
    // Match "path" followed by a quoted value
    final pathPattern = RegExp(r'"path"\s+"([^"]*)"');
    final match = pathPattern.firstMatch(line);

    if (match != null && match.groupCount >= 1) {
      var path = match.group(1) ?? '';
      // Unescape VDF escape sequences
      path = path.replaceAll(r'\\', _platformInfo.pathSeparator);
      return path;
    }

    return null;
  }

  /// Normalizes a path for the current platform.
  String _normalizePath(String path) {
    if (_platformInfo.isWindows) {
      // Convert forward slashes to backslashes on Windows
      return path.replaceAll('/', r'\');
    } else {
      // Convert backslashes to forward slashes on Unix
      return path.replaceAll(r'\', '/');
    }
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

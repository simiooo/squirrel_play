import 'dart:io';

import 'package:squirrel_play/core/services/platform_info.dart';

/// Service for detecting Steam installation directories.
///
/// Supports Windows, Linux, and macOS with platform-specific
/// default paths and manual path override capability.
class SteamDetector {
  final PlatformInfo _platformInfo;

  /// Creates a SteamDetector with the given platform info.
  SteamDetector({required PlatformInfo platformInfo})
      : _platformInfo = platformInfo;

  /// Attempts to auto-detect the Steam installation directory.
  ///
  /// Returns the path if found, null otherwise.
  Future<String?> detectSteamPath() async {
    if (_platformInfo.isWindows) {
      return _detectWindowsSteam();
    } else if (_platformInfo.isLinux) {
      return _detectLinuxSteam();
    } else if (_platformInfo.isMacOS) {
      return _detectMacOSSteam();
    }
    return null;
  }

  /// Validates that the given path is a valid Steam installation.
  ///
  /// Checks for the presence of steamapps directory.
  Future<bool> validateSteamPath(String path) async {
    final steamappsDir = Directory('$_normalizePath(path)/steamapps');
    return await steamappsDir.exists();
  }

  /// Detects Steam on Windows.
  Future<String?> _detectWindowsSteam() async {
    final commonPaths = [
      r'C:\Program Files (x86)\Steam',
      r'C:\Program Files\Steam',
    ];

    for (final steamPath in commonPaths) {
      if (await validateSteamPath(steamPath)) {
        return steamPath;
      }
    }

    return null;
  }

  /// Detects Steam on Linux.
  Future<String?> _detectLinuxSteam() async {
    final home = _platformInfo.homeDirectory;
    if (home.isEmpty) return null;

    final commonPaths = [
      '$home/.steam/steam',
      '$home/.var/app/com.valvesoftware.Steam/.local/share/Steam', // Flatpak
      '$home/.local/share/Steam',
      '$home/.steam/debian-installation',
    ];

    for (final steamPath in commonPaths) {
      if (await validateSteamPath(steamPath)) {
        return steamPath;
      }
    }

    return null;
  }

  /// Detects Steam on macOS.
  Future<String?> _detectMacOSSteam() async {
    final home = _platformInfo.homeDirectory;
    if (home.isEmpty) return null;

    final steamPath = '$home/Library/Application Support/Steam';

    if (await validateSteamPath(steamPath)) {
      return steamPath;
    }

    return null;
  }

  /// Normalizes a path to use the correct path separator.
  String _normalizePath(String path) {
    if (_platformInfo.isWindows) {
      return path.replaceAll('/', r'\');
    }
    return path.replaceAll(r'\', '/');
  }
}

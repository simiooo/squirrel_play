import 'dart:io';

/// Abstract interface for platform information.
///
/// This abstraction allows for testable platform-specific code by enabling
/// mock implementations in unit tests.
abstract class PlatformInfo {
  /// Whether the current platform is Windows.
  bool get isWindows;

  /// Whether the current platform is Linux.
  bool get isLinux;

  /// Whether the current platform is macOS.
  bool get isMacOS;

  /// The user's home directory path.
  String get homeDirectory;

  /// The platform's path separator ('/' on Unix, '\' on Windows).
  String get pathSeparator;
}

/// Implementation of [PlatformInfo] that delegates to dart:io Platform.
class PlatformInfoImpl implements PlatformInfo {
  @override
  bool get isWindows => Platform.isWindows;

  @override
  bool get isLinux => Platform.isLinux;

  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  String get homeDirectory {
    // Try HOME first (Unix-like), then USERPROFILE (Windows)
    return Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
  }

  @override
  String get pathSeparator => Platform.pathSeparator;
}

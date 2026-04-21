import 'dart:io';

import 'package:squirrel_play/core/services/platform_info.dart';

/// Result of a power action attempt.
class PowerActionResult {
  /// Creates a [PowerActionResult].
  const PowerActionResult({required this.success, this.error});

  /// Whether the action succeeded.
  final bool success;

  /// Error message if the action failed.
  final String? error;

  /// Creates a successful result.
  factory PowerActionResult.ok() => const PowerActionResult(success: true);

  /// Creates a failed result with the given [message].
  factory PowerActionResult.fail(String message) =>
      PowerActionResult(success: false, error: message);
}

/// Service for executing system power actions.
///
/// Wraps platform-specific commands for lock, suspend, shutdown, and reboot.
/// All actions require appropriate user permissions (e.g., polkit on Linux).
class SystemPowerService {
  /// Creates a [SystemPowerService].
  SystemPowerService({required PlatformInfo platformInfo})
      : _platformInfo = platformInfo;

  final PlatformInfo _platformInfo;

  /// Locks the current user session.
  Future<PowerActionResult> lock() async {
    return _runCommand(_lockCommands());
  }

  /// Suspends the system (sleep).
  Future<PowerActionResult> suspend() async {
    return _runCommand(_suspendCommands());
  }

  /// Powers off the system (shutdown).
  Future<PowerActionResult> powerOff() async {
    return _runCommand(_powerOffCommands());
  }

  /// Reboots the system.
  Future<PowerActionResult> reboot() async {
    return _runCommand(_rebootCommands());
  }

  List<String> _lockCommands() {
    if (_platformInfo.isLinux) {
      return ['loginctl', 'lock-session'];
    }
    if (_platformInfo.isWindows) {
      return ['rundll32.exe', 'user32.dll,LockWorkStation'];
    }
    if (_platformInfo.isMacOS) {
      return ['pmset', 'displaysleepnow'];
    }
    return [];
  }

  List<String> _suspendCommands() {
    if (_platformInfo.isLinux) {
      return ['systemctl', 'suspend'];
    }
    if (_platformInfo.isWindows) {
      return ['rundll32.exe', 'powrprof.dll,SetSuspendState', '0,1,0'];
    }
    if (_platformInfo.isMacOS) {
      return ['pmset', 'sleepnow'];
    }
    return [];
  }

  List<String> _powerOffCommands() {
    if (_platformInfo.isLinux) {
      return ['systemctl', 'poweroff'];
    }
    if (_platformInfo.isWindows) {
      return ['shutdown', '/s', '/t', '0'];
    }
    if (_platformInfo.isMacOS) {
      return ['shutdown', '-h', 'now'];
    }
    return [];
  }

  List<String> _rebootCommands() {
    if (_platformInfo.isLinux) {
      return ['systemctl', 'reboot'];
    }
    if (_platformInfo.isWindows) {
      return ['shutdown', '/r', '/t', '0'];
    }
    if (_platformInfo.isMacOS) {
      return ['shutdown', '-r', 'now'];
    }
    return [];
  }

  Future<PowerActionResult> _runCommand(List<String> command) async {
    if (command.isEmpty) {
      return PowerActionResult.fail('Unsupported platform');
    }

    try {
      final result = await Process.run(
        command.first,
        command.skip(1).toList(),
        runInShell: true,
      );

      if (result.exitCode != 0) {
        final stderr = (result.stderr as String?)?.trim() ?? '';
        if (stderr.contains('Permission denied') ||
            stderr.contains('access denied') ||
            stderr.contains('Not authorized') ||
            stderr.contains('interactive authentication required')) {
          return PowerActionResult.fail(
            'Permission denied — administrator rights required',
          );
        }
        return PowerActionResult.fail(stderr.isNotEmpty ? stderr : 'Command failed');
      }

      return PowerActionResult.ok();
    } on ProcessException catch (e) {
      return PowerActionResult.fail('Command not found: ${e.message}');
    } catch (e) {
      return PowerActionResult.fail(e.toString());
    }
  }
}

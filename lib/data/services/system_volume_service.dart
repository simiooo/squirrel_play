import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:squirrel_play/core/services/platform_info.dart';

/// Service for controlling the system master volume.
///
/// Uses platform-specific commands:
/// - Linux: `pactl` (PulseAudio) with `amixer` fallback
/// - Windows: PowerShell CoreAudio API
/// - macOS: `osascript`
class SystemVolumeService {
  /// Creates a [SystemVolumeService].
  SystemVolumeService({required PlatformInfo platformInfo})
      : _platformInfo = platformInfo;

  final PlatformInfo _platformInfo;

  /// Initializes the service and sets the application volume to 80%.
  Future<void> initialize() async {
    debugPrint('[SystemVolumeService] Initializing...');
    try {
      await setVolume(0.8);
      debugPrint('[SystemVolumeService] Volume set to 80%');
    } catch (e) {
      debugPrint('[SystemVolumeService] Failed to set initial volume: $e');
    }
  }

  /// Gets the current system master volume (0.0 to 1.0).
  Future<double> getVolume() async {
    if (_platformInfo.isLinux) {
      return _getVolumeLinux();
    }
    if (_platformInfo.isWindows) {
      return _getVolumeWindows();
    }
    if (_platformInfo.isMacOS) {
      return _getVolumeMacOS();
    }
    return 0.8;
  }

  /// Sets the system master volume to [value] (0.0 to 1.0).
  Future<void> setVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    if (_platformInfo.isLinux) {
      await _setVolumeLinux(clamped);
      return;
    }
    if (_platformInfo.isWindows) {
      await _setVolumeWindows(clamped);
      return;
    }
    if (_platformInfo.isMacOS) {
      await _setVolumeMacOS(clamped);
      return;
    }
  }

  /// Gets whether the system master is muted.
  Future<bool> getMuted() async {
    if (_platformInfo.isLinux) {
      return _getMutedLinux();
    }
    if (_platformInfo.isWindows) {
      return _getMutedWindows();
    }
    if (_platformInfo.isMacOS) {
      return _getMutedMacOS();
    }
    return false;
  }

  /// Sets the system master mute state to [muted].
  Future<void> setMuted(bool muted) async {
    if (_platformInfo.isLinux) {
      await _setMutedLinux(muted);
      return;
    }
    if (_platformInfo.isWindows) {
      await _setMutedWindows(muted);
      return;
    }
    if (_platformInfo.isMacOS) {
      await _setMutedMacOS(muted);
      return;
    }
  }

  // ─── Linux (PulseAudio + ALSA fallback) ───

  Future<double> _getVolumeLinux() async {
    try {
      final result = await Process.run(
        'pactl',
        ['list', 'sinks'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final volume = _parsePactlVolume(result.stdout as String);
        if (volume != null) return volume;
      }
    } catch (_) {}

    // Fallback to amixer
    try {
      final result = await Process.run(
        'amixer',
        ['get', 'Master'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final volume = _parseAmixerVolume(result.stdout as String);
        if (volume != null) return volume;
      }
    } catch (_) {}

    return 0.8;
  }

  Future<void> _setVolumeLinux(double value) async {
    final percent = (value * 100).round();
    try {
      final result = await Process.run(
        'pactl',
        ['set-sink-volume', '@DEFAULT_SINK@', '$percent%'],
        runInShell: true,
      );
      if (result.exitCode == 0) return;
    } catch (_) {}

    // Fallback to amixer
    try {
      await Process.run(
        'amixer',
        ['set', 'Master', '$percent%'],
        runInShell: true,
      );
    } catch (e) {
      debugPrint('[SystemVolumeService] Linux setVolume failed: $e');
    }
  }

  Future<bool> _getMutedLinux() async {
    try {
      final result = await Process.run(
        'pactl',
        ['list', 'sinks'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final muted = _parsePactlMute(result.stdout as String);
        if (muted != null) return muted;
      }
    } catch (_) {}

    try {
      final result = await Process.run(
        'amixer',
        ['get', 'Master'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).contains('[off]');
      }
    } catch (_) {}

    return false;
  }

  Future<void> _setMutedLinux(bool muted) async {
    final state = muted ? '1' : '0';
    try {
      final result = await Process.run(
        'pactl',
        ['set-sink-mute', '@DEFAULT_SINK@', state],
        runInShell: true,
      );
      if (result.exitCode == 0) return;
    } catch (_) {}

    try {
      final amixerState = muted ? 'mute' : 'unmute';
      await Process.run(
        'amixer',
        ['set', 'Master', amixerState],
        runInShell: true,
      );
    } catch (e) {
      debugPrint('[SystemVolumeService] Linux setMuted failed: $e');
    }
  }

  double? _parsePactlVolume(String output) {
    // Look for "Volume: front-left: 65536 / 100% / 0.00 dB"
    final match = RegExp(r'Volume:.*?/(\d+)%').firstMatch(output);
    if (match != null) {
      final percent = int.tryParse(match.group(1) ?? '');
      if (percent != null) return percent / 100.0;
    }
    return null;
  }

  bool? _parsePactlMute(String output) {
    final match = RegExp(r'Mute:\s*(yes|no)').firstMatch(output);
    if (match != null) {
      return match.group(1) == 'yes';
    }
    return null;
  }

  double? _parseAmixerVolume(String output) {
    final match = RegExp(r'\[(\d+)%\]').firstMatch(output);
    if (match != null) {
      final percent = int.tryParse(match.group(1) ?? '');
      if (percent != null) return percent / 100.0;
    }
    return null;
  }

  // ─── Windows (PowerShell CoreAudio) ───

  Future<double> _getVolumeWindows() async {
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'Add-Type -TypeDefinition @"'
              '\nusing System;\nusing System.Runtime.InteropServices;\n'
              '\n[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IAudioEndpointVolume {\n'
              '  int RegisterControlChangeNotify(IntPtr pNotify);\n'
              '  int UnregisterControlChangeNotify(IntPtr pNotify);\n'
              '  int GetChannelCount(out uint pnChannelCount);\n'
              '  int SetMasterVolumeLevel(float fLevelDB, Guid pguidEventContext);\n'
              '  int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);\n'
              '  int GetMasterVolumeLevel(out float pfLevelDB);\n'
              '  int GetMasterVolumeLevelScalar(out float pfLevel);\n'
              '  int SetChannelVolumeLevel(uint nChannel, float fLevelDB, Guid pguidEventContext);\n'
              '  int SetChannelVolumeLevelScalar(uint nChannel, float fLevel, Guid pguidEventContext);\n'
              '  int GetChannelVolumeLevel(uint nChannel, out float pfLevelDB);\n'
              '  int GetChannelVolumeLevelScalar(uint nChannel, out float pfLevel);\n'
              '  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);\n'
              '  int GetMute(out bool pbMute);\n'
              '  int GetVolumeStepInfo(out uint pnStep, out uint pnStepCount);\n'
              '  int VolumeStepUp(Guid pguidEventContext);\n'
              '  int VolumeStepDown(Guid pguidEventContext);\n'
              '  int QueryHardwareSupport(out uint pdwHardwareSupportMask);\n'
              '  int GetVolumeRange(out float pflVolumeMindB, out float pflVolumeMaxdB, out float pflVolumeIncrementdB);\n}\n'
              '\n[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDevice {\n'
              '  int Activate(ref Guid iid, uint dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);\n}\n'
              '\n[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDeviceEnumerator {\n'
              '  int EnumAudioEndpoints(int dataFlow, uint dwStateMask, out IntPtr ppDevices);\n'
              '  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppEndpoint);\n}\n'
              '\n[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]\n'
              '\nclass MMDeviceEnumerator { }\n'
              '\npublic class Volume {\n'
              '  public static float GetVolume() {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.GetMasterVolumeLevelScalar(out float level);\n'
              '    return level;\n'
              '  }\n'
              '  public static bool GetMute() {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.GetMute(out bool mute);\n'
              '    return mute;\n'
              '  }\n'
              '  public static void SetVolume(float level) {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.SetMasterVolumeLevelScalar(level, Guid.Empty);\n'
              '  }\n'
              '  public static void SetMute(bool mute) {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.SetMute(mute, Guid.Empty);\n'
              '  }\n}\n'
              '"@; [Volume]::GetVolume()',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final level = double.tryParse((result.stdout as String).trim());
        if (level != null) return level;
      }
    } catch (e) {
      debugPrint('[SystemVolumeService] Windows getVolume failed: $e');
    }
    return 0.8;
  }

  Future<void> _setVolumeWindows(double value) async {
    try {
      await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'Add-Type -TypeDefinition @"'
              '\nusing System;\nusing System.Runtime.InteropServices;\n'
              '\n[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IAudioEndpointVolume {\n'
              '  int RegisterControlChangeNotify(IntPtr pNotify);\n'
              '  int UnregisterControlChangeNotify(IntPtr pNotify);\n'
              '  int GetChannelCount(out uint pnChannelCount);\n'
              '  int SetMasterVolumeLevel(float fLevelDB, Guid pguidEventContext);\n'
              '  int SetMasterVolumeLevelScalar(float fLevel, Guid pguidEventContext);\n'
              '  int GetMasterVolumeLevel(out float pfLevelDB);\n'
              '  int GetMasterVolumeLevelScalar(out float pfLevel);\n'
              '  int SetChannelVolumeLevel(uint nChannel, float fLevelDB, Guid pguidEventContext);\n'
              '  int SetChannelVolumeLevelScalar(uint nChannel, float fLevel, Guid pguidEventContext);\n'
              '  int GetChannelVolumeLevel(uint nChannel, out float pfLevelDB);\n'
              '  int GetChannelVolumeLevelScalar(uint nChannel, out float pfLevel);\n'
              '  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);\n'
              '  int GetMute(out bool pbMute);\n'
              '  int GetVolumeStepInfo(out uint pnStep, out uint pnStepCount);\n'
              '  int VolumeStepUp(Guid pguidEventContext);\n'
              '  int VolumeStepDown(Guid pguidEventContext);\n'
              '  int QueryHardwareSupport(out uint pdwHardwareSupportMask);\n'
              '  int GetVolumeRange(out float pflVolumeMindB, out float pflVolumeMaxdB, out float pflVolumeIncrementdB);\n}\n'
              '\n[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDevice {\n'
              '  int Activate(ref Guid iid, uint dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);\n}\n'
              '\n[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDeviceEnumerator {\n'
              '  int EnumAudioEndpoints(int dataFlow, uint dwStateMask, out IntPtr ppDevices);\n'
              '  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppEndpoint);\n}\n'
              '\n[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]\n'
              '\nclass MMDeviceEnumerator { }\n'
              '\npublic class Volume {\n'
              '  public static void SetVolume(float level) {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.SetMasterVolumeLevelScalar(level, Guid.Empty);\n'
              '  }\n'
              '  public static void SetMute(bool mute) {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.SetMute(mute, Guid.Empty);\n'
              '  }\n}\n'
              '"@; [Volume]::SetVolume($value)',
        ],
        runInShell: true,
      );
    } catch (e) {
      debugPrint('[SystemVolumeService] Windows setVolume failed: $e');
    }
  }

  Future<bool> _getMutedWindows() async {
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'Add-Type -TypeDefinition @"'
              '\nusing System;\nusing System.Runtime.InteropServices;\n'
              '\n[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IAudioEndpointVolume {\n'
              '  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);\n'
              '  int GetMute(out bool pbMute);\n}\n'
              '\n[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDevice {\n'
              '  int Activate(ref Guid iid, uint dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);\n}\n'
              '\n[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDeviceEnumerator {\n'
              '  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppEndpoint);\n}\n'
              '\n[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]\n'
              '\nclass MMDeviceEnumerator { }\n'
              '\npublic class Volume {\n'
              '  public static bool GetMute() {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.GetMute(out bool mute);\n'
              '    return mute;\n'
              '  }\n}\n'
              '"@; [Volume]::GetMute()',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim().toLowerCase();
        return output == 'true';
      }
    } catch (e) {
      debugPrint('[SystemVolumeService] Windows getMuted failed: $e');
    }
    return false;
  }

  Future<void> _setMutedWindows(bool muted) async {
    try {
      await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'Add-Type -TypeDefinition @"'
              '\nusing System;\nusing System.Runtime.InteropServices;\n'
              '\n[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IAudioEndpointVolume {\n'
              '  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, Guid pguidEventContext);\n'
              '  int GetMute(out bool pbMute);\n}\n'
              '\n[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDevice {\n'
              '  int Activate(ref Guid iid, uint dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);\n}\n'
              '\n[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]\n'
              '\ninterface IMMDeviceEnumerator {\n'
              '  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppEndpoint);\n}\n'
              '\n[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]\n'
              '\nclass MMDeviceEnumerator { }\n'
              '\npublic class Volume {\n'
              '  public static void SetMute(bool mute) {\n'
              '    var enumerator = new MMDeviceEnumerator() as IMMDeviceEnumerator;\n'
              '    enumerator.GetDefaultAudioEndpoint(0, 1, out var device);\n'
              '    var guid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");\n'
              '    device.Activate(ref guid, 0, IntPtr.Zero, out var o);\n'
              '    var vol = o as IAudioEndpointVolume;\n'
              '    vol.SetMute(mute, Guid.Empty);\n'
              '  }\n}\n'
              '"@; [Volume]::SetMute($muted)',
        ],
        runInShell: true,
      );
    } catch (e) {
      debugPrint('[SystemVolumeService] Windows setMuted failed: $e');
    }
  }

  // ─── macOS (osascript) ───

  Future<double> _getVolumeMacOS() async {
    try {
      final result = await Process.run(
        'osascript',
        ['-e', 'output volume of (get volume settings)'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final percent = int.tryParse((result.stdout as String).trim());
        if (percent != null) return percent / 100.0;
      }
    } catch (e) {
      debugPrint('[SystemVolumeService] macOS getVolume failed: $e');
    }
    return 0.8;
  }

  Future<void> _setVolumeMacOS(double value) async {
    try {
      final percent = (value * 100).round();
      await Process.run(
        'osascript',
        ['-e', 'set volume output volume $percent'],
        runInShell: true,
      );
    } catch (e) {
      debugPrint('[SystemVolumeService] macOS setVolume failed: $e');
    }
  }

  Future<bool> _getMutedMacOS() async {
    try {
      final result = await Process.run(
        'osascript',
        ['-e', 'output muted of (get volume settings)'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim().toLowerCase();
        return output == 'true';
      }
    } catch (e) {
      debugPrint('[SystemVolumeService] macOS getMuted failed: $e');
    }
    return false;
  }

  Future<void> _setMutedMacOS(bool muted) async {
    try {
      final state = muted ? 'with' : 'without';
      await Process.run(
        'osascript',
        ['-e', 'set volume $state output muted'],
        runInShell: true,
      );
    } catch (e) {
      debugPrint('[SystemVolumeService] macOS setMuted failed: $e');
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:squirrel_play/core/services/platform_info.dart';

/// Type of network interface.
enum NetworkInterfaceType {
  /// Wired Ethernet connection.
  wired,

  /// Wireless (Wi-Fi) connection.
  wireless,

  /// Local loopback interface.
  loopback,

  /// Unknown or other type.
  other,
}

/// Information about a network interface.
class NetworkInterfaceInfo {
  /// Creates a [NetworkInterfaceInfo].
  const NetworkInterfaceInfo({
    required this.name,
    required this.type,
    required this.isUp,
    this.speed,
    this.ipAddresses = const [],
  });

  /// Interface name (e.g., "eth0", "wlan0", "Wi-Fi").
  final String name;

  /// Type of interface.
  final NetworkInterfaceType type;

  /// Whether the interface is currently up/connected.
  final bool isUp;

  /// Link speed in Mbps (if available).
  final int? speed;

  /// IP addresses assigned to this interface.
  final List<String> ipAddresses;

  /// Whether this interface provides internet connectivity.
  bool get isConnected => isUp && type != NetworkInterfaceType.loopback;
}

/// Service for querying network interface status.
///
/// Uses platform-specific commands to discover all network adapters,
/// their types (wired/wireless), and connection status.
class NetworkStatusService {
  /// Creates a [NetworkStatusService].
  NetworkStatusService({required PlatformInfo platformInfo})
      : _platformInfo = platformInfo;

  final PlatformInfo _platformInfo;

  /// Gets all network interfaces on the system.
  Future<List<NetworkInterfaceInfo>> getNetworkInterfaces() async {
    if (_platformInfo.isLinux) {
      return _getInterfacesLinux();
    }
    if (_platformInfo.isWindows) {
      return _getInterfacesWindows();
    }
    if (_platformInfo.isMacOS) {
      return _getInterfacesMacOS();
    }
    return [];
  }

  // ─── Linux ───

  Future<List<NetworkInterfaceInfo>> _getInterfacesLinux() async {
    final interfaces = <NetworkInterfaceInfo>[];

    try {
      // Try ip -j link show first (JSON output, modern)
      final result = await Process.run(
        'ip',
        ['-j', 'link', 'show'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final jsonList = jsonDecode(result.stdout as String) as List<dynamic>;
        for (final item in jsonList) {
          final map = item as Map<String, dynamic>;
          final name = map['ifname'] as String? ?? '';
          final flags = (map['flags'] as List<dynamic>?)?.cast<String>() ?? [];
          final isUp = flags.contains('UP') && !flags.contains('LOOPBACK');

          final linkType = (map['link_type'] as String?)?.toLowerCase() ?? '';
          final type = _classifyLinuxType(name, linkType);

          interfaces.add(NetworkInterfaceInfo(
            name: name,
            type: type,
            isUp: isUp,
          ));
        }
        return interfaces;
      }
    } catch (e) {
      debugPrint('[NetworkStatusService] ip -j failed: $e');
    }

    // Fallback to legacy ip link show
    try {
      final result = await Process.run(
        'ip',
        ['link', 'show'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        return _parseIpLinkOutput(result.stdout as String);
      }
    } catch (e) {
      debugPrint('[NetworkStatusService] ip link failed: $e');
    }

    return interfaces;
  }

  List<NetworkInterfaceInfo> _parseIpLinkOutput(String output) {
    final interfaces = <NetworkInterfaceInfo>[];
    final lines = output.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith(RegExp(r'\d+:'))) {
        final match = RegExp(r'\d+:\s+(\w+):\s+<([^>]+)>').firstMatch(line);
        if (match != null) {
          final name = match.group(1)!;
          final flags = match.group(2)!.split(',');
          final isUp = flags.contains('UP') && !flags.contains('LOOPBACK');
          final type = _classifyLinuxType(name, '');
          interfaces.add(NetworkInterfaceInfo(
            name: name,
            type: type,
            isUp: isUp,
          ));
        }
      }
    }
    return interfaces;
  }

  NetworkInterfaceType _classifyLinuxType(String name, String linkType) {
    if (name.startsWith('lo')) return NetworkInterfaceType.loopback;
    if (name.startsWith('wl') ||
        name.startsWith('wifi') ||
        name.startsWith('wlan') ||
        linkType.contains('ieee802.11')) {
      return NetworkInterfaceType.wireless;
    }
    if (name.startsWith('en') ||
        name.startsWith('eth') ||
        name.startsWith('usb') ||
        linkType.contains('ether')) {
      return NetworkInterfaceType.wired;
    }
    return NetworkInterfaceType.other;
  }

  // ─── Windows ───

  Future<List<NetworkInterfaceInfo>> _getInterfacesWindows() async {
    final interfaces = <NetworkInterfaceInfo>[];

    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r"Get-NetAdapter | Select-Object Name,InterfaceDescription,Status,MediaConnectionState,LinkSpeed,NdisPhysicalMedium | ConvertTo-Json -Depth 2",
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final jsonOutput = result.stdout as String;
        dynamic jsonData;
        try {
          jsonData = jsonDecode(jsonOutput);
        } catch (_) {
          return interfaces;
        }

        final adapterList = jsonData is List ? jsonData : [jsonData];
        for (final adapter in adapterList) {
          if (adapter is! Map<String, dynamic>) continue;
          final map = adapter;

          final name = _safeString(map['Name']) ?? '';
          final status = _safeString(map['Status'])?.toLowerCase() ?? '';
          final mediaState =
              _safeString(map['MediaConnectionState'])?.toLowerCase() ?? '';
          final isUp = status == 'up' && mediaState == 'connected';

          final physMedium = _safeInt(map['NdisPhysicalMedium']) ?? 0;
          final desc = _safeString(map['InterfaceDescription'])?.toLowerCase() ?? '';
          final type = _classifyWindowsType(physMedium, desc);

          interfaces.add(NetworkInterfaceInfo(
            name: name,
            type: type,
            isUp: isUp,
          ));
        }
      }
    } catch (e) {
      debugPrint('[NetworkStatusService] Windows Get-NetAdapter failed: $e');
    }

    return interfaces;
  }

  NetworkInterfaceType _classifyWindowsType(int physMedium, String description) {
    // NdisPhysicalMedium: 0=Unspecified, 1=WirelessLan, 14=WiMax, 15=WWAN
    if (physMedium == 1 || physMedium == 14 || physMedium == 15) {
      return NetworkInterfaceType.wireless;
    }
    if (description.contains('wi-fi') ||
        description.contains('wireless') ||
        description.contains('802.11')) {
      return NetworkInterfaceType.wireless;
    }
    if (description.contains('loopback')) {
      return NetworkInterfaceType.loopback;
    }
    if (physMedium == 0 || physMedium == 8) {
      // 8 = Native 802.11
      return NetworkInterfaceType.wired;
    }
    return NetworkInterfaceType.wired;
  }

  // ─── macOS ───

  Future<List<NetworkInterfaceInfo>> _getInterfacesMacOS() async {
    final interfaces = <NetworkInterfaceInfo>[];

    try {
      final result = await Process.run(
        'networksetup',
        ['-listallhardwareports'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        return _parseMacOSNetworkSetup(result.stdout as String);
      }
    } catch (e) {
      debugPrint('[NetworkStatusService] macOS networksetup failed: $e');
    }

    // Fallback to ifconfig
    try {
      final result = await Process.run(
        'ifconfig',
        [],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        return _parseIfconfigOutput(result.stdout as String);
      }
    } catch (e) {
      debugPrint('[NetworkStatusService] macOS ifconfig failed: $e');
    }

    return interfaces;
  }

  List<NetworkInterfaceInfo> _parseMacOSNetworkSetup(String output) {
    final interfaces = <NetworkInterfaceInfo>[];
    final blocks = output.split('\n\n');

    for (final block in blocks) {
      final lines = block.split('\n');
      String? name;
      String? device;
      NetworkInterfaceType? type;

      for (final line in lines) {
        if (line.startsWith('Hardware Port:')) {
          final port = line.substring('Hardware Port:'.length).trim();
          if (port.toLowerCase().contains('wi-fi') ||
              port.toLowerCase().contains('airport')) {
            type = NetworkInterfaceType.wireless;
          } else if (port.toLowerCase().contains('ethernet')) {
            type = NetworkInterfaceType.wired;
          }
        }
        if (line.startsWith('Device:')) {
          device = line.substring('Device:'.length).trim();
        }
      }

      if (device != null && device != 'lo0') {
        name = device;
        type ??= NetworkInterfaceType.other;
        interfaces.add(NetworkInterfaceInfo(
          name: name,
          type: type,
          isUp: true, // Will be refined by ifconfig if needed
        ));
      }
    }

    return interfaces;
  }

  List<NetworkInterfaceInfo> _parseIfconfigOutput(String output) {
    final interfaces = <NetworkInterfaceInfo>[];
    final blocks = output.split(RegExp(r'(?=^[a-zA-Z0-9]+:)', multiLine: true));

    for (final block in blocks) {
      final firstLine = block.split('\n').first;
      final match = RegExp(r'^([a-zA-Z0-9]+):').firstMatch(firstLine);
      if (match != null) {
        final name = match.group(1)!;
        final isUp = firstLine.contains('status: active') ||
            firstLine.contains('<UP');
        final type = _classifyMacOSType(name, firstLine);
        interfaces.add(NetworkInterfaceInfo(
          name: name,
          type: type,
          isUp: isUp,
        ));
      }
    }

    return interfaces;
  }

  NetworkInterfaceType _classifyMacOSType(String name, String firstLine) {
    if (name == 'lo0') return NetworkInterfaceType.loopback;
    if (name.startsWith('en')) {
      // en0 is usually Wi-Fi on Macs, en1+ can be either
      // We use heuristics from the first line
      if (firstLine.toLowerCase().contains('ether ')) {
        return NetworkInterfaceType.wired;
      }
      return NetworkInterfaceType.wireless;
    }
    return NetworkInterfaceType.other;
  }

  /// Safely extracts a String from a dynamic JSON value.
  static String? _safeString(dynamic value) {
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return null;
  }

  /// Safely extracts an int from a dynamic JSON value.
  static int? _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

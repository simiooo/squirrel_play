import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:squirrel_play/core/services/platform_info.dart';

/// Information about a storage device.
class StorageDeviceInfo {
  /// Creates a [StorageDeviceInfo].
  const StorageDeviceInfo({
    required this.name,
    required this.totalBytes,
    required this.usedBytes,
    required this.mountPoint,
  });

  /// Device name or filesystem label.
  final String name;

  /// Total capacity in bytes.
  final int totalBytes;

  /// Used space in bytes.
  final int usedBytes;

  /// Mount point.
  final String mountPoint;

  /// Free space in bytes.
  int get freeBytes => totalBytes - usedBytes;

  /// Usage ratio (0.0 to 1.0).
  double get usageRatio => totalBytes > 0 ? usedBytes / totalBytes : 0.0;

  /// Formatted total size (e.g., "500 GB").
  String get totalFormatted => _formatBytes(totalBytes);

  /// Formatted used size.
  String get usedFormatted => _formatBytes(usedBytes);

  /// Formatted free size.
  String get freeFormatted => _formatBytes(freeBytes);

  static String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    if (bytes <= 0) return '0 B';
    var i = (bytes.bitLength ~/ 10).clamp(0, suffixes.length - 1);
    // More accurate: use log
    i = 0;
    var size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }
}

/// Comprehensive system information.
class SystemInfo {
  /// Creates a [SystemInfo].
  const SystemInfo({
    required this.osName,
    required this.osVersion,
    required this.kernel,
    required this.hostname,
    required this.cpuModel,
    required this.cpuCores,
    required this.memoryTotal,
    required this.memoryUsed,
    this.gpuModel,
    required this.storageDevices,
    required this.uptime,
    this.architecture,
  });

  /// Operating system name (e.g., "Ubuntu 22.04").
  final String osName;

  /// OS version string.
  final String osVersion;

  /// Kernel version.
  final String kernel;

  /// System hostname.
  final String hostname;

  /// CPU model name.
  final String cpuModel;

  /// Number of CPU cores.
  final int cpuCores;

  /// Total memory in bytes.
  final int memoryTotal;

  /// Used memory in bytes.
  final int memoryUsed;

  /// GPU model (if detectable).
  final String? gpuModel;

  /// List of storage devices.
  final List<StorageDeviceInfo> storageDevices;

  /// System uptime string.
  final String uptime;

  /// CPU architecture.
  final String? architecture;

  /// Memory usage ratio.
  double get memoryUsageRatio =>
      memoryTotal > 0 ? memoryUsed / memoryTotal : 0.0;
}

/// Service for gathering system hardware and software information.
///
/// Inspired by fastfetch — collects OS, CPU, memory, GPU, storage, and uptime.
class SystemInfoService {
  /// Creates a [SystemInfoService].
  SystemInfoService({required PlatformInfo platformInfo})
      : _platformInfo = platformInfo;

  final PlatformInfo _platformInfo;

  /// Gathers comprehensive system information.
  Future<SystemInfo> getSystemInfo() async {
    if (_platformInfo.isLinux) {
      return _getInfoLinux();
    }
    if (_platformInfo.isWindows) {
      return _getInfoWindows();
    }
    if (_platformInfo.isMacOS) {
      return _getInfoMacOS();
    }
    return _fallbackInfo();
  }

  // ─── Linux ───

  Future<SystemInfo> _getInfoLinux() async {
    String osName = 'Linux';
    String osVersion = '';
    String kernel = '';
    String hostname = '';
    String cpuModel = '';
    int cpuCores = 0;
    int memoryTotal = 0;
    int memoryUsed = 0;
    String? gpuModel;
    String uptime = '';
    String? architecture;

    // OS info
    try {
      final result = await Process.run('lsb_release', ['-ds'], runInShell: true);
      if (result.exitCode == 0) {
        osName = (result.stdout as String).trim().replaceAll('"', '');
      }
    } catch (_) {}

    // Kernel
    try {
      final result = await Process.run('uname', ['-r'], runInShell: true);
      if (result.exitCode == 0) {
        kernel = (result.stdout as String).trim();
      }
    } catch (_) {}

    // Hostname
    try {
      final result = await Process.run('uname', ['-n'], runInShell: true);
      if (result.exitCode == 0) {
        hostname = (result.stdout as String).trim();
      }
    } catch (_) {}

    // Architecture
    try {
      final result = await Process.run('uname', ['-m'], runInShell: true);
      if (result.exitCode == 0) {
        architecture = (result.stdout as String).trim();
      }
    } catch (_) {}

    // CPU
    try {
      final result =
          await Process.run('cat', ['/proc/cpuinfo'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final modelMatch = RegExp(r'model name\s*:\s*(.+)', caseSensitive: false)
            .firstMatch(output);
        if (modelMatch != null) {
          cpuModel = modelMatch.group(1)!.trim();
        }
        cpuCores = RegExp(r'^processor\s*:', multiLine: true)
                .allMatches(output)
                .length *
            1;
        if (cpuCores == 0) cpuCores = 1;
      }
    } catch (_) {}

    // Memory
    try {
      final result =
          await Process.run('cat', ['/proc/meminfo'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final totalMatch =
            RegExp(r'MemTotal:\s*(\d+)\s*kB').firstMatch(output);
        final availMatch =
            RegExp(r'MemAvailable:\s*(\d+)\s*kB').firstMatch(output);
        if (totalMatch != null) {
          memoryTotal =
              int.parse(totalMatch.group(1)!) * 1024;
        }
        if (availMatch != null) {
          final avail = int.parse(availMatch.group(1)!) * 1024;
          memoryUsed = memoryTotal - avail;
        } else {
          final freeMatch =
              RegExp(r'MemFree:\s*(\d+)\s*kB').firstMatch(output);
          if (freeMatch != null) {
            final free = int.parse(freeMatch.group(1)!) * 1024;
            memoryUsed = memoryTotal - free;
          }
        }
      }
    } catch (_) {}

    // GPU
    try {
      final result = await Process.run(
        'lspci',
        ['-nnk'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final gpuMatch = RegExp(
          r'VGA compatible controller.*?\[(.*?)\]',
          dotAll: true,
        ).firstMatch(output);
        if (gpuMatch != null) {
          gpuModel = gpuMatch.group(1)!.trim();
        }
      }
    } catch (_) {}

    // Uptime
    try {
      final result =
          await Process.run('cat', ['/proc/uptime'], runInShell: true);
      if (result.exitCode == 0) {
        final seconds = double.tryParse(
          (result.stdout as String).trim().split(' ').first,
        );
        if (seconds != null) {
          uptime = _formatUptime(seconds);
        }
      }
    } catch (_) {}

    // Storage
    final storageDevices = await _getStorageLinux();

    return SystemInfo(
      osName: osName,
      osVersion: osVersion,
      kernel: kernel,
      hostname: hostname,
      cpuModel: cpuModel,
      cpuCores: cpuCores,
      memoryTotal: memoryTotal,
      memoryUsed: memoryUsed,
      gpuModel: gpuModel,
      storageDevices: storageDevices,
      uptime: uptime,
      architecture: architecture,
    );
  }

  Future<List<StorageDeviceInfo>> _getStorageLinux() async {
    final devices = <StorageDeviceInfo>[];

    try {
      final result = await Process.run(
        'df',
        ['-B1', '--output=source,size,used,target'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n').skip(1);
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final name = parts[0];
            final total = int.tryParse(parts[1]) ?? 0;
            final used = int.tryParse(parts[2]) ?? 0;
            final mount = parts[3];
            // Skip pseudo filesystems
            if (name.startsWith('tmpfs') ||
                name.startsWith('devtmpfs') ||
                name.startsWith('squashfs') ||
                name.startsWith('overlay')) {
              continue;
            }
            devices.add(StorageDeviceInfo(
              name: name,
              totalBytes: total,
              usedBytes: used,
              mountPoint: mount,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[SystemInfoService] Linux storage failed: $e');
    }

    return devices;
  }

  // ─── Windows ───

  Future<SystemInfo> _getInfoWindows() async {
    String osName = 'Windows';
    String osVersion = '';
    String kernel = '';
    String hostname = '';
    String cpuModel = '';
    int cpuCores = 0;
    int memoryTotal = 0;
    int memoryUsed = 0;
    String? gpuModel;
    String uptime = '';
    String? architecture;

    // OS and hostname via systeminfo
    try {
      final result = await Process.run(
        'systeminfo',
        ['/FO', 'LIST'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final osMatch = RegExp(r'OS Name:\s*(.+)', caseSensitive: false)
            .firstMatch(output);
        final versionMatch = RegExp(r'OS Version:\s*(.+)', caseSensitive: false)
            .firstMatch(output);
        final hostMatch = RegExp(r'Host Name:\s*(.+)', caseSensitive: false)
            .firstMatch(output);
        final cpuMatch = RegExp(r'Processor\(s\):\s*(.+)', caseSensitive: false)
            .firstMatch(output);
        final archMatch =
            RegExp(r'System Type:\s*(.+)', caseSensitive: false)
                .firstMatch(output);

        if (osMatch != null) {
          osName = osMatch.group(1)!.trim();
        }
        if (versionMatch != null) {
          osVersion = versionMatch.group(1)!.trim();
        }
        if (hostMatch != null) {
          hostname = hostMatch.group(1)!.trim();
        }
        if (cpuMatch != null) {
          final cpuLine = cpuMatch.group(1)!.trim();
          // Usually: "1 Processor(s) Installed. [01]: Intel64 ..."
          final model = RegExp(r'\[\d+\]:\s*(.+)').firstMatch(output);
          if (model != null) {
            cpuModel = model.group(1)!.trim();
          } else {
            cpuModel = cpuLine;
          }
        }
        if (archMatch != null) {
          architecture = archMatch.group(1)!.trim();
        }
      }
    } catch (_) {}

    // Memory via PowerShell
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'(Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final kb = int.tryParse((result.stdout as String).trim());
        if (kb != null) memoryTotal = kb * 1024;
      }
    } catch (_) {}

    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final kb = int.tryParse((result.stdout as String).trim());
        if (kb != null) {
          memoryUsed = memoryTotal - (kb * 1024);
        }
      }
    } catch (_) {}

    // CPU cores
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'(Get-CimInstance Win32_Processor).NumberOfLogicalProcessors',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        cpuCores = int.tryParse((result.stdout as String).trim()) ?? 0;
      }
    } catch (_) {}

    // GPU
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'(Get-CimInstance Win32_VideoController).Name',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        gpuModel = (result.stdout as String).trim();
      }
    } catch (_) {}

    // Uptime
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime | Select-Object -ExpandProperty TotalSeconds',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final seconds = double.tryParse((result.stdout as String).trim());
        if (seconds != null) {
          uptime = _formatUptime(seconds);
        }
      }
    } catch (_) {}

    final storageDevices = await _getStorageWindows();

    return SystemInfo(
      osName: osName,
      osVersion: osVersion,
      kernel: kernel,
      hostname: hostname,
      cpuModel: cpuModel,
      cpuCores: cpuCores,
      memoryTotal: memoryTotal,
      memoryUsed: memoryUsed,
      gpuModel: gpuModel,
      storageDevices: storageDevices,
      uptime: uptime,
      architecture: architecture,
    );
  }

  Future<List<StorageDeviceInfo>> _getStorageWindows() async {
    final devices = <StorageDeviceInfo>[];

    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-Command',
          r'Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID,Size,FreeSpace | ConvertTo-Json -Depth 2',
        ],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        dynamic jsonData;
        try {
          jsonData = jsonDecode(result.stdout as String);
        } catch (_) {
          return devices;
        }
        final diskList = jsonData is List ? jsonData : [jsonData];
        for (final disk in diskList) {
          final map = disk as Map<String, dynamic>;
          final name = map['DeviceID'] as String? ?? '';
          final size = (map['Size'] as num?)?.toInt() ?? 0;
          final free = (map['FreeSpace'] as num?)?.toInt() ?? 0;
          if (size > 0) {
            devices.add(StorageDeviceInfo(
              name: name,
              totalBytes: size,
              usedBytes: size - free,
              mountPoint: name,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[SystemInfoService] Windows storage failed: $e');
    }

    return devices;
  }

  // ─── macOS ───

  Future<SystemInfo> _getInfoMacOS() async {
    String osName = 'macOS';
    String osVersion = '';
    String kernel = '';
    String hostname = '';
    String cpuModel = '';
    int cpuCores = 0;
    int memoryTotal = 0;
    int memoryUsed = 0;
    String? gpuModel;
    String uptime = '';
    String? architecture;

    // OS version
    try {
      final result =
          await Process.run('sw_vers', ['-productVersion'], runInShell: true);
      if (result.exitCode == 0) {
        osVersion = (result.stdout as String).trim();
        osName = 'macOS $osVersion';
      }
    } catch (_) {}

    // Kernel
    try {
      final result = await Process.run('uname', ['-r'], runInShell: true);
      if (result.exitCode == 0) {
        kernel = (result.stdout as String).trim();
      }
    } catch (_) {}

    // Hostname
    try {
      final result = await Process.run('uname', ['-n'], runInShell: true);
      if (result.exitCode == 0) {
        hostname = (result.stdout as String).trim();
      }
    } catch (_) {}

    // Architecture
    try {
      final result = await Process.run('uname', ['-m'], runInShell: true);
      if (result.exitCode == 0) {
        architecture = (result.stdout as String).trim();
      }
    } catch (_) {}

    // CPU
    try {
      final result = await Process.run(
        'sysctl',
        ['-n', 'machdep.cpu.brand_string'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        cpuModel = (result.stdout as String).trim();
      }
    } catch (_) {}

    try {
      final result = await Process.run(
        'sysctl',
        ['-n', 'hw.logicalcpu'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        cpuCores = int.tryParse((result.stdout as String).trim()) ?? 0;
      }
    } catch (_) {}

    // Memory
    try {
      final result = await Process.run(
        'sysctl',
        ['-n', 'hw.memsize'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        memoryTotal = int.tryParse((result.stdout as String).trim()) ?? 0;
      }
    } catch (_) {}

    try {
      final result = await Process.run(
        'vm_stat',
        [],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final pageSizeMatch =
            RegExp(r'page size of (\d+) bytes').firstMatch(output);
        final freeMatch =
            RegExp(r'Pages free:\s+(\d+)').firstMatch(output);
        final inactiveMatch =
            RegExp(r'Pages inactive:\s+(\d+)').firstMatch(output);

        if (pageSizeMatch != null && freeMatch != null) {
          final pageSize = int.parse(pageSizeMatch.group(1)!);
          final freePages = int.parse(freeMatch.group(1)!);
          final inactivePages =
              inactiveMatch != null ? int.parse(inactiveMatch.group(1)!) : 0;
          final usedPages =
              (memoryTotal ~/ pageSize) - freePages - inactivePages;
          memoryUsed = usedPages * pageSize;
        }
      }
    } catch (_) {}

    // GPU
    try {
      final result = await Process.run(
        'system_profiler',
        ['SPDisplaysDataType', '-json'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final jsonData = jsonDecode(result.stdout as String);
        final displays = jsonData['SPDisplaysDataType'] as List<dynamic>?;
        if (displays != null && displays.isNotEmpty) {
          final first = displays.first as Map<String, dynamic>;
          gpuModel = first['sppci_model'] as String? ??
              first['sppci_device'] as String?;
        }
      }
    } catch (_) {}

    // Uptime
    try {
      final result = await Process.run('sysctl', ['-n', 'kern.boottime'], runInShell: true);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        final secMatch = RegExp(r'sec = (\d+)').firstMatch(output);
        if (secMatch != null) {
          final bootTime = int.parse(secMatch.group(1)!);
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          uptime = _formatUptime((now - bootTime).toDouble());
        }
      }
    } catch (_) {}

    final storageDevices = await _getStorageMacOS();

    return SystemInfo(
      osName: osName,
      osVersion: osVersion,
      kernel: kernel,
      hostname: hostname,
      cpuModel: cpuModel,
      cpuCores: cpuCores,
      memoryTotal: memoryTotal,
      memoryUsed: memoryUsed,
      gpuModel: gpuModel,
      storageDevices: storageDevices,
      uptime: uptime,
      architecture: architecture,
    );
  }

  Future<List<StorageDeviceInfo>> _getStorageMacOS() async {
    final devices = <StorageDeviceInfo>[];

    try {
      final result = await Process.run(
        'df',
        ['-k'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n').skip(1);
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 6) {
            final name = parts[0];
            final total = int.tryParse(parts[1]) ?? 0;
            final used = int.tryParse(parts[2]) ?? 0;
            final mount = parts[5];
            if (name.startsWith('map ')) continue;
            devices.add(StorageDeviceInfo(
              name: name,
              totalBytes: total * 1024,
              usedBytes: used * 1024,
              mountPoint: mount,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('[SystemInfoService] macOS storage failed: $e');
    }

    return devices;
  }

  // ─── Fallback ───

  SystemInfo _fallbackInfo() {
    return const SystemInfo(
      osName: 'Unknown',
      osVersion: '',
      kernel: '',
      hostname: '',
      cpuModel: '',
      cpuCores: 0,
      memoryTotal: 0,
      memoryUsed: 0,
      storageDevices: [],
      uptime: '',
    );
  }

  // ─── Helpers ───

  static String _formatUptime(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days day${days > 1 ? 's' : ''}');
    if (hours > 0) parts.add('$hours hour${hours > 1 ? 's' : ''}');
    if (minutes > 0) parts.add('$minutes min');

    return parts.isEmpty ? '< 1 min' : parts.join(', ');
  }
}

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:squirrel_play/data/models/discovered_executable_model.dart';

/// Progress information during a file scan operation.
class ScanProgress {
  /// Number of directories scanned so far.
  final int directoriesScanned;

  /// Number of executable files found so far.
  final int filesFound;

  /// Current directory being scanned.
  final String currentPath;

  /// List of discovered executables (accumulated during scan).
  final List<DiscoveredExecutableModel> executables;

  /// Whether the scan is complete.
  final bool isComplete;

  /// Error message if scan failed for a directory.
  final String? error;

  /// Creates a ScanProgress instance.
  const ScanProgress({
    required this.directoriesScanned,
    required this.filesFound,
    required this.currentPath,
    required this.executables,
    this.isComplete = false,
    this.error,
  });

  /// Creates a copy of this ScanProgress with the given fields replaced.
  ScanProgress copyWith({
    int? directoriesScanned,
    int? filesFound,
    String? currentPath,
    List<DiscoveredExecutableModel>? executables,
    bool? isComplete,
    String? error,
  }) {
    return ScanProgress(
      directoriesScanned: directoriesScanned ?? this.directoriesScanned,
      filesFound: filesFound ?? this.filesFound,
      currentPath: currentPath ?? this.currentPath,
      executables: executables ?? this.executables,
      isComplete: isComplete ?? this.isComplete,
      error: error ?? this.error,
    );
  }
}

/// Service for scanning directories to discover executable files.
///
/// Provides recursive scanning with progress callbacks and cancellation support.
class FileScannerService {
  bool _isCancelled = false;
  bool _isScanning = false;

  /// Whether a scan is currently in progress.
  bool get isScanning => _isScanning;

  /// Scans the given directories for executable files.
  ///
  /// Returns a stream of [ScanProgress] updates. The stream emits:
  /// - Progress updates during scanning
  /// - Final result with [isComplete] = true
  /// - Error updates if a directory cannot be accessed
  ///
  /// [directories] - List of directory paths to scan
  /// [skipPatterns] - Set of filename patterns to skip (e.g., 'setup', 'uninstall')
  /// [maxDepth] - Maximum recursion depth (default: 10)
  /// [directoryIds] - Map of directory paths to their IDs (for associating executables)
  Stream<ScanProgress> scanDirectories(
    List<String> directories, {
    Set<String> skipPatterns = const {'setup', 'uninstall', 'launcher'},
    int maxDepth = 10,
    Map<String, String>? directoryIds,
  }) async* {
    if (_isScanning) {
      throw StateError('A scan is already in progress');
    }

    _isScanning = true;
    _isCancelled = false;

    final allExecutables = <DiscoveredExecutableModel>[];
    int directoriesScanned = 0;
    int filesFound = 0;

    try {
      for (final dirPath in directories) {
        if (_isCancelled) break;

        final dir = Directory(dirPath);
        if (!await dir.exists()) {
          yield ScanProgress(
            directoriesScanned: directoriesScanned,
            filesFound: filesFound,
            currentPath: dirPath,
            executables: List.unmodifiable(allExecutables),
            error: 'Directory does not exist: $dirPath',
          );
          continue;
        }

        final directoryId = directoryIds?[dirPath];

        await for (final progress in _scanDirectory(
          dir,
          skipPatterns,
          maxDepth,
          directoryId ?? '',
          directoriesScanned,
          filesFound,
          allExecutables,
        )) {
          directoriesScanned = progress.directoriesScanned;
          filesFound = progress.filesFound;
          yield progress;
        }
      }

      // Final complete progress
      yield ScanProgress(
        directoriesScanned: directoriesScanned,
        filesFound: filesFound,
        currentPath: '',
        executables: List.unmodifiable(allExecutables),
        isComplete: true,
      );
    } finally {
      _isScanning = false;
    }
  }

  /// Scans a single directory recursively.
  Stream<ScanProgress> _scanDirectory(
    Directory directory,
    Set<String> skipPatterns,
    int maxDepth,
    String directoryId,
    int directoriesScanned,
    int filesFound,
    List<DiscoveredExecutableModel> allExecutables,
  ) async* {
    if (_isCancelled || maxDepth < 0) return;

    final currentPath = directory.path;
    int localDirsScanned = directoriesScanned;
    int localFilesFound = filesFound;

    try {
      await for (final entity in directory.list(recursive: false)) {
        if (_isCancelled) break;

        if (entity is File) {
          final fileName = path.basename(entity.path);
          final extension = path.extension(fileName).toLowerCase();

          // Check if it's an .exe file
          if (extension == '.exe') {
            // Check if it matches any skip patterns
            final lowerFileName = fileName.toLowerCase();
            final shouldSkip = skipPatterns.any(
              (pattern) => lowerFileName.contains(pattern.toLowerCase()),
            );

            if (!shouldSkip) {
              final executable = DiscoveredExecutableModel(
                path: entity.path,
                fileName: fileName,
                directoryId: directoryId,
                isSelected: false,
                isAlreadyAdded: false,
              );
              allExecutables.add(executable);
              localFilesFound++;
            }
          }
        } else if (entity is Directory && maxDepth > 0) {
          // Recursively scan subdirectory
          await for (final subProgress in _scanDirectory(
            entity,
            skipPatterns,
            maxDepth - 1,
            directoryId,
            localDirsScanned,
            localFilesFound,
            allExecutables,
          )) {
            localDirsScanned = subProgress.directoriesScanned;
            localFilesFound = subProgress.filesFound;
            yield subProgress;
          }
        }
      }

      localDirsScanned++;

      yield ScanProgress(
        directoriesScanned: localDirsScanned,
        filesFound: localFilesFound,
        currentPath: currentPath,
        executables: List.unmodifiable(allExecutables),
      );
    } on FileSystemException catch (e) {
      yield ScanProgress(
        directoriesScanned: localDirsScanned,
        filesFound: localFilesFound,
        currentPath: currentPath,
        executables: List.unmodifiable(allExecutables),
        error: 'Cannot access $currentPath: ${e.message}',
      );
    }
  }

  /// Cancels the current scan operation.
  void cancelScan() {
    _isCancelled = true;
  }

  /// Resets the service state.
  void reset() {
    _isCancelled = false;
    _isScanning = false;
  }
}

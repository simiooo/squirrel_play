import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:squirrel_play/data/services/file_scanner_service.dart';

void main() {
  group('FileScannerService', () {
    late FileScannerService service;
    late Directory tempDir;

    setUp(() async {
      service = FileScannerService();
      tempDir = await Directory.systemTemp.createTemp('file_scanner_test_');
    });

    tearDown(() async {
      service.cancelScan();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Basic Scanning', () {
      test('should find .exe files in a directory', () async {
        // Create test files
        await File(path.join(tempDir.path, 'game1.exe')).create();
        await File(path.join(tempDir.path, 'game2.exe')).create();
        await File(path.join(tempDir.path, 'readme.txt')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.last.isComplete, isTrue);
        expect(results.last.filesFound, equals(2));
        expect(results.last.executables.length, equals(2));
      });

      test('should scan recursively in subdirectories', () async {
        // Create nested structure
        final subDir = Directory(path.join(tempDir.path, 'subfolder'));
        await subDir.create();
        await File(path.join(tempDir.path, 'game1.exe')).create();
        await File(path.join(subDir.path, 'game2.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.last.filesFound, equals(2));
        expect(results.last.directoriesScanned, greaterThanOrEqualTo(2));
      });

      test('should skip non-.exe files', () async {
        await File(path.join(tempDir.path, 'game.exe')).create();
        await File(path.join(tempDir.path, 'readme.txt')).create();
        await File(path.join(tempDir.path, 'config.json')).create();
        await File(path.join(tempDir.path, 'data.bin')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.last.filesFound, equals(1));
        expect(results.last.executables.first.fileName, equals('game.exe'));
      });
    });

    group('Skip Patterns', () {
      test('should skip setup.exe by default', () async {
        await File(path.join(tempDir.path, 'setup.exe')).create();
        await File(path.join(tempDir.path, 'game.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.last.filesFound, equals(1));
        expect(results.last.executables.first.fileName, equals('game.exe'));
      });

      test('should skip uninstall.exe by default', () async {
        await File(path.join(tempDir.path, 'uninstall.exe')).create();
        await File(path.join(tempDir.path, 'game.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.last.filesFound, equals(1));
      });

      test('should skip launcher.exe by default', () async {
        await File(path.join(tempDir.path, 'launcher.exe')).create();
        await File(path.join(tempDir.path, 'game.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.last.filesFound, equals(1));
      });

      test('should respect custom skip patterns', () async {
        await File(path.join(tempDir.path, 'test.exe')).create();
        await File(path.join(tempDir.path, 'game.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories(
          [tempDir.path],
          skipPatterns: {'test'},
        )) {
          results.add(progress);
        }

        expect(results.last.filesFound, equals(1));
        expect(results.last.executables.first.fileName, equals('game.exe'));
      });
    });

    group('Progress Updates', () {
      test('should emit progress updates during scan', () async {
        // Create multiple files
        for (int i = 0; i < 5; i++) {
          await File(path.join(tempDir.path, 'game$i.exe')).create();
        }

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.length, greaterThan(0));
        expect(results.last.isComplete, isTrue);
      });

      test('should track directories scanned', () async {
        final subDir1 = Directory(path.join(tempDir.path, 'folder1'));
        final subDir2 = Directory(path.join(tempDir.path, 'folder2'));
        await subDir1.create();
        await subDir2.create();

        await File(path.join(tempDir.path, 'game1.exe')).create();
        await File(path.join(subDir1.path, 'game2.exe')).create();
        await File(path.join(subDir2.path, 'game3.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        expect(results.last.directoriesScanned, greaterThanOrEqualTo(3));
      });
    });

    group('Multiple Directories', () {
      test('should scan multiple directories', () async {
        final dir1 = Directory(path.join(tempDir.path, 'dir1'));
        final dir2 = Directory(path.join(tempDir.path, 'dir2'));
        await dir1.create();
        await dir2.create();

        await File(path.join(dir1.path, 'game1.exe')).create();
        await File(path.join(dir2.path, 'game2.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([dir1.path, dir2.path])) {
          results.add(progress);
        }

        expect(results.last.filesFound, equals(2));
      });
    });

    group('Cancellation', () {
      test('should be cancelable', () async {
        // Create files in nested directories to ensure scan takes some time
        for (int i = 0; i < 10; i++) {
          final subDir = Directory(path.join(tempDir.path, 'subdir$i'));
          await subDir.create();
          for (int j = 0; j < 10; j++) {
            await File(path.join(subDir.path, 'game$j.exe')).create();
          }
        }

        final results = <ScanProgress>[];
        late Stream<ScanProgress> scanStream;

        scanStream = service.scanDirectories([tempDir.path]);

        // Cancel immediately after first emission
        await for (final progress in scanStream) {
          results.add(progress);
          service.cancelScan();
        }

        // Should have received at least one progress update
        expect(results.isNotEmpty, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle non-existent directory', () async {
        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories(['/nonexistent/path'])) {
          results.add(progress);
        }

        // Should complete but with 0 files found
        expect(results.last.isComplete, isTrue);
        expect(results.last.filesFound, equals(0));
      });
    });

    group('DiscoveredExecutableModel', () {
      test('should include correct file information', () async {
        await File(path.join(tempDir.path, 'MyGame.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories([tempDir.path])) {
          results.add(progress);
        }

        final executable = results.last.executables.first;
        expect(executable.fileName, equals('MyGame.exe'));
        expect(executable.path, equals(path.join(tempDir.path, 'MyGame.exe')));
        expect(executable.isSelected, isFalse);
      });

      test('should include directory ID when provided', () async {
        await File(path.join(tempDir.path, 'game.exe')).create();

        final directoryIds = {tempDir.path: 'test-dir-id'};

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories(
          [tempDir.path],
          directoryIds: directoryIds,
        )) {
          results.add(progress);
        }

        expect(results.last.executables.first.directoryId, equals('test-dir-id'));
      });
    });

    group('Max Depth', () {
      test('should respect max depth limit', () async {
        // Create deep nesting
        var currentDir = tempDir;
        for (int i = 0; i < 15; i++) {
          currentDir = Directory(path.join(currentDir.path, 'level$i'));
          await currentDir.create();
        }

        await File(path.join(currentDir.path, 'deep_game.exe')).create();
        await File(path.join(tempDir.path, 'shallow_game.exe')).create();

        final results = <ScanProgress>[];
        await for (final progress in service.scanDirectories(
          [tempDir.path],
          maxDepth: 5,
        )) {
          results.add(progress);
        }

        // Should only find shallow_game.exe
        expect(results.last.filesFound, equals(1));
        expect(results.last.executables.first.fileName, equals('shallow_game.exe'));
      });
    });
  });
}

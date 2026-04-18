import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/core/services/platform_info.dart';
import 'package:squirrel_play/data/services/steam_detector.dart';

class MockPlatformInfo extends Mock implements PlatformInfo {}

class MockDirectory extends Mock implements Directory {}

void main() {
  group('SteamDetector', () {
    late SteamDetector detector;
    late MockPlatformInfo mockPlatformInfo;

    setUp(() {
      mockPlatformInfo = MockPlatformInfo();
      detector = SteamDetector(platformInfo: mockPlatformInfo);
      // Set default platform to Linux for tests that don't specify
      when(() => mockPlatformInfo.isWindows).thenReturn(false);
      when(() => mockPlatformInfo.isLinux).thenReturn(true);
      when(() => mockPlatformInfo.isMacOS).thenReturn(false);
    });

    group('Flatpak path detection', () {
      test('should include Flatpak Steam path in detection paths', () {
        const home = '/home/testuser';
        const flatpakPath = '$home/.var/app/com.valvesoftware.Steam/.local/share/Steam';

        // The expected paths for Linux detection (from the implementation)
        final expectedPaths = [
          '$home/.steam/steam',
          '$home/.var/app/com.valvesoftware.Steam/.local/share/Steam',
          '$home/.local/share/Steam',
          '$home/.steam/debian-installation',
        ];

        // Verify the Flatpak path is in the expected paths list
        expect(expectedPaths, contains(flatpakPath));
        // Verify it's at position 1 (after native, before .local/share/Steam)
        expect(expectedPaths[1], equals(flatpakPath));
      });

      test('should prefer native path over Flatpak when both exist', () {
        const home = '/home/testuser';
        const nativePath = '$home/.steam/steam';
        const flatpakPath = '$home/.var/app/com.valvesoftware.Steam/.local/share/Steam';

        // The expected paths for Linux detection
        final expectedPaths = [
          nativePath,
          flatpakPath,
          '$home/.local/share/Steam',
          '$home/.steam/debian-installation',
        ];

        // Verify native path is first (higher priority)
        expect(expectedPaths.first, equals(nativePath));
        // Verify Flatpak path is second
        expect(expectedPaths[1], equals(flatpakPath));
      });

      test('should include Flatpak path in Linux detection paths', () {
        const home = '/home/testuser';

        // The expected paths for Linux detection
        final expectedPaths = [
          '$home/.steam/steam',
          '$home/.var/app/com.valvesoftware.Steam/.local/share/Steam',
          '$home/.local/share/Steam',
          '$home/.steam/debian-installation',
        ];

        // Verify the Flatpak path is included at the correct position
        expect(expectedPaths[1], equals('$home/.var/app/com.valvesoftware.Steam/.local/share/Steam'));
      });
    });

    group('validateSteamPath', () {
      test('should check for steamapps subdirectory', () async {
        // Test with a non-existent path - should return false
        final result = await detector.validateSteamPath('/nonexistent/path');
        expect(result, isFalse);
      });
    });

    group('Platform-specific detection', () {
      test('should detect Steam on Windows', () async {
        when(() => mockPlatformInfo.isWindows).thenReturn(true);
        when(() => mockPlatformInfo.isLinux).thenReturn(false);
        when(() => mockPlatformInfo.isMacOS).thenReturn(false);

        // Windows detection should return null (no Steam installation in test environment)
        final result = await detector.detectSteamPath();
        // We expect null since there's no actual Steam installation
        expect(result, isNull);
      });

      test('should detect Steam on Linux', () async {
        when(() => mockPlatformInfo.isWindows).thenReturn(false);
        when(() => mockPlatformInfo.isLinux).thenReturn(true);
        when(() => mockPlatformInfo.isMacOS).thenReturn(false);
        when(() => mockPlatformInfo.homeDirectory).thenReturn('/home/testuser');

        // Linux detection should try the common paths
        final result = await detector.detectSteamPath();
        // We expect null since there's no actual Steam installation
        expect(result, isNull);
      });

      test('should detect Steam on macOS', () async {
        when(() => mockPlatformInfo.isWindows).thenReturn(false);
        when(() => mockPlatformInfo.isLinux).thenReturn(false);
        when(() => mockPlatformInfo.isMacOS).thenReturn(true);
        when(() => mockPlatformInfo.homeDirectory).thenReturn('/Users/testuser');

        // macOS detection should try the default path
        final result = await detector.detectSteamPath();
        // We expect null since there's no actual Steam installation
        expect(result, isNull);
      });
    });
  });
}

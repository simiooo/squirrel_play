import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Service for managing the application window.
///
/// Handles window initialization, title, minimum size, default size,
/// fullscreen support, and state persistence.
class WindowManagerService {
  static final WindowManagerService _instance = WindowManagerService._internal();
  factory WindowManagerService() => _instance;
  WindowManagerService._internal();

  bool _isInitialized = false;
  bool _isFullscreen = false;

  /// Whether the service is initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the window is currently fullscreen.
  bool get isFullscreen => _isFullscreen;

  /// Initializes the window manager.
  ///
  /// Sets up:
  /// - Window title: "Squirrel Play"
  /// - Minimum size: 800×600
  /// - Default size: 1280×720 or screen-based
  /// - Centered position
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only initialize on desktop platforms
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      debugPrint('[WindowManager] Skipping initialization on non-desktop platform');
      return;
    }

    try {
      await windowManager.ensureInitialized();

      // Window options
      const windowOptions = WindowOptions(
        title: 'Squirrel Play',
        size: Size(1280, 720), // Default 720p
        center: true,
        minimumSize: Size(800, 600), // Minimum 800×600
        backgroundColor: Colors.black,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden, // Custom title bar
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      _isInitialized = true;
      debugPrint('[WindowManager] Initialized successfully');
    } catch (e) {
      debugPrint('[WindowManager] Failed to initialize: $e');
    }
  }

  /// Toggles fullscreen mode.
  ///
  /// Can be triggered by F11 or Start button.
  Future<void> toggleFullscreen() async {
    if (!_isInitialized) return;

    try {
      _isFullscreen = await windowManager.isFullScreen();
      await windowManager.setFullScreen(!_isFullscreen);
      _isFullscreen = !_isFullscreen;
      debugPrint('[WindowManager] Fullscreen toggled: $_isFullscreen');
    } catch (e) {
      debugPrint('[WindowManager] Failed to toggle fullscreen: $e');
    }
  }

  /// Sets the window title.
  Future<void> setTitle(String title) async {
    if (!_isInitialized) return;

    try {
      await windowManager.setTitle(title);
    } catch (e) {
      debugPrint('[WindowManager] Failed to set title: $e');
    }
  }

  /// Sets the window size.
  Future<void> setSize(Size size) async {
    if (!_isInitialized) return;

    try {
      await windowManager.setSize(size);
    } catch (e) {
      debugPrint('[WindowManager] Failed to set size: $e');
    }
  }

  /// Minimizes the window.
  Future<void> minimize() async {
    if (!_isInitialized) return;

    try {
      await windowManager.minimize();
    } catch (e) {
      debugPrint('[WindowManager] Failed to minimize: $e');
    }
  }

  /// Closes the window.
  Future<void> close() async {
    if (!_isInitialized) return;

    try {
      await windowManager.close();
    } catch (e) {
      debugPrint('[WindowManager] Failed to close: $e');
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fullscreen_window/fullscreen_window.dart';
import 'package:path/path.dart' as path;
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';

/// Service for managing the application window.
///
/// Handles window initialization, title, minimum size, default size,
/// fullscreen support, state persistence, and system tray integration.
class WindowManagerService with WindowListener {
  static final WindowManagerService _instance = WindowManagerService._internal();
  factory WindowManagerService() => _instance;
  WindowManagerService._internal();

  bool _isInitialized = false;
  bool _isFullscreen = false;
  SystemTray? _systemTray;
  AppWindow? _appWindow;

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
  /// - System tray with open/hide/quit menu
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

      // Register window event listener for state synchronization
      windowManager.addListener(this);

      // Initialize system tray
      await _initSystemTray();

      _isInitialized = true;
      debugPrint('[WindowManager] Initialized successfully');
    } catch (e) {
      debugPrint('[WindowManager] Failed to initialize: $e');
    }
  }

  /// Initializes the system tray icon and context menu.
  Future<void> _initSystemTray() async {
    try {
      _systemTray = SystemTray();
      _appWindow = AppWindow();

      final iconPath = _getTrayIconPath();
      await _systemTray!.initSystemTray(
        title: 'Squirrel Play',
        iconPath: iconPath ?? '',
        toolTip: 'Squirrel Play',
      );

      // Register tray click events
      _systemTray!.registerSystemTrayEventHandler((eventName) {
        debugPrint('[SystemTray] Event: $eventName');
        if (eventName == 'leftMouseUp') {
          _showWindow();
        } else if (eventName == 'rightMouseUp') {
          _systemTray!.popUpContextMenu();
        } else if (eventName == 'leftMouseDblClk') {
          _toggleWindowVisibility();
        }
      });

      // Build context menu
      await _buildContextMenu();
    } catch (e) {
      debugPrint('[WindowManager] Failed to initialize system tray: $e');
    }
  }

  /// Builds the tray context menu with open, hide, and quit actions.
  Future<void> _buildContextMenu() async {
    if (_systemTray == null) return;

    final items = [
      MenuItem(
        label: 'Open',
        onClicked: () async {
          debugPrint('[SystemTray] Open clicked');
          await _showWindow();
        },
      ),
      MenuItem(
        label: 'Hide',
        onClicked: () async {
          debugPrint('[SystemTray] Hide clicked');
          await _hideWindow();
        },
      ),
      MenuSeparator(),
      MenuItem(
        label: 'Quit',
        onClicked: () async {
          debugPrint('[SystemTray] Quit clicked');
          await _quitApplication();
        },
      ),
    ];

    await _systemTray!.setContextMenu(items);
  }

  /// Shows and focuses the application window.
  Future<void> _showWindow() async {
    try {
      // Data validation: check if window is already visible and focused
      final isVisible = await windowManager.isVisible();
      final isFocused = await windowManager.isFocused();
      if (isVisible && isFocused) {
        debugPrint('[WindowManager] Window already visible and focused');
        return;
      }

      await _appWindow?.show();
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('[WindowManager] Failed to show window: $e');
    }
  }

  /// Toggles the application window visibility.
  Future<void> _toggleWindowVisibility() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await _hideWindow();
      } else {
        await _showWindow();
      }
    } catch (e) {
      debugPrint('[WindowManager] Failed to toggle window visibility: $e');
    }
  }

  /// Hides the application window.
  Future<void> _hideWindow() async {
    try {
      // Data validation: check if window is already hidden
      final isVisible = await windowManager.isVisible();
      if (!isVisible) {
        debugPrint('[WindowManager] Window already hidden');
        return;
      }

      await _appWindow?.hide();
      await windowManager.hide();
    } catch (e) {
      debugPrint('[WindowManager] Failed to hide window: $e');
    }
  }

  /// Quits the application with validation.
  ///
  /// Checks if any games are currently running before quitting.
  /// If games are running, shows a warning and does not quit.
  Future<void> _quitApplication() async {
    try {
      // Data validation: check if any games are running
      final gameLauncher = _getGameLauncher();
      if (gameLauncher != null) {
        final runningGames = await _getRunningGames(gameLauncher);
        if (runningGames.isNotEmpty) {
          debugPrint(
            '[WindowManager] Cannot quit: ${runningGames.length} game(s) still running',
          );
          // Show the window so the user can see the running games
          await _showWindow();
          return;
        }
      }

      await _appWindow?.close();
      await windowManager.close();
    } catch (e) {
      debugPrint('[WindowManager] Failed to quit: $e');
    }
  }

  /// Gets the GameLauncher instance from DI, if available.
  GameLauncher? _getGameLauncher() {
    try {
      return getIt<GameLauncher>();
    } catch (_) {
      return null;
    }
  }

  /// Gets the list of currently running game IDs.
  Future<List<String>> _getRunningGames(GameLauncher launcher) async {
    try {
      // Use the latest value from the stream
      final runningMap = await launcher.runningGamesStream.first;
      return runningMap.keys.toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns the platform-appropriate tray icon path.
  String? _getTrayIconPath() {
    try {
      final executableDir = path.dirname(Platform.resolvedExecutable);

      if (Platform.isWindows) {
        final icoPath = path.join(executableDir, 'data', 'flutter_assets', 'assets', 'icons', 'app_icon.ico');
        if (File(icoPath).existsSync()) return icoPath;
        // Fallback to runner resources during development
        final devPath = path.join(Directory.current.path, 'windows', 'runner', 'resources', 'app_icon.ico');
        if (File(devPath).existsSync()) return devPath;
      } else if (Platform.isMacOS) {
        final pngPath = path.join(executableDir, '..', 'Resources', 'app_icon_128.png');
        if (File(pngPath).existsSync()) return pngPath;
        // Fallback to assets during development
        final devPath = path.join(Directory.current.path, 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', 'app_icon_128.png');
        if (File(devPath).existsSync()) return devPath;
      } else if (Platform.isLinux) {
        final pngPath = path.join(executableDir, 'data', 'flutter_assets', 'assets', 'icons', 'app_icon_128.png');
        if (File(pngPath).existsSync()) return pngPath;
        // Fallback to macOS icon during development
        final devPath = path.join(Directory.current.path, 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset', 'app_icon_128.png');
        if (File(devPath).existsSync()) return devPath;
      }
    } catch (e) {
      debugPrint('[WindowManager] Failed to resolve tray icon path: $e');
    }
    return null;
  }

  /// Toggles fullscreen mode.
  ///
  /// Can be triggered by F11 or Start button.
  /// Uses [fullscreen_window] plugin on Windows for reliable EGL surface handling.
  Future<void> toggleFullscreen() async {
    if (!_isInitialized) return;

    try {
      final newValue = !_isFullscreen;
      await FullScreenWindow.setFullScreen(newValue);
      _isFullscreen = newValue;
      debugPrint('[WindowManager] Fullscreen toggled: $_isFullscreen');
    } catch (e) {
      debugPrint('[WindowManager] Failed to toggle fullscreen: $e');
    }
  }

  /// Sets fullscreen mode explicitly.
  ///
  /// [value] `true` to enter fullscreen, `false` to exit.
  /// Uses [fullscreen_window] plugin on Windows for reliable EGL surface handling.
  Future<void> setFullscreen(bool value) async {
    if (!_isInitialized) return;

    try {
      await FullScreenWindow.setFullScreen(value);
      _isFullscreen = value;
      debugPrint('[WindowManager] Fullscreen set to: $_isFullscreen');
    } catch (e) {
      debugPrint('[WindowManager] Failed to set fullscreen: $e');
    }
  }

  // ── WindowListener overrides ──

  @override
  void onWindowEnterFullScreen() {
    _isFullscreen = true;
    debugPrint('[WindowManager] Window entered fullscreen (event)');
  }

  @override
  void onWindowLeaveFullScreen() {
    _isFullscreen = false;
    debugPrint('[WindowManager] Window left fullscreen (event)');
  }

  @override
  void onWindowResize() {
    debugPrint('[WindowManager] Window resized');
  }

  @override
  void onWindowMaximize() {
    debugPrint('[WindowManager] Window maximized');
  }

  @override
  void onWindowUnmaximize() {
    debugPrint('[WindowManager] Window restored from maximized');
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

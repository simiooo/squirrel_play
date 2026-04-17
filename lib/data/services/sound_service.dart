import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service for playing sound effects.
///
/// Uses the `audioplayers` package for actual audio playback.
/// Sounds are loaded lazily on first play to avoid blocking startup.
/// Gracefully handles missing sound files.
class SoundService {
  /// Singleton instance.
  static final SoundService _instance = SoundService._internal();

  /// Gets the singleton instance.
  static SoundService get instance => _instance;

  /// Internal constructor.
  SoundService._internal();

  /// Whether the service is initialized.
  bool _isInitialized = false;

  /// Master volume level (0.0 to 1.0).
  double _volume = 0.5;

  /// Whether sound is muted.
  bool _isMuted = false;

  /// Audio players for each sound type (lazy loaded).
  final Map<String, AudioPlayer> _players = {};

  /// Timestamp of last focus move sound play for debouncing.
  DateTime? _lastFocusMoveTime;

  /// Minimum interval between focus move sounds (80ms).
  static const Duration _focusMoveDebounce = Duration(milliseconds: 80);

  /// Gets the current volume level.
  double get volume => _volume;

  /// Gets whether sound is muted.
  bool get isMuted => _isMuted;

  /// Sets whether sound is muted.
  set isMuted(bool value) {
    _isMuted = value;
    debugPrint('[SoundService] Mute set to $_isMuted');
  }

  /// Sets the master volume level.
  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
    _applyVolumeToAllPlayers();
    debugPrint('[SoundService] Volume set to $_volume');
  }

  /// Applies current volume to all initialized audio players.
  void _applyVolumeToAllPlayers() {
    for (final player in _players.values) {
      player.setVolume(_volume);
    }
  }

  /// Initializes the sound service.
  ///
  /// Note: Sound files are NOT preloaded. They are loaded on first play
  /// to avoid blocking the UI at startup.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[SoundService] Already initialized');
      return;
    }

    debugPrint('[SoundService] Initializing...');
    debugPrint('[SoundService] Sound files are optional - app will work without them');
    debugPrint('[SoundService] Sounds will be loaded lazily on first play');

    _isInitialized = true;
    debugPrint('[SoundService] Initialized successfully');
  }

  /// Disposes the service and cleans up resources.
  void dispose() {
    debugPrint('[SoundService] Disposing...');
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _isInitialized = false;
  }

  /// Plays a sound file with error handling.
  Future<void> _playSound(String assetPath, String soundName) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Don't play if muted
    if (_isMuted) {
      debugPrint('[SoundService] Skipping $soundName (muted)');
      return;
    }

    try {
      // Lazy load the player if not already created
      final player = _players[soundName] ??= AudioPlayer()..setVolume(_volume);

      await player.play(AssetSource(assetPath));
      debugPrint('[SoundService] Playing $soundName from $assetPath');
    } catch (e) {
      // Gracefully handle missing files or other errors
      debugPrint('[SoundService] Could not play $soundName: $e');
    }
  }

  /// Plays the focus move sound.
  ///
  /// Triggered when focus moves between interactive elements.
  /// File: assets/sounds/jump-retro-video-game-sfx-jump-c-sound.flac
  /// Max Duration: 100ms
  /// Debounced: 80ms minimum interval between plays.
  Future<void> playFocusMove() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check debounce interval
    final now = DateTime.now();
    if (_lastFocusMoveTime != null) {
      final elapsed = now.difference(_lastFocusMoveTime!);
      if (elapsed < _focusMoveDebounce) {
        // Too soon, skip this sound
        return;
      }
    }
    _lastFocusMoveTime = now;

    await _playSound(
      'sounds/jump-retro-video-game-sfx-jump-c-sound.flac',
      'focus_move',
    );
  }

  /// Plays the focus select sound.
  ///
  /// Triggered when user confirms/activates a focused element.
  /// File: assets/sounds/select-sound.flac
  /// Max Duration: 200ms
  /// Note: This sound plays immediately (not debounced).
  Future<void> playFocusSelect() async {
    await _playSound('sounds/select-sound.flac', 'focus_select');
  }

  /// Plays the focus back sound.
  ///
  /// Triggered when user cancels or navigates back.
  /// File: assets/sounds/select-sound.flac
  /// Max Duration: 150ms
  /// Note: This sound plays immediately (not debounced).
  Future<void> playFocusBack() async {
    await _playSound('sounds/select-sound.flac', 'focus_back');
  }

  /// Plays the page transition sound.
  ///
  /// Triggered when navigating between pages/routes.
  /// File: assets/sounds/transition-transition-whoosh-sound-sound.flac
  /// Max Duration: 300ms
  /// Note: This sound plays immediately (not debounced).
  Future<void> playPageTransition() async {
    await _playSound(
      'sounds/transition-transition-whoosh-sound-sound.flac',
      'page_transition',
    );
  }

  /// Plays the error sound.
  ///
  /// Triggered when an error occurs or invalid action attempted.
  /// File: assets/sounds/error-sound.flac
  /// Max Duration: 300ms
  /// Note: This sound plays immediately (not debounced).
  Future<void> playError() async {
    await _playSound('sounds/error-sound.flac', 'error');
  }

  /// Plays the scan complete sound.
  ///
  /// Triggered when a quick scan completes and new games are found.
  /// File: assets/sounds/rechambering-finish-sound.flac
  Future<void> playScanComplete() async {
    await _playSound('sounds/rechambering-finish-sound.flac', 'scan_complete');
  }

  /// Plays the scan error sound.
  ///
  /// Triggered when a quick scan encounters an error.
  /// File: assets/sounds/error-sound.flac
  Future<void> playScanError() async {
    await _playSound('sounds/error-sound.flac', 'scan_error');
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting system-level application settings.
///
/// Currently manages fullscreen preference and command-line argument parsing.
class SystemSettingsService {
  /// Creates a [SystemSettingsService] with the given [SharedPreferences].
  SystemSettingsService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _fullscreenKey = 'system_settings_fullscreen';

  /// Loads the saved fullscreen setting.
  ///
  /// Returns `true` if fullscreen was enabled, `false` otherwise.
  /// Defaults to `false` if no value has been saved.
  bool loadFullscreenSetting() {
    return _prefs.getBool(_fullscreenKey) ?? false;
  }

  /// Persists the fullscreen setting.
  Future<void> saveFullscreenSetting(bool value) async {
    await _prefs.setBool(_fullscreenKey, value);
  }

  /// Determines whether the app should start in fullscreen mode.
  ///
  /// Checks [args] for `--fullscreen` first (temporary override).
  /// If not present, falls back to the persisted setting.
  bool shouldStartFullscreen(List<String> args) {
    if (args.contains('--fullscreen')) {
      return true;
    }
    return loadFullscreenSetting();
  }
}

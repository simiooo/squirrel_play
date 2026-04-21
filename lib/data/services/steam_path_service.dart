import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting the Steam installation path.
///
/// Stores the manually-specified or auto-detected Steam path
/// so it survives app restarts and dialog closes.
class SteamPathService {
  static const String _prefsKey = 'steam_installation_path';

  final SharedPreferences? _prefs;

  SteamPathService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Gets the saved Steam installation path, if any.
  Future<String?> getSteamPath() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final path = prefs.getString(_prefsKey);
    if (path != null && path.isNotEmpty) {
      return path;
    }
    return null;
  }

  /// Saves the Steam installation path.
  Future<void> saveSteamPath(String path) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, path);
  }

  /// Clears the saved Steam path.
  Future<void> clearSteamPath() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

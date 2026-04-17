import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving the RAWG API key.
///
/// Supports:
/// - Storage in SharedPreferences
/// - Environment variable fallback (RAWG_API_KEY)
/// - Key validation
class ApiKeyService {
  static const String _prefsKey = 'rawg_api_key';
  static const String _envVarName = 'RAWG_API_KEY';

  final SharedPreferences? _prefs;

  ApiKeyService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Gets the stored API key.
  ///
  /// Checks in order:
  /// 1. SharedPreferences
  /// 2. Environment variable RAWG_API_KEY
  ///
  /// Returns null if no key is found.
  Future<String?> getApiKey() async {
    // Check SharedPreferences first
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final storedKey = prefs.getString(_prefsKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }

    // Fall back to environment variable
    final envKey = Platform.environment[_envVarName];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }

    return null;
  }

  /// Saves the API key to SharedPreferences.
  Future<void> saveApiKey(String apiKey) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, apiKey.trim());
  }

  /// Clears the stored API key.
  Future<void> clearApiKey() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  /// Checks if an API key is configured.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Validates an API key format.
  ///
  /// RAWG API keys are 32-character hexadecimal strings.
  bool isValidFormat(String apiKey) {
    if (apiKey.isEmpty) return false;
    if (apiKey.length != 32) return false;
    // Check if it's hexadecimal
    return RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(apiKey);
  }
}

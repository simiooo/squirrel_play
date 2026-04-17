import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State for the LocaleCubit.
class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState(this.locale);

  @override
  List<Object?> get props => [locale];
}

/// Cubit for managing the application locale.
///
/// Handles language switching and persists the selected locale
/// to shared preferences. Falls back to device locale on first launch.
class LocaleCubit extends Cubit<LocaleState> {
  static const String _prefsKey = 'app_locale';
  final SharedPreferences _prefs;

  /// Creates a LocaleCubit with the given SharedPreferences instance.
  LocaleCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(const LocaleState(Locale('en'))) {
    _loadSavedLocale();
  }

  /// Loads the saved locale from preferences or uses device locale as fallback.
  void _loadSavedLocale() {
    final savedLocale = _prefs.getString(_prefsKey);
    if (savedLocale != null) {
      emit(LocaleState(Locale(savedLocale)));
    }
    // If no saved locale, keep default (English) - device locale resolution
    // is handled by MaterialApp's localeResolutionCallback
  }

  /// Sets the application locale.
  ///
  /// The locale is persisted to shared preferences and the UI updates
  /// immediately without requiring an app restart.
  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_prefsKey, locale.languageCode);
    emit(LocaleState(locale));
  }

  /// Sets the locale to English.
  Future<void> setEnglish() async {
    await setLocale(const Locale('en'));
  }

  /// Sets the locale to Chinese (Simplified).
  Future<void> setChinese() async {
    await setLocale(const Locale('zh'));
  }

  /// Gets the current locale.
  Locale get currentLocale => state.locale;

  /// Checks if the current locale is English.
  bool get isEnglish => state.locale.languageCode == 'en';

  /// Checks if the current locale is Chinese.
  bool get isChinese => state.locale.languageCode == 'zh';
}

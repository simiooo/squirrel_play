part of 'settings_bloc.dart';

/// Events for the SettingsBloc.
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request loading of settings.
class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

/// Event to save the API key.
class SettingsApiKeySaved extends SettingsEvent {
  final String apiKey;

  const SettingsApiKeySaved({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

/// Event to clear the API key.
class SettingsApiKeyCleared extends SettingsEvent {
  const SettingsApiKeyCleared();
}

/// Event to change the system volume.
class SettingsSystemVolumeChanged extends SettingsEvent {
  final double volume;

  const SettingsSystemVolumeChanged({required this.volume});

  @override
  List<Object?> get props => [volume];
}

/// Event to toggle system mute.
class SettingsSystemMuteToggled extends SettingsEvent {
  const SettingsSystemMuteToggled();
}

/// Event to change the language.
class SettingsLanguageChanged extends SettingsEvent {
  final String languageCode;

  const SettingsLanguageChanged({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}

/// Event to toggle fullscreen setting.
class SettingsFullscreenToggled extends SettingsEvent {
  const SettingsFullscreenToggled();
}

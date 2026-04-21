part of 'settings_bloc.dart';

/// States for the SettingsBloc.
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any loading has occurred.
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state while fetching settings.
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Loaded state with settings values.
class SettingsLoaded extends SettingsState {
  final String? apiKey;
  final bool isApiConnected;
  final double systemVolume;
  final bool isSystemMuted;
  final String languageCode;
  final bool isFullscreen;

  const SettingsLoaded({
    this.apiKey,
    this.isApiConnected = false,
    this.systemVolume = 0.8,
    this.isSystemMuted = false,
    this.languageCode = 'en',
    this.isFullscreen = false,
  });

  SettingsLoaded copyWith({
    String? apiKey,
    bool? isApiConnected,
    double? systemVolume,
    bool? isSystemMuted,
    String? languageCode,
    bool? isFullscreen,
    bool clearApiKey = false,
  }) {
    return SettingsLoaded(
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      isApiConnected: isApiConnected ?? this.isApiConnected,
      systemVolume: systemVolume ?? this.systemVolume,
      isSystemMuted: isSystemMuted ?? this.isSystemMuted,
      languageCode: languageCode ?? this.languageCode,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }

  @override
  List<Object?> get props => [
        apiKey,
        isApiConnected,
        systemVolume,
        isSystemMuted,
        languageCode,
        isFullscreen,
      ];
}

/// Error state when loading fails.
class SettingsError extends SettingsState {
  final String? message;
  final String? localizationKey;
  final String? details;

  const SettingsError({
    this.message,
    this.localizationKey,
    this.details,
  });

  @override
  List<Object?> get props => [message, localizationKey, details];
}

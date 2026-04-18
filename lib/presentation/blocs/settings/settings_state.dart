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
  final double volume;
  final bool isMuted;
  final String languageCode;

  const SettingsLoaded({
    this.apiKey,
    this.isApiConnected = false,
    this.volume = 0.5,
    this.isMuted = false,
    this.languageCode = 'en',
  });

  SettingsLoaded copyWith({
    String? apiKey,
    bool? isApiConnected,
    double? volume,
    bool? isMuted,
    String? languageCode,
    bool clearApiKey = false,
  }) {
    return SettingsLoaded(
      apiKey: clearApiKey ? null : (apiKey ?? this.apiKey),
      isApiConnected: isApiConnected ?? this.isApiConnected,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  List<Object?> get props => [
        apiKey,
        isApiConnected,
        volume,
        isMuted,
        languageCode,
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

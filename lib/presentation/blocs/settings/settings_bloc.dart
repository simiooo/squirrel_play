import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// BLoC for managing the settings page state.
///
/// Handles loading settings, saving API keys, updating sound settings,
/// and language selection.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsApiKeySaved>(_onApiKeySaved);
    on<SettingsApiKeyCleared>(_onApiKeyCleared);
    on<SettingsVolumeChanged>(_onVolumeChanged);
    on<SettingsMuteToggled>(_onMuteToggled);
    on<SettingsLanguageChanged>(_onLanguageChanged);
  }

  void _onLoadRequested(SettingsLoadRequested event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());

    try {
      // TODO: Load actual settings from services
      // For now, emit loaded with default values
      emit(const SettingsLoaded(
        apiKey: null,
        volume: 0.5,
        isMuted: false,
        languageCode: 'en',
      ));
    } catch (e) {
      emit(SettingsError(
        localizationKey: 'errorLoadSettingsFailed',
        details: e.toString(),
      ));
    }
  }

  void _onApiKeySaved(SettingsApiKeySaved event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(apiKey: event.apiKey));
    }
  }

  void _onApiKeyCleared(SettingsApiKeyCleared event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(clearApiKey: true, isApiConnected: false));
    }
  }

  void _onVolumeChanged(SettingsVolumeChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(volume: event.volume));
    }
  }

  void _onMuteToggled(SettingsMuteToggled event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(isMuted: !current.isMuted));
    }
  }

  void _onLanguageChanged(SettingsLanguageChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(languageCode: event.languageCode));
    }
  }
}

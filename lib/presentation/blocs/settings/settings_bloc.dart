import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/services/window_manager_service.dart';
import 'package:squirrel_play/data/services/system_settings_service.dart';
import 'package:squirrel_play/data/services/system_volume_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// BLoC for managing the settings page state.
///
/// Handles loading settings, saving API keys, updating system volume,
/// language selection, and fullscreen preference.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsApiKeySaved>(_onApiKeySaved);
    on<SettingsApiKeyCleared>(_onApiKeyCleared);
    on<SettingsSystemVolumeChanged>(_onSystemVolumeChanged);
    on<SettingsSystemMuteToggled>(_onSystemMuteToggled);
    on<SettingsLanguageChanged>(_onLanguageChanged);
    on<SettingsFullscreenToggled>(_onFullscreenToggled);
  }

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    try {
      final systemSettings = getIt<SystemSettingsService>();
      final systemVolume = getIt<SystemVolumeService>();

      final isFullscreen = systemSettings.loadFullscreenSetting();
      final volume = await systemVolume.getVolume();
      final isMuted = await systemVolume.getMuted();

      emit(SettingsLoaded(
        apiKey: null,
        systemVolume: volume,
        isSystemMuted: isMuted,
        languageCode: 'en',
        isFullscreen: isFullscreen,
      ));
    } catch (e) {
      emit(SettingsError(
        localizationKey: 'errorLoadSettingsFailed',
        details: e.toString(),
      ));
    }
  }

  void _onApiKeySaved(
    SettingsApiKeySaved event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(apiKey: event.apiKey));
    }
  }

  void _onApiKeyCleared(
    SettingsApiKeyCleared event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(clearApiKey: true, isApiConnected: false));
    }
  }

  Future<void> _onSystemVolumeChanged(
    SettingsSystemVolumeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      try {
        await getIt<SystemVolumeService>().setVolume(event.volume);
        emit(current.copyWith(systemVolume: event.volume));
      } catch (e) {
        // Keep current state on error
      }
    }
  }

  Future<void> _onSystemMuteToggled(
    SettingsSystemMuteToggled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      final newMute = !current.isSystemMuted;
      try {
        await getIt<SystemVolumeService>().setMuted(newMute);
        emit(current.copyWith(isSystemMuted: newMute));
      } catch (e) {
        // Keep current state on error
      }
    }
  }

  void _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      emit(current.copyWith(languageCode: event.languageCode));
    }
  }

  Future<void> _onFullscreenToggled(
    SettingsFullscreenToggled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final current = state as SettingsLoaded;
      final newFullscreen = !current.isFullscreen;
      try {
        await getIt<SystemSettingsService>()
            .saveFullscreenSetting(newFullscreen);
        await WindowManagerService().setFullscreen(newFullscreen);
        emit(current.copyWith(isFullscreen: newFullscreen));
      } catch (e) {
        // Keep current state on error
      }
    }
  }
}

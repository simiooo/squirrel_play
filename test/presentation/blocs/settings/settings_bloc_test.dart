import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/system_settings_service.dart';
import 'package:squirrel_play/data/services/system_volume_service.dart';
import 'package:squirrel_play/presentation/blocs/settings/settings_bloc.dart';

class MockSystemSettingsService extends Mock implements SystemSettingsService {}

class MockSystemVolumeService extends Mock implements SystemVolumeService {}

void main() {
  late MockSystemSettingsService mockSystemSettings;
  late MockSystemVolumeService mockSystemVolume;

  setUp(() {
    mockSystemSettings = MockSystemSettingsService();
    mockSystemVolume = MockSystemVolumeService();

    when(() => mockSystemSettings.loadFullscreenSetting()).thenReturn(false);
    when(() => mockSystemVolume.getVolume()).thenAnswer((_) async => 0.8);
    when(() => mockSystemVolume.getMuted()).thenAnswer((_) async => false);

    GetIt.I.registerSingleton<SystemSettingsService>(mockSystemSettings);
    GetIt.I.registerSingleton<SystemVolumeService>(mockSystemVolume);
  });

  tearDown(() {
    GetIt.I.unregister<SystemSettingsService>();
    GetIt.I.unregister<SystemVolumeService>();
  });

  group('SettingsBloc', () {
    group('initial state', () {
      test('is SettingsInitial', () {
        expect(SettingsBloc().state, const SettingsInitial());
      });
    });

    group('SettingsLoadRequested', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsLoaded] when load succeeds',
        build: () => SettingsBloc(),
        act: (bloc) => bloc.add(const SettingsLoadRequested()),
        expect: () => [
          const SettingsLoading(),
          isA<SettingsLoaded>()
              .having((s) => s.systemVolume, 'systemVolume', 0.8)
              .having((s) => s.isSystemMuted, 'isSystemMuted', false)
              .having((s) => s.languageCode, 'languageCode', 'en')
              .having((s) => s.apiKey, 'apiKey', null)
              .having((s) => s.isApiConnected, 'isApiConnected', false)
              .having((s) => s.isFullscreen, 'isFullscreen', false),
        ],
      );
    });

    group('SettingsApiKeySaved', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates apiKey when saved',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(),
        act: (bloc) => bloc.add(const SettingsApiKeySaved(apiKey: 'test-key')),
        expect: () => [
          isA<SettingsLoaded>().having((s) => s.apiKey, 'apiKey', 'test-key'),
        ],
      );
    });

    group('SettingsApiKeyCleared', () {
      blocTest<SettingsBloc, SettingsState>(
        'clears apiKey and sets isApiConnected to false',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(
          apiKey: 'test-key',
          isApiConnected: true,
        ),
        act: (bloc) => bloc.add(const SettingsApiKeyCleared()),
        expect: () => [
          isA<SettingsLoaded>()
              .having((s) => s.apiKey, 'apiKey', null)
              .having((s) => s.isApiConnected, 'isApiConnected', false),
        ],
      );
    });

    group('SettingsSystemVolumeChanged', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates system volume',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(systemVolume: 0.5),
        act: (bloc) =>
            bloc.add(const SettingsSystemVolumeChanged(volume: 0.8)),
        expect: () => [
          isA<SettingsLoaded>()
              .having((s) => s.systemVolume, 'systemVolume', 0.8),
        ],
      );
    });

    group('SettingsSystemMuteToggled', () {
      blocTest<SettingsBloc, SettingsState>(
        'toggles isSystemMuted from false to true',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(isSystemMuted: false),
        act: (bloc) => bloc.add(const SettingsSystemMuteToggled()),
        expect: () => [
          isA<SettingsLoaded>()
              .having((s) => s.isSystemMuted, 'isSystemMuted', true),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'toggles isSystemMuted from true to false',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(isSystemMuted: true),
        act: (bloc) => bloc.add(const SettingsSystemMuteToggled()),
        expect: () => [
          isA<SettingsLoaded>()
              .having((s) => s.isSystemMuted, 'isSystemMuted', false),
        ],
      );
    });

    group('SettingsLanguageChanged', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates languageCode',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(languageCode: 'en'),
        act: (bloc) =>
            bloc.add(const SettingsLanguageChanged(languageCode: 'zh')),
        expect: () => [
          isA<SettingsLoaded>()
              .having((s) => s.languageCode, 'languageCode', 'zh'),
        ],
      );
    });

    group('SettingsFullscreenToggled', () {
      blocTest<SettingsBloc, SettingsState>(
        'toggles isFullscreen from false to true',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(isFullscreen: false),
        act: (bloc) => bloc.add(const SettingsFullscreenToggled()),
        expect: () => [
          isA<SettingsLoaded>()
              .having((s) => s.isFullscreen, 'isFullscreen', true),
        ],
      );
    });
  });
}

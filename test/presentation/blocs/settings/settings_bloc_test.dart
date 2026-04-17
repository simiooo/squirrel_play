import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/presentation/blocs/settings/settings_bloc.dart';

void main() {
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
              .having((s) => s.volume, 'volume', 0.5)
              .having((s) => s.isMuted, 'isMuted', false)
              .having((s) => s.languageCode, 'languageCode', 'en')
              .having((s) => s.apiKey, 'apiKey', null)
              .having((s) => s.isApiConnected, 'isApiConnected', false),
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

    group('SettingsVolumeChanged', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates volume',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(volume: 0.5),
        act: (bloc) => bloc.add(const SettingsVolumeChanged(volume: 0.8)),
        expect: () => [
          isA<SettingsLoaded>().having((s) => s.volume, 'volume', 0.8),
        ],
      );
    });

    group('SettingsMuteToggled', () {
      blocTest<SettingsBloc, SettingsState>(
        'toggles isMuted from false to true',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(isMuted: false),
        act: (bloc) => bloc.add(const SettingsMuteToggled()),
        expect: () => [
          isA<SettingsLoaded>().having((s) => s.isMuted, 'isMuted', true),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'toggles isMuted from true to false',
        build: () => SettingsBloc(),
        seed: () => const SettingsLoaded(isMuted: true),
        act: (bloc) => bloc.add(const SettingsMuteToggled()),
        expect: () => [
          isA<SettingsLoaded>().having((s) => s.isMuted, 'isMuted', false),
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
  });
}

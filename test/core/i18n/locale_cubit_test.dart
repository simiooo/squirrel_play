import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squirrel_play/core/i18n/locale_cubit.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('LocaleCubit', () {
    late MockSharedPreferences mockPrefs;
    late LocaleCubit localeCubit;

    setUp(() {
      mockPrefs = MockSharedPreferences();
    });

    tearDown(() {
      localeCubit.close();
    });

    test('initial state is English locale', () {
      when(() => mockPrefs.getString('app_locale')).thenReturn(null);

      localeCubit = LocaleCubit(prefs: mockPrefs);

      expect(localeCubit.state.locale, const Locale('en'));
      expect(localeCubit.isEnglish, true);
      expect(localeCubit.isChinese, false);
    });

    test('loads saved locale from preferences', () {
      when(() => mockPrefs.getString('app_locale')).thenReturn('zh');

      localeCubit = LocaleCubit(prefs: mockPrefs);

      expect(localeCubit.state.locale, const Locale('zh'));
      expect(localeCubit.isEnglish, false);
      expect(localeCubit.isChinese, true);
    });

    test('setLocale updates state and saves to preferences', () async {
      when(() => mockPrefs.getString('app_locale')).thenReturn(null);
      when(() => mockPrefs.setString('app_locale', 'zh'))
          .thenAnswer((_) async => true);

      localeCubit = LocaleCubit(prefs: mockPrefs);

      await localeCubit.setLocale(const Locale('zh'));

      expect(localeCubit.state.locale, const Locale('zh'));
      verify(() => mockPrefs.setString('app_locale', 'zh')).called(1);
    });

    test('setEnglish sets locale to English', () async {
      when(() => mockPrefs.getString('app_locale')).thenReturn('zh');
      when(() => mockPrefs.setString('app_locale', 'en'))
          .thenAnswer((_) async => true);

      localeCubit = LocaleCubit(prefs: mockPrefs);

      await localeCubit.setEnglish();

      expect(localeCubit.state.locale, const Locale('en'));
      verify(() => mockPrefs.setString('app_locale', 'en')).called(1);
    });

    test('setChinese sets locale to Chinese', () async {
      when(() => mockPrefs.getString('app_locale')).thenReturn(null);
      when(() => mockPrefs.setString('app_locale', 'zh'))
          .thenAnswer((_) async => true);

      localeCubit = LocaleCubit(prefs: mockPrefs);

      await localeCubit.setChinese();

      expect(localeCubit.state.locale, const Locale('zh'));
      verify(() => mockPrefs.setString('app_locale', 'zh')).called(1);
    });

    test('currentLocale returns current locale', () {
      when(() => mockPrefs.getString('app_locale')).thenReturn('zh');

      localeCubit = LocaleCubit(prefs: mockPrefs);

      expect(localeCubit.currentLocale, const Locale('zh'));
    });
  });
}

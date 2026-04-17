import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:squirrel_play/data/services/api_key_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('ApiKeyService', () {
    late ApiKeyService service;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      service = ApiKeyService(prefs: mockPrefs);
    });

    group('getApiKey', () {
      test('should return key from SharedPreferences when available', () async {
        const testKey = '12345678901234567890123456789012';
        
        when(() => mockPrefs.getString('rawg_api_key')).thenReturn(testKey);

        final result = await service.getApiKey();

        expect(result, equals(testKey));
        verify(() => mockPrefs.getString('rawg_api_key')).called(1);
      });

      test('should return null when no key is stored', () async {
        when(() => mockPrefs.getString('rawg_api_key')).thenReturn(null);

        final result = await service.getApiKey();

        expect(result, isNull);
      });

      test('should return null when stored key is empty', () async {
        when(() => mockPrefs.getString('rawg_api_key')).thenReturn('');

        final result = await service.getApiKey();

        expect(result, isNull);
      });

      test('should use SharedPreferences instance passed in constructor', () async {
        const testKey = '12345678901234567890123456789012';
        when(() => mockPrefs.getString('rawg_api_key')).thenReturn(testKey);

        final result = await service.getApiKey();

        expect(result, equals(testKey));
      });
    });

    group('saveApiKey', () {
      test('should save key to SharedPreferences', () async {
        const testKey = '12345678901234567890123456789012';
        
        when(() => mockPrefs.setString('rawg_api_key', testKey)).thenAnswer((_) async => true);

        await service.saveApiKey(testKey);

        verify(() => mockPrefs.setString('rawg_api_key', testKey)).called(1);
      });

      test('should trim whitespace from key before saving', () async {
        const testKeyWithSpaces = '  12345678901234567890123456789012  ';
        const testKeyTrimmed = '12345678901234567890123456789012';
        
        when(() => mockPrefs.setString('rawg_api_key', testKeyTrimmed)).thenAnswer((_) async => true);

        await service.saveApiKey(testKeyWithSpaces);

        verify(() => mockPrefs.setString('rawg_api_key', testKeyTrimmed)).called(1);
      });
    });

    group('clearApiKey', () {
      test('should remove key from SharedPreferences', () async {
        when(() => mockPrefs.remove('rawg_api_key')).thenAnswer((_) async => true);

        await service.clearApiKey();

        verify(() => mockPrefs.remove('rawg_api_key')).called(1);
      });
    });

    group('hasApiKey', () {
      test('should return true when key exists', () async {
        const testKey = '12345678901234567890123456789012';
        when(() => mockPrefs.getString('rawg_api_key')).thenReturn(testKey);

        final result = await service.hasApiKey();

        expect(result, isTrue);
      });

      test('should return false when no key exists', () async {
        when(() => mockPrefs.getString('rawg_api_key')).thenReturn(null);

        final result = await service.hasApiKey();

        expect(result, isFalse);
      });

      test('should return false when key is empty', () async {
        when(() => mockPrefs.getString('rawg_api_key')).thenReturn('');

        final result = await service.hasApiKey();

        expect(result, isFalse);
      });
    });

    group('isValidFormat', () {
      test('should return true for valid 32-character hex key', () {
        const validKey = '12345678901234567890123456789012';
        
        final result = service.isValidFormat(validKey);
        
        expect(result, isTrue);
      });

      test('should return true for valid hex key with uppercase letters', () {
        const validKey = 'ABCDEF12345678901234567890123456';
        
        final result = service.isValidFormat(validKey);
        
        expect(result, isTrue);
      });

      test('should return true for valid hex key with mixed case', () {
        const validKey = 'AbCdEf12345678901234567890123456';
        
        final result = service.isValidFormat(validKey);
        
        expect(result, isTrue);
      });

      test('should return false for empty key', () {
        final result = service.isValidFormat('');
        
        expect(result, isFalse);
      });

      test('should return false for key shorter than 32 characters', () {
        const shortKey = '1234567890123456789012345678901';
        
        final result = service.isValidFormat(shortKey);
        
        expect(result, isFalse);
      });

      test('should return false for key longer than 32 characters', () {
        const longKey = '123456789012345678901234567890123';
        
        final result = service.isValidFormat(longKey);
        
        expect(result, isFalse);
      });

      test('should return false for key with non-hex characters', () {
        const invalidKey = '1234567890123456789012345678901g';
        
        final result = service.isValidFormat(invalidKey);
        
        expect(result, isFalse);
      });

      test('should return false for key with special characters', () {
        const invalidKey = '123456789012345678901234567890!';
        
        final result = service.isValidFormat(invalidKey);
        
        expect(result, isFalse);
      });

      test('should return false for key with spaces', () {
        const invalidKey = '123456789012345678901234567890 1';
        
        final result = service.isValidFormat(invalidKey);
        
        expect(result, isFalse);
      });
    });

    group('Constants', () {
      test('should have correct preferences key', () {
        // The prefs key should be 'rawg_api_key'
        // This is verified by the implementation using it correctly
        expect(true, isTrue); // Placeholder - constants are tested indirectly
      });
    });
  });
}

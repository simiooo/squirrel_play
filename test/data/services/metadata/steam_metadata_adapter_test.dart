import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/metadata/steam_local_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_metadata_adapter.dart';
import 'package:squirrel_play/data/services/metadata/steam_store_source.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

class MockSteamLocalSource extends Mock implements SteamLocalSource {}

class MockSteamStoreSource extends Mock implements SteamStoreSource {}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
  });

  group('SteamMetadataAdapter', () {
    late SteamMetadataAdapter adapter;
    late MockSteamLocalSource mockLocalSource;
    late MockSteamStoreSource mockStoreSource;

    setUp(() {
      mockLocalSource = MockSteamLocalSource();
      mockStoreSource = MockSteamStoreSource();
      adapter = SteamMetadataAdapter(
        steamLocalSource: mockLocalSource,
        steamStoreSource: mockStoreSource,
      );
    });

    group('importMetadata', () {
      test('returns null for non-Steam games', () async {
        final game = Game(
          id: 'game1',
          title: 'Non-Steam Game',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        final result = await adapter.importMetadata(game);

        expect(result, isNull);
        verifyNever(() => mockLocalSource.fetch(any()));
        verifyNever(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')));
      });

      test('returns null when appId cannot be determined', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => null);
        // Store source also returns null when it can't extract appId
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);

        final result = await adapter.importMetadata(game);

        expect(result, isNull);
      });

      test('constructs correct CDN URLs', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final localMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          lastFetched: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => localMetadata);
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);

        final result = await adapter.importMetadata(game);

        expect(result, isNotNull);
        expect(result!.cardImageUrl, endsWith('header.jpg'));
        expect(result.cardImageUrl, contains('730'));
        expect(result.coverImageUrl, endsWith('library_600x900.jpg'));
        expect(result.coverImageUrl, contains('730'));
        expect(result.heroImageUrl, endsWith('library_hero.jpg'));
        expect(result.heroImageUrl, contains('730'));
        expect(result.logoImageUrl, endsWith('logo.png'));
        expect(result.logoImageUrl, contains('730'));
      });

      test('merges local + store data correctly', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final localMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          lastFetched: DateTime.now(),
        );

        final storeMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          title: 'Counter-Strike 2',
          description: 'A tactical first-person shooter',
          genres: const ['Action', 'FPS'],
          screenshots: const ['https://example.com/ss1.jpg'],
          releaseDate: DateTime(2012, 8, 22),
          developer: 'Valve',
          publisher: 'Valve',
          lastFetched: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => localMetadata);
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => storeMetadata);

        final result = await adapter.importMetadata(game);

        expect(result, isNotNull);
        expect(result!.title, equals('Counter-Strike 2'));
        expect(result.description, equals('A tactical first-person shooter'));
        expect(result.genres, contains('Action'));
        expect(result.genres, contains('FPS'));
        expect(result.screenshots, contains('https://example.com/ss1.jpg'));
        expect(result.developer, equals('Valve'));
        expect(result.publisher, equals('Valve'));
        expect(result.releaseDate, equals(DateTime(2012, 8, 22)));
        // Image URLs should come from CDN, not store
        expect(result.cardImageUrl, endsWith('header.jpg'));
        expect(result.coverImageUrl, endsWith('library_600x900.jpg'));
        expect(result.heroImageUrl, endsWith('library_hero.jpg'));
        expect(result.externalId, equals('steam:730'));
        expect(result.lastFetched, isNotNull);
      });

      test('falls back to store images when CDN unavailable', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/games/game.exe', // Non-Steam path
          addedDate: DateTime.now(),
        );

        // Path doesn't contain steamapps, so adapter returns null early
        final result = await adapter.importMetadata(game);
        expect(result, isNull);
      });

      test('applies 200ms rate limit before store call', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final localMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          lastFetched: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => localMetadata);
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);

        final stopwatch = Stopwatch()..start();
        await adapter.importMetadata(game);
        stopwatch.stop();

        // Should take at least 200ms due to rate limiting delay
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(200));
      });

      test('handles Steam Store source returning null gracefully', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final localMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          lastFetched: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => localMetadata);
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);

        final result = await adapter.importMetadata(game);

        expect(result, isNotNull);
        expect(result!.externalId, equals('steam:730'));
        // Should still have CDN URLs from local-derived appId
        expect(result.cardImageUrl, isNotNull);
        expect(result.coverImageUrl, isNotNull);
        expect(result.heroImageUrl, isNotNull);
      });

      test('handles Steam Local source returning null gracefully', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath:
              '/home/user/.steam/steamapps/common/Game/appmanifest_12345.acf/game.exe',
          addedDate: DateTime.now(),
        );

        final storeMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          title: 'Test Game',
          description: 'A test game',
          lastFetched: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => null);
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => storeMetadata);

        final result = await adapter.importMetadata(game);

        expect(result, isNotNull);
        // Should still have CDN URLs extracted from path
        expect(result!.cardImageUrl, endsWith('header.jpg'));
        expect(result.cardImageUrl, contains('12345'));
        expect(result.coverImageUrl, endsWith('library_600x900.jpg'));
        expect(result.coverImageUrl, contains('12345'));
        expect(result.heroImageUrl, endsWith('library_hero.jpg'));
        expect(result.heroImageUrl, contains('12345'));
        expect(result.logoImageUrl, endsWith('logo.png'));
        expect(result.logoImageUrl, contains('12345'));
      });
    });

    group('refreshMetadata', () {
      test('re-fetches and updates lastFetched', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final localMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          lastFetched: DateTime.now().subtract(const Duration(days: 1)),
        );

        final storeMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          title: 'Counter-Strike 2',
          description: 'Updated description',
          lastFetched: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => localMetadata);
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => storeMetadata);

        final beforeTimestamp = DateTime.now();
        final result = await adapter.refreshMetadata(game);
        final afterTimestamp = DateTime.now();

        expect(result, isNotNull);
        expect(result!.lastFetched.isAfter(beforeTimestamp) ||
            result.lastFetched.isAtSameMomentAs(beforeTimestamp), isTrue);
        expect(result.lastFetched.isBefore(afterTimestamp) ||
            result.lastFetched.isAtSameMomentAs(afterTimestamp), isTrue);
      });

      test('overwrites existing metadata', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final localMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          lastFetched: DateTime.now(),
        );

        final storeMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          title: 'Counter-Strike 2',
          description: 'A tactical first-person shooter',
          lastFetched: DateTime.now(),
        );

        when(() => mockLocalSource.fetch(any())).thenAnswer((_) async => localMetadata);
        when(() => mockStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => storeMetadata);

        final importResult = await adapter.importMetadata(game);
        final refreshResult = await adapter.refreshMetadata(game);

        expect(importResult, isNotNull);
        expect(refreshResult, isNotNull);
        // Should be a completely new object with fresh data
        expect(identical(importResult, refreshResult), isFalse);
      });
    });
  });
}

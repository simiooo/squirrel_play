import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_local_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_store_source.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

class MockSteamLocalSource extends Mock implements SteamLocalSource {
  @override
  String get displayName => 'Steam Local';

  @override
  MetadataSourceType get sourceType => MetadataSourceType.steamLocal;
}

class MockSteamStoreSource extends Mock implements SteamStoreSource {
  @override
  String get displayName => 'Steam Store';

  @override
  MetadataSourceType get sourceType => MetadataSourceType.steamStore;
}

class MockRawgSource extends Mock implements RawgSource {
  @override
  String get displayName => 'RAWG';

  @override
  MetadataSourceType get sourceType => MetadataSourceType.rawg;
}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
  });

  group('MetadataAggregator', () {
    late MetadataAggregator aggregator;
    late MockSteamLocalSource mockSteamLocalSource;
    late MockSteamStoreSource mockSteamStoreSource;
    late MockRawgSource mockRawgSource;

    setUp(() {
      mockSteamLocalSource = MockSteamLocalSource();
      mockSteamStoreSource = MockSteamStoreSource();
      mockRawgSource = MockRawgSource();

      aggregator = MetadataAggregator(
        steamLocalSource: mockSteamLocalSource,
        steamStoreSource: mockSteamStoreSource,
        rawgSource: mockRawgSource,
      );
    });

    group('fetchMetadata', () {
      test('should try Steam sources first for Steam games', () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final metadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          description: 'Test game',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamLocalSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockSteamLocalSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => metadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, equals(metadata));
        verify(() => mockSteamLocalSource.canProvide(steamGame, externalId: null)).called(1);
        verify(() => mockSteamLocalSource.fetch(steamGame, externalId: null)).called(1);
        verifyNever(() => mockSteamStoreSource.fetch(any(), externalId: any(named: 'externalId')));
        verifyNever(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')));
      });

      test('should fall back to SteamStoreSource when SteamLocalSource fails', () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final metadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          description: 'Test game from store',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamLocalSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockSteamLocalSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);
        when(() => mockSteamStoreSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockSteamStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => metadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, equals(metadata));
        verify(() => mockSteamLocalSource.fetch(steamGame, externalId: null)).called(1);
        verify(() => mockSteamStoreSource.fetch(steamGame, externalId: null)).called(1);
        verifyNever(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')));
      });

      test('should fall back to RawgSource when Steam sources fail', () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final metadata = GameMetadata(
          gameId: 'game1',
          externalId: 'rawg:67890',
          description: 'Test game from RAWG',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamLocalSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockSteamLocalSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);
        when(() => mockSteamStoreSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockSteamStoreSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);
        when(() => mockRawgSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => metadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, equals(metadata));
        verify(() => mockSteamLocalSource.fetch(steamGame, externalId: null)).called(1);
        verify(() => mockSteamStoreSource.fetch(steamGame, externalId: null)).called(1);
        verify(() => mockRawgSource.fetch(steamGame, externalId: null)).called(1);
      });

      test('should use only RawgSource for non-Steam games', () async {
        final nonSteamGame = Game(
          id: 'game1',
          title: 'Non-Steam Game',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        final metadata = GameMetadata(
          gameId: 'game1',
          externalId: 'rawg:67890',
          description: 'Test game from RAWG',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockRawgSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => metadata);

        final result = await aggregator.fetchMetadata(nonSteamGame);

        expect(result, equals(metadata));
        verify(() => mockRawgSource.canProvide(nonSteamGame, externalId: null)).called(1);
        verify(() => mockRawgSource.fetch(nonSteamGame, externalId: null)).called(1);
        verifyNever(() => mockSteamLocalSource.fetch(any(), externalId: any(named: 'externalId')));
        verifyNever(() => mockSteamStoreSource.fetch(any(), externalId: any(named: 'externalId')));
      });

      test('should return null when all sources fail', () async {
        final game = Game(
          id: 'game1',
          title: 'Test Game',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        when(() => mockRawgSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);

        final result = await aggregator.fetchMetadata(game);

        expect(result, isNull);
      });

      test('should skip sources that cannot provide metadata', () async {
        final game = Game(
          id: 'game1',
          title: 'Test Game',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        final metadata = GameMetadata(
          gameId: 'game1',
          externalId: 'rawg:67890',
          description: 'Test game',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockRawgSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => false);
        // This shouldn't happen in practice, but test the fallback behavior
        // If canProvide returns false, we should still try other sources
        // In this case, there's only RAWG for non-Steam games

        // For this test, let's simulate that RAWG initially says it can't provide
        // but then we have no other sources, so we return null
        final result = await aggregator.fetchMetadata(game);

        expect(result, isNull);
        verify(() => mockRawgSource.canProvide(game, externalId: null)).called(1);
        verifyNever(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')));
      });
    });
  });
}

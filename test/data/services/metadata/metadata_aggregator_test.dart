import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/metadata/metadata_aggregator.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/data/services/metadata/steam_metadata_adapter.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

class MockSteamMetadataAdapter extends Mock implements SteamMetadataAdapter {}

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
    late MockSteamMetadataAdapter mockSteamMetadataAdapter;
    late MockRawgSource mockRawgSource;

    setUp(() {
      mockSteamMetadataAdapter = MockSteamMetadataAdapter();
      mockRawgSource = MockRawgSource();

      aggregator = MetadataAggregator(
        steamMetadataAdapter: mockSteamMetadataAdapter,
        rawgSource: mockRawgSource,
      );
    });

    group('fetchMetadata', () {
      test('should try Steam adapter first for Steam games', () async {
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

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => metadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, equals(metadata));
        verify(() => mockSteamMetadataAdapter.importMetadata(steamGame)).called(1);
        verifyNever(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')));
      });

      test('should fall back to RawgSource when adapter fails', () async {
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

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => null);
        when(() => mockRawgSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => true);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => metadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, equals(metadata));
        verify(() => mockSteamMetadataAdapter.importMetadata(steamGame)).called(1);
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
        verifyNever(() => mockSteamMetadataAdapter.importMetadata(any()));
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

        when(() => mockRawgSource.canProvide(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => false);

        final result = await aggregator.fetchMetadata(game);

        expect(result, isNull);
        verify(() => mockRawgSource.canProvide(game, externalId: null)).called(1);
        verifyNever(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')));
      });

      test('should use adapter when externalId starts with steam:', () async {
        final game = Game(
          id: 'game1',
          title: 'Game with Steam externalId',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        final metadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:730',
          description: 'Steam game metadata',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => metadata);

        final result = await aggregator.fetchMetadata(
          game,
          externalId: 'steam:730',
        );

        expect(result, equals(metadata));
        verify(() => mockSteamMetadataAdapter.importMetadata(game)).called(1);
      });

      test(
          'should fall back to RAWG when Steam metadata is missing description',
          () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final incompleteSteamMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          description: '',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        final rawgMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'rawg:67890',
          title: 'RAWG Title',
          description: 'Test game from RAWG',
          coverImageUrl: 'https://example.com/rawg_cover.jpg',
          cardImageUrl: 'https://example.com/rawg_card.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => incompleteSteamMetadata);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => rawgMetadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, isNotNull);
        expect(result!.description, equals('Test game from RAWG'));
        expect(result.title, equals('RAWG Title'));
        verify(() => mockSteamMetadataAdapter.importMetadata(steamGame)).called(1);
        verify(() => mockRawgSource.fetch(steamGame, externalId: null)).called(1);
      });

      test(
          'should fall back to RAWG when Steam metadata is missing images',
          () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final incompleteSteamMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          description: 'Steam game description',
          lastFetched: DateTime.now(),
        );

        final rawgMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'rawg:67890',
          title: 'RAWG Title',
          description: 'RAWG description',
          coverImageUrl: 'https://example.com/rawg_cover.jpg',
          cardImageUrl: 'https://example.com/rawg_card.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => incompleteSteamMetadata);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => rawgMetadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, isNotNull);
        expect(result!.coverImageUrl, equals('https://example.com/rawg_cover.jpg'));
        expect(result.cardImageUrl, equals('https://example.com/rawg_card.jpg'));
        expect(result.description, equals('Steam game description'));
      });

      test('should keep Steam title when merging with RAWG metadata', () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final steamMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          title: 'Steam Title',
          description: '',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        final rawgMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'rawg:67890',
          title: 'RAWG Title',
          description: 'RAWG description',
          coverImageUrl: 'https://example.com/rawg_cover.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => steamMetadata);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => rawgMetadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, isNotNull);
        expect(result!.title, equals('Steam Title'));
        expect(result.description, equals('RAWG description'));
      });

      test(
          'should return incomplete Steam metadata when RAWG fallback fails',
          () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final incompleteSteamMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          description: '',
          coverImageUrl: 'https://example.com/cover.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => incompleteSteamMetadata);
        when(() => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')))
            .thenAnswer((_) async => null);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, isNotNull);
        expect(result!.description, isEmpty);
        expect(result.coverImageUrl, equals('https://example.com/cover.jpg'));
      });

      test(
          'should return complete Steam metadata without RAWG when complete',
          () async {
        final steamGame = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final completeSteamMetadata = GameMetadata(
          gameId: 'game1',
          externalId: 'steam:12345',
          title: 'Complete Steam Game',
          description: 'Full description',
          coverImageUrl: 'https://example.com/cover.jpg',
          cardImageUrl: 'https://example.com/card.jpg',
          lastFetched: DateTime.now(),
        );

        when(() => mockSteamMetadataAdapter.importMetadata(any()))
            .thenAnswer((_) async => completeSteamMetadata);

        final result = await aggregator.fetchMetadata(steamGame);

        expect(result, isNotNull);
        expect(result!.title, equals('Complete Steam Game'));
        expect(result.description, equals('Full description'));
        expect(result.coverImageUrl, equals('https://example.com/cover.jpg'));
        expect(result.cardImageUrl, equals('https://example.com/card.jpg'));
        verifyNever(
            () => mockRawgSource.fetch(any(), externalId: any(named: 'externalId')));
      });
    });
  });
}

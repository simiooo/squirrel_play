import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';
import 'package:squirrel_play/data/services/api_key_service.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/domain/entities/game.dart';

class MockApiKeyService extends Mock implements ApiKeyService {}

class MockRawgApiClient extends Mock implements RawgApiClient {}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
  });

  group('RawgSource', () {
    late RawgSource source;
    late MockApiKeyService mockApiKeyService;

    setUp(() {
      mockApiKeyService = MockApiKeyService();
      // Default: no API key
      when(() => mockApiKeyService.getApiKey())
          .thenAnswer((_) async => null);
      when(() => mockApiKeyService.saveApiKey(any()))
          .thenAnswer((_) async {});

      source = RawgSource(
        apiKeyService: mockApiKeyService,
      );
    });

    group('sourceType', () {
      test('should return rawg', () {
        expect(source.sourceType, equals(MetadataSourceType.rawg));
      });
    });

    group('displayName', () {
      test('should return RAWG', () {
        expect(source.displayName, equals('RAWG'));
      });
    });

    group('initialize', () {
      test('should initialize when API key is available', () async {
        when(() => mockApiKeyService.getApiKey())
            .thenAnswer((_) async => 'test-api-key');

        await source.initialize();

        expect(source.isInitialized, isTrue);
      });

      test('should not initialize when API key is null', () async {
        when(() => mockApiKeyService.getApiKey())
            .thenAnswer((_) async => null);

        await source.initialize();

        expect(source.isInitialized, isFalse);
      });

      test('should not initialize when API key is empty', () async {
        when(() => mockApiKeyService.getApiKey())
            .thenAnswer((_) async => '');

        await source.initialize();

        expect(source.isInitialized, isFalse);
      });
    });

    group('setApiKey', () {
      test('should set API key and initialize client', () async {
        await source.setApiKey('new-api-key');

        expect(source.isInitialized, isTrue);
        verify(() => mockApiKeyService.saveApiKey('new-api-key')).called(1);
      });
    });

    group('canProvide', () {
      test('should return true when initialized', () async {
        when(() => mockApiKeyService.getApiKey())
            .thenAnswer((_) async => 'test-api-key');

        await source.initialize();

        final game = Game(
          id: 'game1',
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.canProvide(game);

        expect(result, isTrue);
      });

      test('should return false when not initialized', () async {
        final game = Game(
          id: 'game1',
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.canProvide(game);

        expect(result, isFalse);
      });

      test('should auto-initialize when not initialized but API key exists', () async {
        when(() => mockApiKeyService.getApiKey())
            .thenAnswer((_) async => 'test-api-key');

        final game = Game(
          id: 'game1',
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        // canProvide should auto-initialize
        final result = await source.canProvide(game);

        expect(result, isTrue);
        expect(source.isInitialized, isTrue);
      });
    });

    group('fetch', () {
      test('should return null when not initialized', () async {
        final game = Game(
          id: 'game1',
          title: 'Test Game',
          executablePath: '/games/test.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.fetch(game);

        expect(result, isNull);
      });
    });

    group('findMatch', () {
      test('should return null when not initialized', () async {
        final result = await source.findMatch('test.exe');

        expect(result, isNull);
      });
    });

    group('searchManually', () {
      test('should return empty list when not initialized', () async {
        final result = await source.searchManually('test query');

        expect(result, isEmpty);
      });
    });

    group('fetchById', () {
      test('should return null when not initialized', () async {
        final result = await source.fetchById('game1', 12345);

        expect(result, isNull);
      });
    });

    group('externalId format', () {
      test('should use rawg: prefix for externalId in metadata', () {
        // The source type indicates the externalId format
        expect(source.sourceType, equals(MetadataSourceType.rawg));
        // RawgSource produces externalId in format 'rawg:{gameIdInt}'
        // This is verified through the _convertToGameMetadata method
      });
    });

    group('apiClient access', () {
      test('should expose apiClient for backward compatibility', () async {
        when(() => mockApiKeyService.getApiKey())
            .thenAnswer((_) async => 'test-api-key');

        await source.initialize();

        // apiClient should be available after initialization
        expect(source.apiClient, isNotNull);
      });

      test('should have null apiClient when not initialized', () {
        expect(source.apiClient, isNull);
      });
    });

    group('_convertToGameMetadata mappings', () {
      late MockRawgApiClient mockApiClient;

      setUp(() {
        mockApiClient = MockRawgApiClient();
        source.apiClient = mockApiClient;
      });

      test('should map name to title', () async {
        when(() => mockApiClient.getGameDetails(any())).thenAnswer(
          (_) async => const GameDetailResponse(
            id: 123,
            name: 'Test Game Title',
            slug: 'test-game-title',
            description: 'Test description',
            descriptionRaw: 'Test description raw',
            backgroundImage: 'https://example.com/bg.jpg',
            backgroundImageAdditional: 'https://example.com/bg2.jpg',
            released: '2023-01-01',
            rating: 4.5,
            ratingTop: 5,
            genres: [
              Genre(id: 1, name: 'Action', slug: 'action'),
            ],
            developers: [
              Developer(id: 1, name: 'Dev Studio', slug: 'dev-studio'),
            ],
            publishers: [
              Publisher(id: 1, name: 'Pub Co', slug: 'pub-co'),
            ],
          ),
        );

        when(() => mockApiClient.getGameScreenshots(any())).thenAnswer(
          (_) async => [
            const Screenshot(id: 1, url: 'https://example.com/ss1.jpg'),
          ],
        );

        final result = await source.fetchById('game1', 123);

        expect(result, isNotNull);
        expect(result!.title, equals('Test Game Title'));
      });

      test('should map background_image to cardImageUrl', () async {
        when(() => mockApiClient.getGameDetails(any())).thenAnswer(
          (_) async => const GameDetailResponse(
            id: 123,
            name: 'Test Game',
            slug: 'test-game',
            backgroundImage: 'https://example.com/bg.jpg',
          ),
        );

        when(() => mockApiClient.getGameScreenshots(any()))
            .thenAnswer((_) async => []);

        final result = await source.fetchById('game1', 123);

        expect(result, isNotNull);
        expect(result!.cardImageUrl, equals('https://example.com/bg.jpg'));
      });

      test('should map background_image to coverImageUrl', () async {
        when(() => mockApiClient.getGameDetails(any())).thenAnswer(
          (_) async => const GameDetailResponse(
            id: 123,
            name: 'Test Game',
            slug: 'test-game',
            backgroundImage: 'https://example.com/bg.jpg',
          ),
        );

        when(() => mockApiClient.getGameScreenshots(any()))
            .thenAnswer((_) async => []);

        final result = await source.fetchById('game1', 123);

        expect(result, isNotNull);
        expect(result!.coverImageUrl, equals('https://example.com/bg.jpg'));
      });

      test('should use background_image_additional for heroImageUrl', () async {
        when(() => mockApiClient.getGameDetails(any())).thenAnswer(
          (_) async => const GameDetailResponse(
            id: 123,
            name: 'Test Game',
            slug: 'test-game',
            backgroundImage: 'https://example.com/bg.jpg',
            backgroundImageAdditional: 'https://example.com/bg_additional.jpg',
          ),
        );

        when(() => mockApiClient.getGameScreenshots(any()))
            .thenAnswer((_) async => []);

        final result = await source.fetchById('game1', 123);

        expect(result, isNotNull);
        expect(
          result!.heroImageUrl,
          equals('https://example.com/bg_additional.jpg'),
        );
      });

      test('should fall back to background_image when additional is null',
          () async {
        when(() => mockApiClient.getGameDetails(any())).thenAnswer(
          (_) async => const GameDetailResponse(
            id: 123,
            name: 'Test Game',
            slug: 'test-game',
            backgroundImage: 'https://example.com/bg.jpg',
            backgroundImageAdditional: null,
          ),
        );

        when(() => mockApiClient.getGameScreenshots(any()))
            .thenAnswer((_) async => []);

        final result = await source.fetchById('game1', 123);

        expect(result, isNotNull);
        expect(result!.heroImageUrl, equals('https://example.com/bg.jpg'));
      });

      test('should set externalId to rawg:{gameIdInt}', () async {
        when(() => mockApiClient.getGameDetails(any())).thenAnswer(
          (_) async => const GameDetailResponse(
            id: 456,
            name: 'Test Game',
            slug: 'test-game',
            backgroundImage: 'https://example.com/bg.jpg',
          ),
        );

        when(() => mockApiClient.getGameScreenshots(any()))
            .thenAnswer((_) async => []);

        final result = await source.fetchById('game1', 456);

        expect(result, isNotNull);
        expect(result!.externalId, equals('rawg:456'));
      });
    });
  });
}

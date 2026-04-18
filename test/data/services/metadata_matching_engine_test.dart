import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';
import 'package:squirrel_play/data/services/metadata_matching_engine.dart';

class MockRawgApiClient extends Mock implements RawgApiClient {}

void main() {
  group('MetadataMatchingEngine', () {
    late MetadataMatchingEngine engine;
    late MockRawgApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockRawgApiClient();
      engine = MetadataMatchingEngine(apiClient: mockApiClient);
    });

    group('findBestMatch', () {
      test('should return auto-match when first-page score is >= 0.7',
          () async {
        when(() => mockApiClient.searchGamesResponse(any())).thenAnswer(
          (_) async => const RawgSearchResponse<GameSearchResult>(
            count: 1,
            next: null,
            previous: null,
            results: [
              GameSearchResult(
                id: 1,
                name: 'Test Game',
                slug: 'test-game',
                released: '2023-01-01',
                backgroundImage: 'https://example.com/image.jpg',
                rating: 4.5,
              ),
            ],
          ),
        );

        final result = await engine.findBestMatch('Test Game.exe');

        expect(result, isNotNull);
        expect(result!.isAutoMatch, isTrue);
        expect(result.gameName, equals('Test Game'));
        expect(result.confidence, greaterThanOrEqualTo(0.7));
        verify(() => mockApiClient.searchGamesResponse(any())).called(1);
        verifyNever(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        );
      });

      test('should trigger pagination when first-page best score is < 0.7',
          () async {
        when(() => mockApiClient.searchGamesResponse(any())).thenAnswer(
          (_) async => const RawgSearchResponse<GameSearchResult>(
            count: 1,
            next: 'https://api.rawg.io/api/games?search=my-target-game&page=2',
            previous: null,
            results: [
              GameSearchResult(
                id: 1,
                name: 'Something Completely Different',
                slug: 'something-completely-different',
                released: '2023-01-01',
                backgroundImage: 'https://example.com/image.jpg',
                rating: 4.5,
              ),
            ],
          ),
        );

        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
            firstPageResults: any(named: 'firstPageResults'),
            firstPageNextUrl: any(named: 'firstPageNextUrl'),
          ),
        ).thenAnswer(
          (_) async => [
            const GameSearchResult(
              id: 1,
              name: 'Something Completely Different',
              slug: 'something-completely-different',
              released: '2023-01-01',
              backgroundImage: 'https://example.com/image.jpg',
              rating: 4.5,
            ),
            const GameSearchResult(
              id: 2,
              name: 'My Target Game',
              slug: 'my-target-game',
              released: '2022-01-01',
              backgroundImage: 'https://example.com/image2.jpg',
              rating: 4.8,
            ),
          ],
        );

        final result = await engine.findBestMatch('My Target Game.exe');

        expect(result, isNotNull);
        verify(() => mockApiClient.searchGamesResponse(any())).called(1);
        verify(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
            firstPageResults: any(named: 'firstPageResults'),
            firstPageNextUrl: any(named: 'firstPageNextUrl'),
          ),
        ).called(1);
      });

      test('should not call paginated search when usePagination is false',
          () async {
        when(() => mockApiClient.searchGamesResponse(any())).thenAnswer(
          (_) async => const RawgSearchResponse<GameSearchResult>(
            count: 1,
            next: 'https://api.rawg.io/api/games?search=my-game&page=2',
            previous: null,
            results: [
              GameSearchResult(
                id: 1,
                name: 'Something Different',
                slug: 'something-different',
                released: '2023-01-01',
                backgroundImage: 'https://example.com/image.jpg',
                rating: 4.5,
              ),
            ],
          ),
        );

        final result = await engine.findBestMatch(
          'My Game.exe',
          usePagination: false,
        );

        expect(result, isNotNull);
        expect(result!.isAutoMatch, isFalse);
        verify(() => mockApiClient.searchGamesResponse(any())).called(1);
        verifyNever(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
          ),
        );
      });

      test('should return null when no matches found', () async {
        when(() => mockApiClient.searchGamesResponse(any())).thenAnswer(
          (_) async => const RawgSearchResponse<GameSearchResult>(
            count: 0,
            next: null,
            previous: null,
            results: [],
          ),
        );

        final result = await engine.findBestMatch('SomeGame.exe');

        expect(result, isNull);
      });

      test('should return null for empty cleaned filename', () async {
        final result = await engine.findBestMatch('_');

        expect(result, isNull);
      });

      test('should mark match as non-auto when below threshold', () async {
        when(() => mockApiClient.searchGamesResponse(any())).thenAnswer(
          (_) async => const RawgSearchResponse<GameSearchResult>(
            count: 1,
            next: 'https://api.rawg.io/api/games?search=mygame&page=2',
            previous: null,
            results: [
              GameSearchResult(
                id: 1,
                name: 'Very Different Game Name',
                slug: 'very-different-game-name',
                released: '2023-01-01',
                backgroundImage: 'https://example.com/image.jpg',
                rating: 4.5,
              ),
            ],
          ),
        );

        when(
          () => mockApiClient.searchGamesPaginated(
            any(),
            maxPages: any(named: 'maxPages'),
            firstPageResults: any(named: 'firstPageResults'),
            firstPageNextUrl: any(named: 'firstPageNextUrl'),
          ),
        ).thenAnswer(
          (_) async => [
            const GameSearchResult(
              id: 1,
              name: 'Very Different Game Name',
              slug: 'very-different-game-name',
              released: '2023-01-01',
              backgroundImage: 'https://example.com/image.jpg',
              rating: 4.5,
            ),
          ],
        );

        final result = await engine.findBestMatch('MyGame.exe');

        expect(result, isNotNull);
        expect(result!.isAutoMatch, isFalse);
        expect(result.confidence, lessThan(0.7));
      });

      test('should include alternatives in result', () async {
        when(() => mockApiClient.searchGamesResponse(any())).thenAnswer(
          (_) async => const RawgSearchResponse<GameSearchResult>(
            count: 3,
            next: null,
            previous: null,
            results: [
              GameSearchResult(
                id: 1,
                name: 'Test Game',
                slug: 'test-game',
                released: '2023-01-01',
                backgroundImage: 'https://example.com/image1.jpg',
                rating: 4.5,
              ),
              GameSearchResult(
                id: 2,
                name: 'Test Game 2',
                slug: 'test-game-2',
                released: '2022-01-01',
                backgroundImage: 'https://example.com/image2.jpg',
                rating: 4.0,
              ),
              GameSearchResult(
                id: 3,
                name: 'Test Game 3',
                slug: 'test-game-3',
                released: '2021-01-01',
                backgroundImage: 'https://example.com/image3.jpg',
                rating: 3.5,
              ),
            ],
          ),
        );

        final result = await engine.findBestMatch('Test Game.exe');

        expect(result, isNotNull);
        expect(result!.alternatives.length, greaterThanOrEqualTo(2));
      });
    });

    group('searchManually', () {
      test('should search with custom query', () async {
        when(() => mockApiClient.searchGames(any(), pageSize: any(named: 'pageSize')))
            .thenAnswer(
          (_) async => [
            const GameSearchResult(
              id: 1,
              name: 'Custom Result',
              slug: 'custom-result',
              released: '2023-01-01',
              backgroundImage: 'https://example.com/image.jpg',
              rating: 4.5,
            ),
          ],
        );

        final results = await engine.searchManually('custom query');

        expect(results.length, equals(1));
        expect(results[0].gameName, equals('Custom Result'));
      });
    });

    group('similarity scoring', () {
      test('exact match should score 1.0', () async {
        when(() => mockApiClient.searchGamesResponse(any())).thenAnswer(
          (_) async => const RawgSearchResponse<GameSearchResult>(
            count: 1,
            next: null,
            previous: null,
            results: [
              GameSearchResult(
                id: 1,
                name: 'Test Game',
                slug: 'test-game',
              ),
            ],
          ),
        );

        final result = await engine.findBestMatch('Test Game.exe');

        expect(result!.confidence, equals(1.0));
      });

      test('empty query should return null', () async {
        final result = await engine.findBestMatch('');

        expect(result, isNull);
      });
    });
  });
}

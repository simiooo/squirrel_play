import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';

class MockDio extends Mock implements Dio {}

class MockResponse extends Mock implements Response<Map<String, dynamic>> {}

void main() {
  group('RawgApiClient.searchGamesPaginated', () {
    late RawgApiClient client;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      client = RawgApiClient.test(dio: mockDio, apiKey: 'test-key');
    });

    test('should follow next URLs and combine results from multiple pages',
        () async {
      final page1Response = MockResponse();
      final page2Response = MockResponse();

      when(() => page1Response.data).thenReturn({
        'count': 2,
        'next': 'https://api.rawg.io/api/games?search=zelda&page=2',
        'previous': null,
        'results': [
          {
            'id': 1,
            'name': 'Zelda 1',
            'slug': 'zelda-1',
            'released': '2020-01-01',
            'background_image': 'https://example.com/z1.jpg',
            'rating': 4.5,
          },
        ],
      });

      when(() => page2Response.data).thenReturn({
        'count': 2,
        'next': null,
        'previous': 'https://api.rawg.io/api/games?search=zelda&page=1',
        'results': [
          {
            'id': 2,
            'name': 'Zelda 2',
            'slug': 'zelda-2',
            'released': '2021-01-01',
            'background_image': 'https://example.com/z2.jpg',
            'rating': 4.8,
          },
        ],
      });

      when(
        () => mockDio.get(
          '/games',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => page1Response);

      when(
        () => mockDio.get(
          'https://api.rawg.io/api/games?search=zelda&page=2',
        ),
      ).thenAnswer((_) async => page2Response);

      final results = await client.searchGamesPaginated('zelda');

      expect(results.length, equals(2));
      expect(results[0].id, equals(1));
      expect(results[0].name, equals('Zelda 1'));
      expect(results[1].id, equals(2));
      expect(results[1].name, equals('Zelda 2'));

      verify(
        () => mockDio.get(
          '/games',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
      verify(
        () => mockDio.get(
          'https://api.rawg.io/api/games?search=zelda&page=2',
        ),
      ).called(1);
    });

    test('should stop at maxPages', () async {
      final page1Response = MockResponse();

      when(() => page1Response.data).thenReturn({
        'count': 100,
        'next': 'https://api.rawg.io/api/games?search=zelda&page=2',
        'previous': null,
        'results': [
          {
            'id': 1,
            'name': 'Zelda 1',
            'slug': 'zelda-1',
            'released': '2020-01-01',
            'background_image': 'https://example.com/z1.jpg',
            'rating': 4.5,
          },
        ],
      });

      when(
        () => mockDio.get(
          '/games',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => page1Response);

      // maxPages = 1 means only first page
      final results = await client.searchGamesPaginated('zelda', maxPages: 1);

      expect(results.length, equals(1));
      expect(results[0].name, equals('Zelda 1'));

      // Should only call page 1
      verify(
        () => mockDio.get(
          '/games',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
      verifyNever(
        () => mockDio.get(
          'https://api.rawg.io/api/games?search=zelda&page=2',
        ),
      );
    });

    test('should respect rate limiting across pages', () async {
      final page1Response = MockResponse();
      final page2Response = MockResponse();

      when(() => page1Response.data).thenReturn({
        'count': 2,
        'next': 'https://api.rawg.io/api/games?search=zelda&page=2',
        'previous': null,
        'results': [
          {
            'id': 1,
            'name': 'Zelda 1',
            'slug': 'zelda-1',
          },
        ],
      });

      when(() => page2Response.data).thenReturn({
        'count': 2,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 2,
            'name': 'Zelda 2',
            'slug': 'zelda-2',
          },
        ],
      });

      when(
        () => mockDio.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => page1Response);

      when(
        () => mockDio.get(
          'https://api.rawg.io/api/games?search=zelda&page=2',
        ),
      ).thenAnswer((_) async => page2Response);

      final initialCount = client.requestCount;
      await client.searchGamesPaginated('zelda', maxPages: 2);

      // Should have made 2 requests (page 1 + page 2)
      expect(client.requestCount, equals(initialCount + 2));
    });

    test('should handle next == null gracefully', () async {
      final page1Response = MockResponse();

      when(() => page1Response.data).thenReturn({
        'count': 1,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 1,
            'name': 'Zelda 1',
            'slug': 'zelda-1',
            'released': '2020-01-01',
            'background_image': 'https://example.com/z1.jpg',
            'rating': 4.5,
          },
        ],
      });

      when(
        () => mockDio.get(
          '/games',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => page1Response);

      final results = await client.searchGamesPaginated('zelda');

      expect(results.length, equals(1));
      expect(results[0].name, equals('Zelda 1'));

      // Should only call page 1
      verify(
        () => mockDio.get(
          '/games',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });

    test('should default to ApiConfig.maxPaginatedPages when maxPages is null',
        () async {
      final page1Response = MockResponse();

      when(() => page1Response.data).thenReturn({
        'count': 1,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 1,
            'name': 'Zelda 1',
            'slug': 'zelda-1',
          },
        ],
      });

      when(
        () => mockDio.get(
          '/games',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => page1Response);

      final results = await client.searchGamesPaginated('zelda');

      expect(results.length, equals(1));
    });
  });
}

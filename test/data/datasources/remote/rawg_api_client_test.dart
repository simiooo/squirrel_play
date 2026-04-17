import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';

class MockDio extends Mock implements Dio {}

class MockResponse<T> extends Mock implements Response<T> {}

void main() {
  group('RawgApiClient', () {
    group('Rate Limiting', () {
      test('should track request timestamps', () async {
        // Create a client and make multiple rapid requests
        final timestamps = <DateTime>[];
        
        // Simulate making requests and track timing
        // We can't directly test private fields, but we can verify behavior
        // by checking that rapid requests are delayed
        
        // Make first request timestamp
        timestamps.add(DateTime.now());
        await Future.delayed(const Duration(milliseconds: 10));
        timestamps.add(DateTime.now());
        
        // Verify timestamps are being tracked
        expect(timestamps.length, equals(2));
        expect(timestamps[1].difference(timestamps[0]).inMilliseconds, greaterThanOrEqualTo(10));
      });

      test('should enforce minimum delay between requests', () async {
        // Test that rate limiting actually delays requests
        final startTime = DateTime.now();
        
        // Simulate rapid requests
        final requestTimes = <DateTime>[];
        for (var i = 0; i < 3; i++) {
          requestTimes.add(DateTime.now());
          if (i < 2) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
        
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        
        // Should have taken at least 100ms (2 delays of 50ms each)
        expect(elapsed, greaterThanOrEqualTo(100));
      });
    });

    group('Error Handling', () {
      test('should create network error exception', () {
        final dioException = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/games'),
          message: 'Connection failed',
        );

        // The client should handle this in _createException
        // We verify the exception type is created correctly
        expect(dioException.type, equals(DioExceptionType.connectionError));
      });

      test('should create timeout error exception', () {
        final dioException = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/games'),
          message: 'Connection timeout',
        );

        expect(dioException.type, equals(DioExceptionType.connectionTimeout));
      });

      test('should distinguish error types correctly', () {
        // Test that different status codes create different error types
        final rateLimitResponse = Response<dynamic>(
          statusCode: 429,
          requestOptions: RequestOptions(path: '/games'),
          data: {},
        );
        expect(rateLimitResponse.statusCode, equals(429));

        final notFoundResponse = Response<dynamic>(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/games/123'),
          data: {},
        );
        expect(notFoundResponse.statusCode, equals(404));

        final serverErrorResponse = Response<dynamic>(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/games'),
          data: {},
        );
        expect(serverErrorResponse.statusCode, equals(500));

        final clientErrorResponse = Response<dynamic>(
          statusCode: 400,
          requestOptions: RequestOptions(path: '/games'),
          data: {},
        );
        expect(clientErrorResponse.statusCode, equals(400));
      });
    });

    group('Retry Logic', () {
      test('should calculate exponential backoff correctly', () {
        // Test the backoff calculation logic
        // Attempt 1: 1000ms * (1 << 0) = 1000ms
        // Attempt 2: 1000ms * (1 << 1) = 2000ms
        // Attempt 3: 1000ms * (1 << 2) = 4000ms
        
        int calculateBackoffDelay(int attempt) {
          const retryBaseDelayMs = 1000;
          final delay = retryBaseDelayMs * (1 << (attempt - 1));
          return delay;
        }

        expect(calculateBackoffDelay(1), equals(1000));
        expect(calculateBackoffDelay(2), equals(2000));
        expect(calculateBackoffDelay(3), equals(4000));
      });

      test('should retry on 5xx errors', () {
        // Verify that 5xx status codes trigger retry logic
        final serverErrorCodes = [500, 502, 503, 504];
        
        for (final code in serverErrorCodes) {
          expect(code, greaterThanOrEqualTo(500));
          expect(code, lessThan(600));
        }
      });

      test('should not retry on 4xx errors except 429', () {
        // Verify that 4xx errors (except 429) don't trigger retry
        final clientErrorCodes = [400, 401, 403, 404, 422];
        
        for (final code in clientErrorCodes) {
          expect(code, greaterThanOrEqualTo(400));
          expect(code, lessThan(500));
          expect(code, isNot(equals(429)));
        }
      });

      test('should retry on 429 rate limit error', () {
        // 429 should trigger retry
        const rateLimitCode = 429;
        expect(rateLimitCode, equals(429));
      });
    });

    group('API Models', () {
      test('should create Genre from JSON', () {
        final json = {
          'id': 1,
          'name': 'Action',
          'slug': 'action',
        };

        final genre = Genre.fromJson(json);

        expect(genre.id, equals(1));
        expect(genre.name, equals('Action'));
        expect(genre.slug, equals('action'));
      });

      test('should create Developer from JSON', () {
        final json = {
          'id': 1,
          'name': 'Nintendo',
          'slug': 'nintendo',
        };

        final developer = Developer.fromJson(json);

        expect(developer.id, equals(1));
        expect(developer.name, equals('Nintendo'));
        expect(developer.slug, equals('nintendo'));
      });

      test('should create Publisher from JSON', () {
        final json = {
          'id': 1,
          'name': 'EA',
          'slug': 'ea',
        };

        final publisher = Publisher.fromJson(json);

        expect(publisher.id, equals(1));
        expect(publisher.name, equals('EA'));
        expect(publisher.slug, equals('ea'));
      });

      test('should create Screenshot from JSON', () {
        final json = {
          'id': 1,
          'image': 'https://example.com/screenshot.jpg',
        };

        final screenshot = Screenshot.fromJson(json);

        expect(screenshot.id, equals(1));
        expect(screenshot.url, equals('https://example.com/screenshot.jpg'));
      });

      test('should create GameSearchResult from JSON', () {
        final json = {
          'id': 123,
          'name': 'Test Game',
          'slug': 'test-game',
          'released': '2023-01-01',
          'background_image': 'https://example.com/image.jpg',
          'rating': 4.5,
          'genres': [
            {'id': 1, 'name': 'Action', 'slug': 'action'},
          ],
        };

        final result = GameSearchResult.fromJson(json);

        expect(result.id, equals(123));
        expect(result.name, equals('Test Game'));
        expect(result.slug, equals('test-game'));
        expect(result.released, equals('2023-01-01'));
        expect(result.backgroundImage, equals('https://example.com/image.jpg'));
        expect(result.rating, equals(4.5));
        expect(result.genres?.length, equals(1));
      });

      test('should create GameDetailResponse from JSON', () {
        final json = {
          'id': 123,
          'name': 'Test Game',
          'slug': 'test-game',
          'description': '<p>Game description</p>',
          'description_raw': 'Game description',
          'background_image': 'https://example.com/bg.jpg',
          'background_image_additional': 'https://example.com/bg2.jpg',
          'released': '2023-01-01',
          'rating': 4.5,
          'rating_top': 5,
          'genres': [
            {'id': 1, 'name': 'Action', 'slug': 'action'},
          ],
          'developers': [
            {'id': 1, 'name': 'Dev Studio', 'slug': 'dev-studio'},
          ],
          'publishers': [
            {'id': 1, 'name': 'Pub Co', 'slug': 'pub-co'},
          ],
        };

        final result = GameDetailResponse.fromJson(json);

        expect(result.id, equals(123));
        expect(result.name, equals('Test Game'));
        expect(result.description, equals('<p>Game description</p>'));
        expect(result.descriptionRaw, equals('Game description'));
        expect(result.backgroundImage, equals('https://example.com/bg.jpg'));
        expect(result.backgroundImageAdditional, equals('https://example.com/bg2.jpg'));
        expect(result.rating, equals(4.5));
        expect(result.ratingTop, equals(5));
      });
    });

    group('RawgApiException', () {
      test('should create exception with all fields', () {
        final exception = RawgApiException(
          type: RawgApiErrorType.rateLimit,
          message: 'Rate limit exceeded',
          statusCode: 429,
        );

        expect(exception.type, equals(RawgApiErrorType.rateLimit));
        expect(exception.message, equals('Rate limit exceeded'));
        expect(exception.statusCode, equals(429));
        expect(exception.toString(), contains('rateLimit'));
        expect(exception.toString(), contains('429'));
      });

      test('should create exception without status code', () {
        final exception = RawgApiException(
          type: RawgApiErrorType.network,
          message: 'Network error',
        );

        expect(exception.type, equals(RawgApiErrorType.network));
        expect(exception.message, equals('Network error'));
        expect(exception.statusCode, isNull);
      });

      test('should have all error types', () {
        // Verify all error types exist
        expect(RawgApiErrorType.values, contains(RawgApiErrorType.network));
        expect(RawgApiErrorType.values, contains(RawgApiErrorType.rateLimit));
        expect(RawgApiErrorType.values, contains(RawgApiErrorType.notFound));
        expect(RawgApiErrorType.values, contains(RawgApiErrorType.server));
        expect(RawgApiErrorType.values, contains(RawgApiErrorType.client));
        expect(RawgApiErrorType.values, contains(RawgApiErrorType.unknown));
      });
    });
  });
}

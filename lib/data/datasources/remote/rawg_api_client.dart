import 'dart:async';

import 'package:dio/dio.dart';

import 'package:squirrel_play/data/datasources/remote/api_config.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';

/// Exception types for RAWG API errors.
enum RawgApiErrorType {
  /// Network error (no connection)
  network,

  /// Rate limit exceeded (429)
  rateLimit,

  /// Not found (404)
  notFound,

  /// Server error (5xx)
  server,

  /// Client error (4xx)
  client,

  /// Unknown error
  unknown,
}

/// Exception for RAWG API errors.
class RawgApiException implements Exception {
  final RawgApiErrorType type;
  final String message;
  final int? statusCode;

  RawgApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'RawgApiException($type): $message (status: $statusCode)';
}

/// Dio-based HTTP client for RAWG API.
///
/// Features:
/// - Rate limiting (max 5 requests per second)
/// - Retry logic with exponential backoff for 5xx errors
/// - Error handling with specific exception types
/// - 10 second timeout per request
class RawgApiClient {
  late final Dio _dio;
  final String _apiKey;

  // Rate limiting - tracks timestamps of requests in the last second
  final List<DateTime> _requestTimestamps = [];

  RawgApiClient({required String apiKey}) : _apiKey = apiKey {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.requestTimeoutSeconds),
        receiveTimeout: const Duration(seconds: ApiConfig.requestTimeoutSeconds),
        queryParameters: {ApiConfig.keyParam: _apiKey},
      ),
    );

    // Add logging interceptor in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (o) => print('[RAWG API] $o'),
      ),
    );
  }

  /// Searches for games by query string.
  ///
  /// Returns a list of search results.
  /// Throws [RawgApiException] on error.
  Future<List<GameSearchResult>> searchGames(
    String query, {
    int pageSize = ApiConfig.defaultPageSize,
  }) async {
    await _applyRateLimit();

    return _withRetry(() async {
      final response = await _dio.get(
        ApiConfig.gamesEndpoint,
        queryParameters: {
          ApiConfig.searchParam: query,
          ApiConfig.pageSizeParam: pageSize,
        },
      );

      final searchResponse = RawgSearchResponse<GameSearchResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => GameSearchResult.fromJson(json as Map<String, dynamic>),
      );

      return searchResponse.results;
    });
  }

  /// Gets detailed information about a specific game.
  ///
  /// [gameId] is the RAWG game ID.
  /// Throws [RawgApiException] on error.
  Future<GameDetailResponse> getGameDetails(int gameId) async {
    await _applyRateLimit();

    return _withRetry(() async {
      final response = await _dio.get(
        '${ApiConfig.gamesEndpoint}/$gameId',
      );

      return GameDetailResponse.fromJson(response.data as Map<String, dynamic>);
    });
  }

  /// Gets screenshots for a specific game.
  ///
  /// [gameId] is the RAWG game ID.
  /// Throws [RawgApiException] on error.
  Future<List<Screenshot>> getGameScreenshots(int gameId) async {
    await _applyRateLimit();

    return _withRetry(() async {
      final response = await _dio.get(
        '${ApiConfig.gamesEndpoint}/$gameId/screenshots',
      );

      final searchResponse = RawgSearchResponse<Screenshot>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Screenshot.fromJson(json as Map<String, dynamic>),
      );

      return searchResponse.results;
    });
  }

  /// Applies rate limiting by waiting if necessary.
  ///
  /// Ensures no more than 5 requests per second.
  /// Uses a simple approach: track request timestamps and delay if needed.
  Future<void> _applyRateLimit() async {
    final now = DateTime.now();

    // Remove timestamps older than 1 second
    _requestTimestamps.removeWhere(
      (timestamp) => now.difference(timestamp).inMilliseconds > 1000,
    );

    // If we've hit the limit, wait until the oldest request is outside the window
    if (_requestTimestamps.length >= ApiConfig.maxRequestsPerSecond) {
      final oldestTimestamp = _requestTimestamps.first;
      final elapsed = now.difference(oldestTimestamp).inMilliseconds;
      final waitTime = 1000 - elapsed + ApiConfig.minRequestIntervalMs;

      if (waitTime > 0) {
        await Future.delayed(Duration(milliseconds: waitTime));
      }
    }

    // Add current timestamp after any delay
    _requestTimestamps.add(DateTime.now());
  }

  /// Executes a request with retry logic.
  ///
  /// Retries up to 3 times with exponential backoff for 5xx errors.
  Future<T> _withRetry<T>(Future<T> Function() request) async {
    int attempts = 0;

    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        attempts++;

        // Don't retry on client errors (4xx) except 429
        if (e.response?.statusCode != null) {
          final statusCode = e.response!.statusCode!;

          if (statusCode == 429) {
            // Rate limit - wait and retry
            if (attempts < ApiConfig.maxRetries) {
              final delay = _calculateBackoffDelay(attempts);
              await Future.delayed(delay);
              continue;
            }
            throw _createException(e);
          }

          if (statusCode >= 400 && statusCode < 500) {
            throw _createException(e);
          }

          // Server error (5xx) - retry with backoff
          if (statusCode >= 500 && attempts < ApiConfig.maxRetries) {
            final delay = _calculateBackoffDelay(attempts);
            await Future.delayed(delay);
            continue;
          }
        }

        // Network errors - retry
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          if (attempts < ApiConfig.maxRetries) {
            final delay = _calculateBackoffDelay(attempts);
            await Future.delayed(delay);
            continue;
          }
        }

        throw _createException(e);
      }
    }
  }

  /// Calculates exponential backoff delay.
  Duration _calculateBackoffDelay(int attempt) {
    final delay = ApiConfig.retryBaseDelayMs * (1 << (attempt - 1));
    return Duration(milliseconds: delay);
  }

  /// Creates a RawgApiException from a DioException.
  RawgApiException _createException(DioException e) {
    if (e.response?.statusCode != null) {
      final statusCode = e.response!.statusCode!;

      if (statusCode == 429) {
        return RawgApiException(
          type: RawgApiErrorType.rateLimit,
          message: 'Rate limit exceeded. Please try again later.',
          statusCode: statusCode,
        );
      }

      if (statusCode == 404) {
        return RawgApiException(
          type: RawgApiErrorType.notFound,
          message: 'Game not found.',
          statusCode: statusCode,
        );
      }

      if (statusCode >= 500) {
        return RawgApiException(
          type: RawgApiErrorType.server,
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
        );
      }

      if (statusCode >= 400) {
        return RawgApiException(
          type: RawgApiErrorType.client,
          message: 'Invalid request: ${e.message}',
          statusCode: statusCode,
        );
      }
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return RawgApiException(
        type: RawgApiErrorType.network,
        message: 'Network error. Please check your connection.',
      );
    }

    return RawgApiException(
      type: RawgApiErrorType.unknown,
      message: e.message ?? 'Unknown error occurred.',
    );
  }
}



/// Configuration for RAWG API.
///
/// Contains base URL, endpoints, and key management.
class ApiConfig {
  ApiConfig._();

  /// Base URL for RAWG API
  static const String baseUrl = 'https://api.rawg.io/api';

  /// API endpoints
  static const String gamesEndpoint = '/games';

  /// Query parameter names
  static const String keyParam = 'key';
  static const String searchParam = 'search';
  static const String pageSizeParam = 'page_size';

  /// Default page size for search results
  static const int defaultPageSize = 10;

  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 10;

  /// Maximum requests per second (rate limiting)
  static const int maxRequestsPerSecond = 5;

  /// Minimum interval between requests in milliseconds
  static const int minRequestIntervalMs = 200; // 1000ms / 5 = 200ms

  /// Number of retries for failed requests
  static const int maxRetries = 3;

  /// Exponential backoff base delay in milliseconds
  static const int retryBaseDelayMs = 1000;

  /// Maximum number of pages to fetch in paginated search (safety cap)
  static const int maxPaginatedPages = 10;
}

import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';

/// Shared scoring utility for matching game names against search results.
///
/// Used by both [MetadataMatchingEngine] and [RawgBatchSearchService]
/// to avoid duplicated Levenshtein distance and similarity logic.
class MetadataScorer {
  MetadataScorer._();

  /// Scores a list of search results against the cleaned query.
  static List<ScoredResult> scoreResults(
    String cleanedName,
    List<GameSearchResult> results,
  ) {
    final scoredResults = <ScoredResult>[];
    for (final result in results) {
      final score = calculateSimilarity(cleanedName, result.name);
      scoredResults.add(ScoredResult(result: result, score: score));
    }
    return scoredResults;
  }

  /// Calculates string similarity using normalized Levenshtein distance.
  ///
  /// Returns a score between 0.0 and 1.0, where 1.0 is an exact match.
  static double calculateSimilarity(String source, String target) {
    // Normalize both strings
    final s = _normalize(source);
    final t = _normalize(target);

    if (s == t) return 1.0;
    if (s.isEmpty || t.isEmpty) return 0.0;

    // Calculate Levenshtein distance
    final distance = _levenshteinDistance(s, t);
    final maxLength = s.length > t.length ? s.length : t.length;

    // Normalize to 0-1 range
    return 1.0 - (distance / maxLength);
  }

  /// Normalizes a string for comparison.
  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .trim();
  }

  /// Calculates Levenshtein distance between two strings.
  static int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final previousRow = List<int>.filled(t.length + 1, 0);
    final currentRow = List<int>.filled(t.length + 1, 0);

    for (var j = 0; j <= t.length; j++) {
      previousRow[j] = j;
    }

    for (var i = 1; i <= s.length; i++) {
      currentRow[0] = i;

      for (var j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;

        currentRow[j] = [
          previousRow[j] + 1, // deletion
          currentRow[j - 1] + 1, // insertion
          previousRow[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }

      // Swap rows
      for (var j = 0; j <= t.length; j++) {
        previousRow[j] = currentRow[j];
      }
    }

    return previousRow[t.length];
  }

  /// Extracts year from ISO 8601 date string.
  static String? extractYear(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final date = DateTime.parse(dateString);
      return date.year.toString();
    } catch (_) {
      return null;
    }
  }
}

/// Holds a scored search result.
class ScoredResult {
  /// The search result.
  final GameSearchResult result;

  /// Similarity score between 0.0 and 1.0.
  final double score;

  const ScoredResult({required this.result, required this.score});
}

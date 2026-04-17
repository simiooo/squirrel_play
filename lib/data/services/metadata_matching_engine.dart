import 'package:squirrel_play/core/utils/filename_cleaner.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_models.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';

/// Fuzzy matching engine for selecting the best game from search results.
///
/// Uses Levenshtein distance-based similarity scoring to match
/// cleaned filenames against API search results.
class MetadataMatchingEngine {
  final RawgApiClient _apiClient;

  /// Minimum confidence threshold for automatic matching (70%).
  static const double autoMatchThreshold = 0.7;

  MetadataMatchingEngine({required RawgApiClient apiClient})
      : _apiClient = apiClient;

  /// Finds the best matching game for a given filename.
  ///
  /// 1. Cleans the filename using [FilenameCleaner.cleanForSearch()]
  /// 2. Searches RAWG API with the cleaned name
  /// 3. Scores each result using fuzzy string similarity
  /// 4. Returns [MetadataMatchResult] with match details
  ///
  /// [filename] is the original executable filename.
  /// Returns null if no matches found.
  Future<MetadataMatchResult?> findBestMatch(String filename) async {
    // Step 1: Clean the filename
    final cleanedName = FilenameCleaner.cleanForSearch(filename);

    if (cleanedName.isEmpty) {
      return null;
    }

    // Step 2: Search RAWG API
    final searchResults = await _apiClient.searchGames(cleanedName);

    if (searchResults.isEmpty) {
      return null;
    }

    // Step 3: Score each result
    final scoredResults = <_ScoredResult>[];
    for (final result in searchResults) {
      final score = _calculateSimilarity(cleanedName, result.name);
      scoredResults.add(_ScoredResult(result: result, score: score));
    }

    // Sort by score descending
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    // Step 4: Build match result
    final bestMatch = scoredResults.first;
    final isAutoMatch = bestMatch.score >= autoMatchThreshold;

    // Build alternatives list (exclude the best match)
    final alternatives = scoredResults
        .skip(1)
        .take(4) // Top 4 alternatives
        .map((scored) => MetadataAlternative(
              gameId: scored.result.id.toString(),
              gameName: scored.result.name,
              confidence: scored.score,
              coverImageUrl: scored.result.backgroundImage,
              releaseYear: _extractYear(scored.result.released),
            ))
        .toList();

    return MetadataMatchResult(
      gameId: bestMatch.result.id.toString(),
      gameName: bestMatch.result.name,
      confidence: bestMatch.score,
      isAutoMatch: isAutoMatch,
      alternatives: alternatives,
    );
  }

  /// Searches for games manually with a custom query.
  ///
  /// Used when the automatic match fails and user wants to search manually.
  Future<List<MetadataAlternative>> searchManually(String query) async {
    final searchResults = await _apiClient.searchGames(query, pageSize: 20);

    return searchResults.map((result) {
      final score = _calculateSimilarity(query, result.name);
      return MetadataAlternative(
        gameId: result.id.toString(),
        gameName: result.name,
        confidence: score,
        coverImageUrl: result.backgroundImage,
        releaseYear: _extractYear(result.released),
      );
    }).toList();
  }

  /// Calculates string similarity using normalized Levenshtein distance.
  ///
  /// Returns a score between 0.0 and 1.0, where 1.0 is an exact match.
  double _calculateSimilarity(String source, String target) {
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
  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .trim();
  }

  /// Calculates Levenshtein distance between two strings.
  int _levenshteinDistance(String s, String t) {
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
  String? _extractYear(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final date = DateTime.parse(dateString);
      return date.year.toString();
    } catch (_) {
      return null;
    }
  }
}

/// Internal class for holding a scored search result.
class _ScoredResult {
  final GameSearchResult result;
  final double score;

  _ScoredResult({required this.result, required this.score});
}

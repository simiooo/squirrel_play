import 'package:squirrel_play/core/utils/filename_cleaner.dart';
import 'package:squirrel_play/data/datasources/remote/rawg_api_client.dart';
import 'package:squirrel_play/data/services/metadata_scorer.dart';
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
  /// 2. Searches RAWG API with the cleaned name (first page)
  /// 3. Scores each result using fuzzy string similarity
  /// 4. If the best match is below [autoMatchThreshold] and [usePagination]
  ///    is true, fetches additional pages and re-scores.
  /// 5. Returns [MetadataMatchResult] with match details.
  ///
  /// [filename] is the original executable filename.
  /// [usePagination] whether to search additional pages when first-page
  /// confidence is low.
  /// Returns null if no matches found.
  Future<MetadataMatchResult?> findBestMatch(
    String filename, {
    bool usePagination = true,
  }) async {
    // Step 1: Clean the filename
    final cleanedName = FilenameCleaner.cleanForSearch(filename);

    if (cleanedName.isEmpty) {
      return null;
    }

    // Step 2: Search RAWG API (first page)
    final firstPageResponse = await _apiClient.searchGamesResponse(cleanedName);
    final searchResults = firstPageResponse.results;

    if (searchResults.isEmpty) {
      return null;
    }

    // Step 3: Score each result
    var scoredResults = MetadataScorer.scoreResults(cleanedName, searchResults);

    // Sort by score descending
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    // Step 4: Check if we need pagination
    final bestMatch = scoredResults.first;
    if (bestMatch.score < autoMatchThreshold &&
        usePagination &&
        firstPageResponse.next != null) {
      final paginatedResults = await _apiClient.searchGamesPaginated(
        cleanedName,
        maxPages: 3,
        firstPageResults: firstPageResponse.results,
        firstPageNextUrl: firstPageResponse.next,
      );
      if (paginatedResults.length > searchResults.length) {
        scoredResults = MetadataScorer.scoreResults(cleanedName, paginatedResults);
        scoredResults.sort((a, b) => b.score.compareTo(a.score));
      }
    }

    // Step 5: Build match result
    final finalBestMatch = scoredResults.first;
    final isAutoMatch = finalBestMatch.score >= autoMatchThreshold;

    // Build alternatives list (exclude the best match)
    final alternatives = scoredResults
        .skip(1)
        .take(4) // Top 4 alternatives
        .map((scored) => MetadataAlternative(
              gameId: scored.result.id.toString(),
              gameName: scored.result.name,
              confidence: scored.score,
              coverImageUrl: scored.result.backgroundImage,
              releaseYear: MetadataScorer.extractYear(scored.result.released),
            ))
        .toList();

    return MetadataMatchResult(
      gameId: finalBestMatch.result.id.toString(),
      gameName: finalBestMatch.result.name,
      confidence: finalBestMatch.score,
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
      final score = MetadataScorer.calculateSimilarity(query, result.name);
      return MetadataAlternative(
        gameId: result.id.toString(),
        gameName: result.name,
        confidence: score,
        coverImageUrl: result.backgroundImage,
        releaseYear: MetadataScorer.extractYear(result.released),
      );
    }).toList();
  }
}

import 'dart:async';
import 'dart:developer' as developer;

import 'package:squirrel_play/core/utils/filename_cleaner.dart';
import 'package:squirrel_play/data/services/metadata/rawg_source.dart';
import 'package:squirrel_play/data/services/metadata_scorer.dart';
import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';

/// Result of a single game search within a batch operation.
class BatchSearchResult {
  /// The original game name that was searched.
  final String gameName;

  /// The best match found, or null if no matches.
  final MetadataMatchResult? match;

  /// Whether the search succeeded.
  final bool success;

  /// Error message if the search failed.
  final String? error;

  const BatchSearchResult({
    required this.gameName,
    this.match,
    required this.success,
    this.error,
  });
}

/// Coordinates RAWG searches for multiple games with rate limiting
/// and progress reporting.
///
/// Uses [RawgSource] to access the [RawgApiClient] and performs
/// paginated searches for each game name.
class RawgBatchSearchService {
  final RawgSource _rawgSource;

  /// Free-plan request limit per period.
  static const int _freePlanLimit = 20000;

  /// Minimum confidence threshold for automatic matching (70%).
  static const double _autoMatchThreshold = 0.7;

  RawgBatchSearchService({required RawgSource rawgSource})
      : _rawgSource = rawgSource;

  /// Searches for multiple games and emits progress updates.
  ///
  /// For each game name, cleans the filename and performs a paginated
  /// search (up to 3 pages). Rate limiting is handled by the underlying
  /// [RawgApiClient].
  ///
  /// Emits [BatchMetadataProgress] after each game is processed.
  Stream<BatchMetadataProgress> searchMultipleGames(
    List<String> gameNames,
  ) async* {
    var completed = 0;
    var failed = 0;

    for (var i = 0; i < gameNames.length; i++) {
      final gameName = gameNames[i];

      final result = await _processGame(gameName);

      if (result.success) {
        completed++;
      } else {
        failed++;
      }

      // Emit progress after processing
      yield BatchMetadataProgress(
        total: gameNames.length,
        completed: completed,
        failed: failed,
        currentGame: gameName,
        isComplete: false,
      );
    }

    // Emit completion
    yield BatchMetadataProgress(
      total: gameNames.length,
      completed: completed,
      failed: failed,
      currentGame: null,
      isComplete: true,
    );
  }

  /// Synchronous wrapper that collects all results.
  ///
  /// Returns a list of [BatchSearchResult] for each game name.
  Future<List<BatchSearchResult>> searchMultipleGamesSync(
    List<String> gameNames,
  ) async {
    final results = <BatchSearchResult>[];

    for (final gameName in gameNames) {
      final result = await _processGame(gameName);
      results.add(result);
    }

    return results;
  }

  /// Processes a single game search.
  Future<BatchSearchResult> _processGame(String gameName) async {
    // Ensure RAWG source is initialized
    if (!_rawgSource.isInitialized) {
      await _rawgSource.initialize();
      if (!_rawgSource.isInitialized) {
        return BatchSearchResult(
          gameName: gameName,
          success: false,
          error: 'RAWG API not initialized - no API key configured',
        );
      }
    }

    final apiClient = _rawgSource.apiClient!;

    // Check free-plan limit
    if (apiClient.requestCount >= _freePlanLimit) {
      return BatchSearchResult(
        gameName: gameName,
        success: false,
        error:
            'Rate limit exceeded: free plan limit ($_freePlanLimit) reached',
      );
    }

    try {
      // Clean the game name for search
      final cleanedName = FilenameCleaner.cleanForSearch(gameName);

      if (cleanedName.isEmpty) {
        return BatchSearchResult(
          gameName: gameName,
          success: false,
          error: 'Cleaned game name is empty',
        );
      }

      // Perform paginated search (up to 3 pages)
      final searchResults =
          await apiClient.searchGamesPaginated(cleanedName, maxPages: 3);

      if (searchResults.isEmpty) {
        return BatchSearchResult(
          gameName: gameName,
          success: false,
          error: 'No matches found',
        );
      }

      // Score results and find best match
      final scoredResults = MetadataScorer.scoreResults(cleanedName, searchResults);
      scoredResults.sort((a, b) => b.score.compareTo(a.score));

      final bestMatch = scoredResults.first;
      final isAutoMatch = bestMatch.score >= _autoMatchThreshold;

      // Build alternatives list (exclude best match)
      final alternatives = scoredResults
          .skip(1)
          .take(4)
          .map((scored) => MetadataAlternative(
                gameId: scored.result.id.toString(),
                gameName: scored.result.name,
                confidence: scored.score,
                coverImageUrl: scored.result.backgroundImage,
                releaseYear: MetadataScorer.extractYear(scored.result.released),
              ))
          .toList();

      final matchResult = MetadataMatchResult(
        gameId: bestMatch.result.id.toString(),
        gameName: bestMatch.result.name,
        confidence: bestMatch.score,
        isAutoMatch: isAutoMatch,
        alternatives: alternatives,
      );

      return BatchSearchResult(
        gameName: gameName,
        match: matchResult,
        success: true,
      );
    } catch (e) {
      developer.log(
        'RawgBatchSearchService: Error searching for $gameName: $e',
        name: 'RawgBatchSearchService',
      );
      return BatchSearchResult(
        gameName: gameName,
        success: false,
        error: e.toString(),
      );
    }
  }

}

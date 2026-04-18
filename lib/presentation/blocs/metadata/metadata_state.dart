import 'package:equatable/equatable.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';

/// Base class for metadata states.
abstract class MetadataState extends Equatable {
  const MetadataState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any metadata operations.
class MetadataInitial extends MetadataState {
  const MetadataInitial();
}

/// State when metadata is being loaded.
class MetadataLoading extends MetadataState {
  final String? gameId;
  final String? gameTitle;

  const MetadataLoading({this.gameId, this.gameTitle});

  @override
  List<Object?> get props => [gameId, gameTitle];
}

/// State when metadata has been loaded successfully.
class MetadataLoaded extends MetadataState {
  final GameMetadata metadata;

  const MetadataLoaded({required this.metadata});

  @override
  List<Object?> get props => [metadata];
}

/// State when a match requires manual confirmation.
class MetadataMatchRequired extends MetadataState {
  final String gameId;
  final String gameTitle;
  final List<MetadataAlternative> alternatives;

  const MetadataMatchRequired({
    required this.gameId,
    required this.gameTitle,
    required this.alternatives,
  });

  @override
  List<Object?> get props => [gameId, gameTitle, alternatives];
}

/// State when an error occurs during metadata fetching.
class MetadataError extends MetadataState {
  final String gameId;
  final String? message;
  final String? localizationKey;
  final String? details;
  final bool isRetryable;

  const MetadataError({
    required this.gameId,
    this.message,
    this.localizationKey,
    this.details,
    this.isRetryable = true,
  });

  @override
  List<Object?> get props => [gameId, message, localizationKey, details, isRetryable];
}

/// State showing batch fetch progress.
class MetadataBatchProgress extends MetadataState {
  final int total;
  final int completed;
  final int failed;
  final String? currentGame;
  final bool isComplete;
  final String? error;

  const MetadataBatchProgress({
    required this.total,
    required this.completed,
    required this.failed,
    this.currentGame,
    required this.isComplete,
    this.error,
  });

  /// Progress percentage (0.0 to 1.0).
  double get progress => total > 0 ? (completed + failed) / total : 0.0;

  /// Number of remaining games.
  int get remaining => total - completed - failed;

  @override
  List<Object?> get props => [
        total,
        completed,
        failed,
        currentGame,
        isComplete,
        error,
      ];
}

/// State when manual search results are available.
class MetadataSearchResults extends MetadataState {
  final String query;
  final List<MetadataAlternative> results;

  const MetadataSearchResults({
    required this.query,
    required this.results,
  });

  @override
  List<Object?> get props => [query, results];
}

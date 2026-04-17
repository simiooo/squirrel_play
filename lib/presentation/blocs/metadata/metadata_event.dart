import 'package:equatable/equatable.dart';

/// Base class for metadata events.
abstract class MetadataEvent extends Equatable {
  const MetadataEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch metadata for a single game.
class FetchMetadata extends MetadataEvent {
  final String gameId;
  final String gameTitle;
  final String? executablePath;

  const FetchMetadata({
    required this.gameId,
    required this.gameTitle,
    this.executablePath,
  });

  @override
  List<Object?> get props => [gameId, gameTitle, executablePath];
}

/// Event to fetch metadata for multiple games.
class BatchFetchMetadata extends MetadataEvent {
  final List<String> gameIds;

  const BatchFetchMetadata({required this.gameIds});

  @override
  List<Object?> get props => [gameIds];
}

/// Event to perform a manual search for a game.
class ManualSearch extends MetadataEvent {
  final String query;

  const ManualSearch({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event to select a match from manual search.
class SelectMatch extends MetadataEvent {
  final String gameId;
  final String externalId;

  const SelectMatch({
    required this.gameId,
    required this.externalId,
  });

  @override
  List<Object?> get props => [gameId, externalId];
}

/// Event to retry a failed metadata fetch.
class RetryFetch extends MetadataEvent {
  final String gameId;
  final String gameTitle;

  const RetryFetch({
    required this.gameId,
    required this.gameTitle,
  });

  @override
  List<Object?> get props => [gameId, gameTitle];
}

/// Event to clear metadata for a game.
class ClearMetadata extends MetadataEvent {
  final String gameId;

  const ClearMetadata({required this.gameId});

  @override
  List<Object?> get props => [gameId];
}

/// Event to re-fetch metadata for a game (manual refresh).
class RefetchMetadata extends MetadataEvent {
  final String gameId;
  final String gameTitle;

  const RefetchMetadata({
    required this.gameId,
    required this.gameTitle,
  });

  @override
  List<Object?> get props => [gameId, gameTitle];
}

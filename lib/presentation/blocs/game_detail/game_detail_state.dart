part of 'game_detail_bloc.dart';

/// States for the GameDetailBloc.
///
/// These states represent the different UI states of the game detail page.
abstract class GameDetailState extends Equatable {
  const GameDetailState();

  @override
  List<Object?> get props => [];
}

/// Loading state while fetching game details.
class GameDetailLoading extends GameDetailState {
  const GameDetailLoading();
}

/// Loaded state with game and metadata.
class GameDetailLoaded extends GameDetailState {
  final Game game;
  final GameMetadata? metadata;
  final bool isRunning;
  final String? apiConfigError;
  final String? launchError;

  const GameDetailLoaded({
    required this.game,
    this.metadata,
    this.isRunning = false,
    this.apiConfigError,
    this.launchError,
  });

  GameDetailLoaded copyWith({
    Game? game,
    GameMetadata? metadata,
    bool? isRunning,
    String? apiConfigError,
    String? launchError,
  }) {
    return GameDetailLoaded(
      game: game ?? this.game,
      metadata: metadata ?? this.metadata,
      isRunning: isRunning ?? this.isRunning,
      apiConfigError: apiConfigError,
      launchError: launchError,
    );
  }

  @override
  List<Object?> get props => [game, metadata, isRunning, apiConfigError, launchError];
}

/// Types of errors that can occur on the game detail page.
enum GameDetailErrorType {
  gameNotFound,
  loadFailed,
  launchFailed,
  stopFailed,
  deleteFailed,
  updateFailed,
}

/// Error state when loading fails.
class GameDetailError extends GameDetailState {
  final GameDetailErrorType type;
  final String? details;

  const GameDetailError({
    required this.type,
    this.details,
  });

  @override
  List<Object?> get props => [type, details];
}

/// State emitted when the game has been deleted.
class GameDetailDeleted extends GameDetailState {
  const GameDetailDeleted();
}

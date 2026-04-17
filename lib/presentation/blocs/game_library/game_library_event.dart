part of 'game_library_bloc.dart';

/// Base event for GameLibraryBloc.
abstract class GameLibraryEvent extends Equatable {
  const GameLibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load games from the database.
class LoadGames extends GameLibraryEvent {
  const LoadGames();
}

/// Event to refresh the game list.
class Refresh extends GameLibraryEvent {
  const Refresh();
}

/// Event to delete a game from the library.
class DeleteGame extends GameLibraryEvent {
  final String gameId;

  const DeleteGame(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

/// Event when a new game is added (external trigger).
class GameAdded extends GameLibraryEvent {
  const GameAdded();
}

/// Event to retry loading after an error.
class RetryLoad extends GameLibraryEvent {
  const RetryLoad();
}

part of 'game_detail_bloc.dart';

/// Events for the GameDetailBloc.
///
/// These events represent user actions and system notifications
/// that can change the game detail page state.
abstract class GameDetailEvent extends Equatable {
  const GameDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request loading of game details.
class GameDetailLoadRequested extends GameDetailEvent {
  final String gameId;

  const GameDetailLoadRequested(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

/// Event fired when the game's running state changes.
class GameDetailRunningStateChanged extends GameDetailEvent {
  final bool isRunning;

  const GameDetailRunningStateChanged({required this.isRunning});

  @override
  List<Object?> get props => [isRunning];
}

/// Event to request launching the game.
class GameDetailLaunchRequested extends GameDetailEvent {
  const GameDetailLaunchRequested();

  @override
  List<Object?> get props => [];
}

/// Event to request stopping the running game.
class GameDetailStopRequested extends GameDetailEvent {
  const GameDetailStopRequested();

  @override
  List<Object?> get props => [];
}

/// Event to request deleting the game.
class GameDetailDeleteRequested extends GameDetailEvent {
  const GameDetailDeleteRequested();

  @override
  List<Object?> get props => [];
}

/// Event fired when the game has been updated (e.g., after edit).
class GameDetailGameUpdated extends GameDetailEvent {
  final Game game;

  const GameDetailGameUpdated(this.game);

  @override
  List<Object?> get props => [game];
}

/// Event to save edited game details.
class GameDetailEditSaved extends GameDetailEvent {
  final Game game;

  const GameDetailEditSaved(this.game);

  @override
  List<Object?> get props => [game];
}

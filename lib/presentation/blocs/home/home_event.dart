part of 'home_bloc.dart';

/// Events for the HomeBloc.
///
/// These events represent user actions and system notifications
/// that can change the home page state.
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request loading of home rows.
class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

/// Event fired when a game card receives focus.
class HomeGameFocused extends HomeEvent {
  final Game game;
  final int rowIndex;
  final int cardIndex;

  const HomeGameFocused({
    required this.game,
    required this.rowIndex,
    required this.cardIndex,
  });

  @override
  List<Object?> get props => [game, rowIndex, cardIndex];
}

/// Event fired when a game is launched.
class HomeGameLaunched extends HomeEvent {
  final Game game;

  const HomeGameLaunched({required this.game});

  @override
  List<Object?> get props => [game];
}

/// Event fired when a row header receives focus.
class HomeRowHeaderFocused extends HomeEvent {
  final HomeRow row;

  const HomeRowHeaderFocused({required this.row});

  @override
  List<Object?> get props => [row];
}

/// Event fired when a row header is activated (pressed).
class HomeRowHeaderActivated extends HomeEvent {
  final HomeRow row;

  const HomeRowHeaderActivated({required this.row});

  @override
  List<Object?> get props => [row];
}

/// Event fired when the games list changes (add/delete/update).
class HomeGamesChanged extends HomeEvent {
  final List<Game> games;

  const HomeGamesChanged(this.games);

  @override
  List<Object?> get props => [games];
}

/// Event fired when launch status changes.
class HomeLaunchStatusChanged extends HomeEvent {
  final LaunchStatus status;

  const HomeLaunchStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Event to retry loading after an error.
class HomeRetryRequested extends HomeEvent {
  const HomeRetryRequested();
}

/// Event fired when a game's favorite status is toggled.
class HomeFavoriteToggled extends HomeEvent {
  final String gameId;

  const HomeFavoriteToggled({required this.gameId});

  @override
  List<Object?> get props => [gameId];
}

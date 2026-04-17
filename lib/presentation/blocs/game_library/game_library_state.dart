part of 'game_library_bloc.dart';

/// Base state for GameLibraryBloc.
abstract class GameLibraryState extends Equatable {
  const GameLibraryState();

  @override
  List<Object?> get props => [];
}

/// State while loading games.
class LibraryLoading extends GameLibraryState {
  const LibraryLoading();
}

/// State when games are loaded.
class LibraryLoaded extends GameLibraryState {
  final List<Game> games;
  final int focusedIndex;

  const LibraryLoaded({
    required this.games,
    this.focusedIndex = 0,
  });

  LibraryLoaded copyWith({
    List<Game>? games,
    int? focusedIndex,
  }) {
    return LibraryLoaded(
      games: games ?? this.games,
      focusedIndex: focusedIndex ?? this.focusedIndex,
    );
  }

  @override
  List<Object?> get props => [games, focusedIndex];
}

/// State when library is empty.
class LibraryEmpty extends GameLibraryState {
  const LibraryEmpty();
}

/// State when an error occurs loading games.
class LibraryError extends GameLibraryState {
  final String message;

  const LibraryError(this.message);

  @override
  List<Object?> get props => [message];
}

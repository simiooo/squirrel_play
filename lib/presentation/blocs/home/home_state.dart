part of 'home_bloc.dart';

/// States for the HomeBloc.
///
/// These states represent the different UI states of the home page.
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any loading has occurred.
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Loading state while fetching home rows.
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Loaded state with home rows and focused game.
class HomeLoaded extends HomeState {
  final List<HomeRow> rows;
  final Game? focusedGame;
  final GameMetadata? focusedGameMetadata;
  final int focusedRowIndex;
  final int focusedCardIndex;
  final bool isLaunching;

  const HomeLoaded({
    required this.rows,
    this.focusedGame,
    this.focusedGameMetadata,
    this.focusedRowIndex = 0,
    this.focusedCardIndex = 0,
    this.isLaunching = false,
  });

  HomeLoaded copyWith({
    List<HomeRow>? rows,
    Game? focusedGame,
    GameMetadata? focusedGameMetadata,
    int? focusedRowIndex,
    int? focusedCardIndex,
    bool? isLaunching,
  }) {
    return HomeLoaded(
      rows: rows ?? this.rows,
      focusedGame: focusedGame ?? this.focusedGame,
      focusedGameMetadata: focusedGameMetadata ?? this.focusedGameMetadata,
      focusedRowIndex: focusedRowIndex ?? this.focusedRowIndex,
      focusedCardIndex: focusedCardIndex ?? this.focusedCardIndex,
      isLaunching: isLaunching ?? this.isLaunching,
    );
  }

  @override
  List<Object?> get props => [
        rows,
        focusedGame,
        focusedGameMetadata,
        focusedRowIndex,
        focusedCardIndex,
        isLaunching,
      ];
}

/// Empty state when no games exist in the library.
class HomeEmpty extends HomeState {
  final bool hasScanDirectories;

  const HomeEmpty({this.hasScanDirectories = false});

  @override
  List<Object?> get props => [hasScanDirectories];
}

/// Error state when loading fails.
class HomeError extends HomeState {
  final String message;
  final VoidCallback? onRetry;

  const HomeError({
    required this.message,
    this.onRetry,
  });

  @override
  List<Object?> get props => [message];
}

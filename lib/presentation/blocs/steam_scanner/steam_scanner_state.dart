import 'package:equatable/equatable.dart';

import 'package:squirrel_play/data/models/steam_game_data.dart';

/// View model for a Steam game in the UI.
///
/// Combines the core game data with UI state (selection, already added status).
class SteamGameViewModel extends Equatable {
  /// Core game data.
  final SteamGameData data;

  /// Whether this game is selected for import.
  final bool isSelected;

  /// Whether this game is already in the library.
  final bool isAlreadyAdded;

  /// The ID of the existing game in the library, if already added.
  final String? existingGameId;

  const SteamGameViewModel({
    required this.data,
    this.isSelected = false,
    this.isAlreadyAdded = false,
    this.existingGameId,
  });

  /// Creates a copy with the given fields replaced.
  SteamGameViewModel copyWith({
    SteamGameData? data,
    bool? isSelected,
    bool? isAlreadyAdded,
    String? existingGameId,
  }) {
    return SteamGameViewModel(
      data: data ?? this.data,
      isSelected: isSelected ?? this.isSelected,
      isAlreadyAdded: isAlreadyAdded ?? this.isAlreadyAdded,
      existingGameId: existingGameId ?? this.existingGameId,
    );
  }

  @override
  List<Object?> get props => [data.appId, isSelected, isAlreadyAdded, existingGameId];
}

/// Types of loading states for the Steam scanner.
enum SteamScannerLoadingType {
  /// Detecting Steam installation automatically.
  detecting,

  /// Validating a manually specified Steam path.
  validating,

  /// Scanning Steam libraries for games.
  scanning,
}

/// Types of errors that can occur during Steam scanning.
enum SteamScannerErrorType {
  /// Steam installation was not found automatically.
  notFound,

  /// An error occurred while detecting Steam.
  detectError,

  /// The manually specified Steam path is invalid.
  invalidPath,

  /// An error occurred while validating the path.
  validateError,

  /// No Steam path is set when scanning is requested.
  noPathSet,

  /// An error occurred while scanning the library.
  scanError,
}

/// Represents an error that occurred while importing a specific Steam game.
class SteamImportError extends Equatable {
  /// The name of the game that failed to import.
  final String gameName;

  /// The error message, if any.
  final String? error;

  /// Whether the error was due to no executable being found.
  final bool noExecutable;

  const SteamImportError({
    required this.gameName,
    this.error,
    this.noExecutable = false,
  });

  @override
  List<Object?> get props => [gameName, error, noExecutable];
}

/// Base class for Steam scanner states.
abstract class SteamScannerState extends Equatable {
  const SteamScannerState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
class SteamScannerInitial extends SteamScannerState {
  const SteamScannerInitial();
}

/// Loading state while detecting or scanning Steam.
class SteamScannerLoading extends SteamScannerState {
  final SteamScannerLoadingType type;

  const SteamScannerLoading({required this.type});

  @override
  List<Object?> get props => [type];
}

/// Loaded state with list of games.
class SteamScannerLoaded extends SteamScannerState {
  final List<SteamGameViewModel> games;
  final String steamPath;

  const SteamScannerLoaded({
    required this.games,
    required this.steamPath,
  });

  /// Number of selected games.
  int get selectedCount => games.where((g) => g.isSelected).length;

  /// Number of games available for import (not already added).
  int get availableCount => games.where((g) => !g.isAlreadyAdded).length;

  SteamScannerLoaded copyWith({
    List<SteamGameViewModel>? games,
    String? steamPath,
  }) {
    return SteamScannerLoaded(
      games: games ?? this.games,
      steamPath: steamPath ?? this.steamPath,
    );
  }

  @override
  List<Object?> get props => [games, steamPath];
}

/// Error state when Steam is not found or permission error.
class SteamScannerError extends SteamScannerState {
  final SteamScannerErrorType type;
  final String? details;
  final String? currentPath;

  const SteamScannerError({
    required this.type,
    this.details,
    this.currentPath,
  });

  @override
  List<Object?> get props => [type, details, currentPath];
}

/// Importing state with progress.
class SteamScannerImporting extends SteamScannerState {
  final int total;
  final int completed;
  final String? currentGame;

  const SteamScannerImporting({
    required this.total,
    required this.completed,
    this.currentGame,
  });

  double get progress => total > 0 ? completed / total : 0;

  @override
  List<Object?> get props => [total, completed, currentGame];
}

/// Import complete state with results.
class SteamScannerImportComplete extends SteamScannerState {
  final int importedCount;
  final int skippedCount;
  final List<SteamImportError> errors;

  const SteamScannerImportComplete({
    required this.importedCount,
    required this.skippedCount,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [importedCount, skippedCount, errors];
}

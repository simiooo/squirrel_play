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

  const SteamGameViewModel({
    required this.data,
    this.isSelected = false,
    this.isAlreadyAdded = false,
  });

  /// Creates a copy with the given fields replaced.
  SteamGameViewModel copyWith({
    SteamGameData? data,
    bool? isSelected,
    bool? isAlreadyAdded,
  }) {
    return SteamGameViewModel(
      data: data ?? this.data,
      isSelected: isSelected ?? this.isSelected,
      isAlreadyAdded: isAlreadyAdded ?? this.isAlreadyAdded,
    );
  }

  @override
  List<Object?> get props => [data.appId, isSelected, isAlreadyAdded];
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
  final String message;

  const SteamScannerLoading({this.message = 'Detecting Steam...'});

  @override
  List<Object?> get props => [message];
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
  final String message;
  final String? currentPath;

  const SteamScannerError({
    required this.message,
    this.currentPath,
  });

  @override
  List<Object?> get props => [message, currentPath];
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
  final List<String> errors;

  const SteamScannerImportComplete({
    required this.importedCount,
    required this.skippedCount,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [importedCount, skippedCount, errors];
}

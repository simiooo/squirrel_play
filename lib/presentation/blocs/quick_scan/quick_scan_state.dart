import 'package:equatable/equatable.dart';

import 'package:squirrel_play/domain/entities/game.dart';

/// Base class for QuickScan states.
abstract class QuickScanState extends Equatable {
  const QuickScanState();

  @override
  List<Object?> get props => [];
}

/// Initial/idle state before any scan.
class QuickScanIdle extends QuickScanState {
  const QuickScanIdle();
}

/// Scanning state while directories and Steam are being scanned.
class QuickScanScanning extends QuickScanState {
  final String? currentPath;

  const QuickScanScanning({this.currentPath});

  @override
  List<Object?> get props => [currentPath];
}

/// Complete state when new games were found and added.
class QuickScanComplete extends QuickScanState {
  final int newGamesFound;
  final List<Game> addedGames;

  const QuickScanComplete({
    required this.newGamesFound,
    required this.addedGames,
  });

  @override
  List<Object?> get props => [newGamesFound, addedGames];
}

/// State when no new games were found.
class QuickScanNoNewGames extends QuickScanState {
  final bool noDirectoriesConfigured;

  const QuickScanNoNewGames({this.noDirectoriesConfigured = false});

  @override
  List<Object?> get props => [noDirectoriesConfigured];
}

/// Error state when scan fails.
class QuickScanError extends QuickScanState {
  final String? message;
  final String? localizationKey;
  final String? details;

  const QuickScanError({
    this.message,
    this.localizationKey,
    this.details,
  });

  @override
  List<Object?> get props => [message, localizationKey, details];
}

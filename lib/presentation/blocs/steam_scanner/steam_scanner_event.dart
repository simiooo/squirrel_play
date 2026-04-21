import 'package:equatable/equatable.dart';

/// Base class for Steam scanner events.
abstract class SteamScannerEvent extends Equatable {
  const SteamScannerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start auto-detection of Steam installation.
class DetectSteam extends SteamScannerEvent {
  const DetectSteam();
}

/// Event to manually set the Steam installation path.
class SetSteamPath extends SteamScannerEvent {
  final String path;

  const SetSteamPath(this.path);

  @override
  List<Object?> get props => [path];
}

/// Event to scan the Steam library for games.
class ScanLibrary extends SteamScannerEvent {
  const ScanLibrary();
}

/// Event to toggle selection of a specific game.
class ToggleGame extends SteamScannerEvent {
  final String appId;

  const ToggleGame(this.appId);

  @override
  List<Object?> get props => [appId];
}

/// Event to select all games.
class SelectAll extends SteamScannerEvent {
  const SelectAll();
}

/// Event to deselect all games.
class SelectNone extends SteamScannerEvent {
  const SelectNone();
}

/// Event to import selected games to the library.
class ImportSelectedGames extends SteamScannerEvent {
  const ImportSelectedGames();
}

/// Event to refresh metadata for an already-added Steam game.
class RefreshAddedGameMetadata extends SteamScannerEvent {
  final String appId;

  const RefreshAddedGameMetadata(this.appId);

  @override
  List<Object?> get props => [appId];
}

/// Event to reset the scanner to initial state.
class ResetScanner extends SteamScannerEvent {
  const ResetScanner();
}

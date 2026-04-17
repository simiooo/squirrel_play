part of 'add_game_bloc.dart';

/// Base event for AddGameBloc.
abstract class AddGameEvent extends Equatable {
  const AddGameEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start manual add flow.
class StartManualAdd extends AddGameEvent {
  const StartManualAdd();
}

/// Event to start scan directory flow.
class StartScanFlow extends AddGameEvent {
  final List<ScanDirectory>? directories;
  final bool isRescan;

  const StartScanFlow({
    this.directories,
    this.isRescan = false,
  });

  @override
  List<Object?> get props => [directories, isRescan];
}

/// Event when a file is selected in manual add.
class FileSelected extends AddGameEvent {
  final String path;
  final String fileName;

  const FileSelected({
    required this.path,
    required this.fileName,
  });

  @override
  List<Object?> get props => [path, fileName];
}

/// Event when file picker is cancelled.
class FilePickerCancelled extends AddGameEvent {
  const FilePickerCancelled();
}

/// Event when game name is changed in manual add.
class NameChanged extends AddGameEvent {
  final String name;

  const NameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

/// Event to confirm manual add.
class ConfirmManualAdd extends AddGameEvent {
  const ConfirmManualAdd();
}

/// Event when a directory is selected.
class DirectorySelected extends AddGameEvent {
  final String path;
  final String directoryId;

  const DirectorySelected({
    required this.path,
    required this.directoryId,
  });

  @override
  List<Object?> get props => [path, directoryId];
}

/// Event to remove a directory from the list.
class RemoveDirectory extends AddGameEvent {
  final String directoryId;

  const RemoveDirectory(this.directoryId);

  @override
  List<Object?> get props => [directoryId];
}

/// Event to start scanning directories.
class StartScan extends AddGameEvent {
  const StartScan();
}

/// Event when scan progress is updated.
class ScanProgressUpdated extends AddGameEvent {
  final int directoriesScanned;
  final int filesFound;
  final String currentPath;
  final List<DiscoveredExecutableModel> executables;

  const ScanProgressUpdated({
    required this.directoriesScanned,
    required this.filesFound,
    required this.currentPath,
    required this.executables,
  });

  @override
  List<Object?> get props => [directoriesScanned, filesFound, currentPath, executables];
}

/// Event when scan completes successfully.
class ScanCompleted extends AddGameEvent {
  final List<DiscoveredExecutableModel> executables;

  const ScanCompleted({
    required this.executables,
  });

  @override
  List<Object?> get props => [executables];
}

/// Event when scan encounters an error.
class ScanError extends AddGameEvent {
  final String error;

  const ScanError(this.error);

  @override
  List<Object?> get props => [error];
}

/// Event to cancel the current scan.
class CancelScan extends AddGameEvent {
  const CancelScan();
}

/// Event to toggle selection of an executable.
class ToggleExecutable extends AddGameEvent {
  final String path;

  const ToggleExecutable(this.path);

  @override
  List<Object?> get props => [path];
}

/// Event to select all executables.
class SelectAllExecutables extends AddGameEvent {
  const SelectAllExecutables();
}

/// Event to deselect all executables.
class SelectNoneExecutables extends AddGameEvent {
  const SelectNoneExecutables();
}

/// Event to confirm scan selection and add games.
class ConfirmScanSelection extends AddGameEvent {
  const ConfirmScanSelection();
}

/// Event to reset the add game flow.
class ResetAddGame extends AddGameEvent {
  const ResetAddGame();
}

/// Event to switch between tabs.
class SwitchTab extends AddGameEvent {
  final int tabIndex;

  const SwitchTab(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

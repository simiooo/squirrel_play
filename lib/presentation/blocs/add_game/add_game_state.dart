part of 'add_game_bloc.dart';

/// Base state for AddGameBloc.
abstract class AddGameState extends Equatable {
  const AddGameState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
class AddGameInitial extends AddGameState {
  const AddGameInitial();
}

/// State for manual add form.
class ManualAddForm extends AddGameState {
  final String executablePath;
  final String fileName;
  final String name;
  final String? errorMessage;

  const ManualAddForm({
    this.executablePath = '',
    this.fileName = '',
    this.name = '',
    this.errorMessage,
  });

  bool get isValid => name.trim().isNotEmpty && executablePath.isNotEmpty;

  ManualAddForm copyWith({
    String? executablePath,
    String? fileName,
    String? name,
    String? errorMessage,
  }) {
    return ManualAddForm(
      executablePath: executablePath ?? this.executablePath,
      fileName: fileName ?? this.fileName,
      name: name ?? this.name,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [executablePath, fileName, name, errorMessage];
}

/// State for scan directory form.
class ScanDirectoryForm extends AddGameState {
  final List<ScanDirectory> directories;
  final String? errorMessage;
  final bool isRescan;

  const ScanDirectoryForm({
    this.directories = const [],
    this.errorMessage,
    this.isRescan = false,
  });

  bool get canStartScan => directories.isNotEmpty;

  ScanDirectoryForm copyWith({
    List<ScanDirectory>? directories,
    String? errorMessage,
    bool? isRescan,
  }) {
    return ScanDirectoryForm(
      directories: directories ?? this.directories,
      errorMessage: errorMessage,
      isRescan: isRescan ?? this.isRescan,
    );
  }

  @override
  List<Object?> get props => [directories, errorMessage, isRescan];
}

/// State while scanning is in progress.
class Scanning extends AddGameState {
  final List<ScanDirectory> directories;
  final int directoriesScanned;
  final int filesFound;
  final String currentPath;
  final List<DiscoveredExecutableModel> executables;

  const Scanning({
    required this.directories,
    required this.directoriesScanned,
    required this.filesFound,
    required this.currentPath,
    required this.executables,
  });

  Scanning copyWith({
    List<ScanDirectory>? directories,
    int? directoriesScanned,
    int? filesFound,
    String? currentPath,
    List<DiscoveredExecutableModel>? executables,
  }) {
    return Scanning(
      directories: directories ?? this.directories,
      directoriesScanned: directoriesScanned ?? this.directoriesScanned,
      filesFound: filesFound ?? this.filesFound,
      currentPath: currentPath ?? this.currentPath,
      executables: executables ?? this.executables,
    );
  }

  @override
  List<Object?> get props => [
        directories,
        directoriesScanned,
        filesFound,
        currentPath,
        executables,
      ];
}

/// State when scan results are available.
class ScanResults extends AddGameState {
  final List<ScanDirectory> directories;
  final List<DiscoveredExecutableModel> executables;

  const ScanResults({
    required this.directories,
    required this.executables,
  });

  int get selectedCount => executables.where((e) => e.isSelected).length;
  int get totalCount => executables.length;

  ScanResults copyWith({
    List<ScanDirectory>? directories,
    List<DiscoveredExecutableModel>? executables,
  }) {
    return ScanResults(
      directories: directories ?? this.directories,
      executables: executables ?? this.executables,
    );
  }

  @override
  List<Object?> get props => [directories, executables];
}

/// State when scan completed but no executables were found.
class EmptyScanResults extends AddGameState {
  final List<ScanDirectory> directories;

  const EmptyScanResults({
    this.directories = const [],
  });

  @override
  List<Object?> get props => [directories];
}

/// State while adding games to the library.
class Adding extends AddGameState {
  const Adding();
}

/// State for Steam Games tab.
class SteamGamesForm extends AddGameState {
  const SteamGamesForm();
}

/// State when an error occurs.
class AddGameError extends AddGameState {
  final String? message;
  final String? localizationKey;
  final String? details;

  const AddGameError({
    this.message,
    this.localizationKey,
    this.details,
  });

  @override
  List<Object?> get props => [message, localizationKey, details];
}

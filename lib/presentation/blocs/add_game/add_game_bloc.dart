import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'package:squirrel_play/data/models/discovered_executable_model.dart';
import 'package:squirrel_play/data/repositories/home_repository_impl.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/scan_directory.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/repositories/scan_directory_repository.dart';

part 'add_game_state.dart';
part 'add_game_event.dart';

/// BLoC for managing the Add Game dialog state.
///
/// Handles both manual add and scan directory flows.
/// After games are added, triggers metadata fetch via [_metadataRepository].
class AddGameBloc extends Bloc<AddGameEvent, AddGameState> {
  final GameRepository _gameRepository;
  final HomeRepositoryImpl _homeRepository;
  final GameMetadataHandler _metadataHandler;
  final MetadataRepository _metadataRepository;
  final Uuid _uuid;

  AddGameBloc({
    required GameRepository gameRepository,
    required HomeRepositoryImpl homeRepository,
    required GameMetadataHandler metadataHandler,
    ScanDirectoryRepository? scanDirectoryRepository,
    required MetadataRepository metadataRepository,
    Uuid? uuid,
  })  : _gameRepository = gameRepository,
        _homeRepository = homeRepository,
        _metadataHandler = metadataHandler,
        _metadataRepository = metadataRepository,
        _uuid = uuid ?? const Uuid(),
        super(const AddGameInitial()) {
    on<StartManualAdd>(_onStartManualAdd);
    on<StartScanFlow>(_onStartScanFlow);
    on<FileSelected>(_onFileSelected);
    on<FilePickerCancelled>(_onFilePickerCancelled);
    on<NameChanged>(_onNameChanged);
    on<ConfirmManualAdd>(_onConfirmManualAdd);
    on<DirectorySelected>(_onDirectorySelected);
    on<RemoveDirectory>(_onRemoveDirectory);
    on<StartScan>(_onStartScan);
    on<ScanProgressUpdated>(_onScanProgressUpdated);
    on<ScanCompleted>(_onScanCompleted);
    on<ScanError>(_onScanError);
    on<CancelScan>(_onCancelScan);
    on<ToggleExecutable>(_onToggleExecutable);
    on<SelectAllExecutables>(_onSelectAllExecutables);
    on<SelectNoneExecutables>(_onSelectNoneExecutables);
    on<ConfirmScanSelection>(_onConfirmScanSelection);
    on<ResetAddGame>(_onResetAddGame);
    on<SwitchTab>(_onSwitchTab);
  }

  void _onStartManualAdd(StartManualAdd event, Emitter<AddGameState> emit) {
    emit(const ManualAddForm());
  }

  void _onStartScanFlow(StartScanFlow event, Emitter<AddGameState> emit) {
    if (event.isRescan && event.directories != null && event.directories!.isNotEmpty) {
      // Rescan mode: pre-populate with existing directories
      emit(ScanDirectoryForm(
        directories: event.directories!,
        isRescan: true,
      ));
    } else {
      // Normal scan mode: start fresh
      emit(const ScanDirectoryForm());
    }
  }

  void _onFileSelected(FileSelected event, Emitter<AddGameState> emit) async {
    if (state is ManualAddForm) {
      final current = state as ManualAddForm;
      final directoryPath = path.dirname(event.path);
      final context = DirectoryContext(
        executablePath: event.path,
        fileName: event.fileName,
        directoryPath: directoryPath,
      );
      await _metadataHandler.handle(context);
      emit(current.copyWith(
        executablePath: event.path,
        fileName: event.fileName,
        name: context.title ?? event.fileName.replaceAll('.exe', ''),
      ));
    }
  }

  void _onFilePickerCancelled(FilePickerCancelled event, Emitter<AddGameState> emit) {
    // No state change needed - just return to current form state
  }

  void _onNameChanged(NameChanged event, Emitter<AddGameState> emit) {
    if (state is ManualAddForm) {
      final current = state as ManualAddForm;
      emit(current.copyWith(name: event.name));
    }
  }

  void _onConfirmManualAdd(ConfirmManualAdd event, Emitter<AddGameState> emit) async {
    if (state is ManualAddForm) {
      final current = state as ManualAddForm;
      if (current.isValid) {
        emit(const Adding());
        
        try {
          // Check for duplicate
          final exists = await _gameRepository.gameExists(current.executablePath);
          if (exists) {
            // Silently skip duplicate - return to form with no error
            emit(const AddGameInitial());
            return;
          }

          // Run metadata chain to detect platform (e.g., Steam)
          final directoryPath = path.dirname(current.executablePath);
          final metadataContext = DirectoryContext(
            executablePath: current.executablePath,
            fileName: current.fileName,
            directoryPath: directoryPath,
          );
          await _metadataHandler.handle(metadataContext);

          // Create and save the game
          final game = Game(
            id: _uuid.v4(),
            title: current.name.trim(),
            executablePath: current.executablePath,
            addedDate: DateTime.now(),
            platform: metadataContext.steamAppId != null ? 'steam' : null,
            platformGameId: metadataContext.steamAppId,
          );
          
          await _gameRepository.addGame(game);
          
          // Trigger metadata fetch in background
          _triggerMetadataFetch(game);
          
          // Notify home repository to trigger reactive update
          await _homeRepository.notifyGamesChanged();
          
          // Success - return to initial state to close dialog
          emit(const AddGameInitial());
        } catch (e) {
          emit(AddGameError(
            localizationKey: 'errorAddGameFailed',
            details: e.toString(),
          ));
        }
      }
    }
  }

  void _onDirectorySelected(DirectorySelected event, Emitter<AddGameState> emit) {
    if (state is ScanDirectoryForm) {
      final current = state as ScanDirectoryForm;
      final newDirectory = ScanDirectory(
        id: event.directoryId,
        path: event.path,
        addedDate: DateTime.now(),
      );
      emit(current.copyWith(
        directories: [...current.directories, newDirectory],
      ));
    }
  }

  void _onRemoveDirectory(RemoveDirectory event, Emitter<AddGameState> emit) {
    if (state is ScanDirectoryForm) {
      final current = state as ScanDirectoryForm;
      emit(current.copyWith(
        directories: current.directories.where((d) => d.id != event.directoryId).toList(),
      ));
    }
  }

  void _onStartScan(StartScan event, Emitter<AddGameState> emit) {
    if (state is ScanDirectoryForm) {
      final current = state as ScanDirectoryForm;
      emit(Scanning(
        directories: current.directories,
        directoriesScanned: 0,
        filesFound: 0,
        currentPath: '',
        executables: const [],
      ));
    }
  }

  void _onScanProgressUpdated(ScanProgressUpdated event, Emitter<AddGameState> emit) {
    if (state is Scanning) {
      final current = state as Scanning;
      emit(current.copyWith(
        directoriesScanned: event.directoriesScanned,
        filesFound: event.filesFound,
        currentPath: event.currentPath,
        executables: event.executables,
      ));
    }
  }

  void _onScanCompleted(ScanCompleted event, Emitter<AddGameState> emit) {
    if (state is Scanning) {
      final current = state as Scanning;
      final newExecutables = event.executables.where((e) => !e.isAlreadyAdded).toList();
      
      if (newExecutables.isEmpty) {
        emit(EmptyScanResults(
          directories: current.directories,
        ));
      } else {
        emit(ScanResults(
          directories: current.directories,
          executables: newExecutables,
        ));
      }
    }
  }

  void _onScanError(ScanError event, Emitter<AddGameState> emit) {
    if (state is Scanning) {
      final current = state as Scanning;
      emit(ScanDirectoryForm(
        directories: current.directories,
        errorMessage: event.error,
      ));
    }
  }

  void _onCancelScan(CancelScan event, Emitter<AddGameState> emit) {
    if (state is Scanning) {
      final current = state as Scanning;
      emit(ScanDirectoryForm(
        directories: current.directories,
      ));
    }
  }

  void _onToggleExecutable(ToggleExecutable event, Emitter<AddGameState> emit) {
    if (state is ScanResults) {
      final current = state as ScanResults;
      final updatedExecutables = current.executables.map((e) {
        if (e.path == event.path) {
          e.isSelected = !e.isSelected;
        }
        return e;
      }).toList();
      emit(current.copyWith(executables: updatedExecutables));
    }
  }

  void _onSelectAllExecutables(SelectAllExecutables event, Emitter<AddGameState> emit) {
    if (state is ScanResults) {
      final current = state as ScanResults;
      for (final e in current.executables) {
        e.isSelected = true;
      }
      emit(current.copyWith(executables: List.from(current.executables)));
    }
  }

  void _onSelectNoneExecutables(SelectNoneExecutables event, Emitter<AddGameState> emit) {
    if (state is ScanResults) {
      final current = state as ScanResults;
      for (final e in current.executables) {
        e.isSelected = false;
      }
      emit(current.copyWith(executables: List.from(current.executables)));
    }
  }

  void _onConfirmScanSelection(ConfirmScanSelection event, Emitter<AddGameState> emit) async {
    if (state is ScanResults) {
      final current = state as ScanResults;
      emit(const Adding());
      
      try {
        final selectedExecutables = current.executables.where((e) => e.isSelected).toList();
        final addedGames = <Game>[];
        
        for (final executable in selectedExecutables) {
          // Check for duplicate (in case it was added since scan started)
          final exists = await _gameRepository.gameExists(executable.path);
          if (exists) {
            continue; // Silently skip duplicates
          }
          
          // Run the metadata chain to get a suggested title
          final directoryPath = path.dirname(executable.path);
          final context = DirectoryContext(
            executablePath: executable.path,
            fileName: executable.fileName,
            directoryPath: directoryPath,
          );
          await _metadataHandler.handle(context);
          executable.suggestedTitle = context.title;
          executable.platform = context.steamAppId != null ? 'steam' : null;
          executable.platformGameId = context.steamAppId;

          // Create and save the game
          final game = Game(
            id: _uuid.v4(),
            title: executable.suggestedTitle ?? executable.fileName.replaceAll('.exe', ''),
            executablePath: executable.path,
            directoryId: executable.directoryId,
            addedDate: DateTime.now(),
            platform: executable.platform,
            platformGameId: executable.platformGameId,
          );
          
          await _gameRepository.addGame(game);
          addedGames.add(game);
        }
        
        // Trigger metadata fetch for all added games in background
        for (final game in addedGames) {
          _triggerMetadataFetch(game);
        }
        
        // Notify home repository to trigger reactive update
        await _homeRepository.notifyGamesChanged();
        
        // Success - return to initial state to close dialog
        emit(const AddGameInitial());
      } catch (e) {
        emit(AddGameError(
          localizationKey: 'errorAddGamesFailed',
          details: e.toString(),
        ));
      }
    }
  }

  void _onResetAddGame(ResetAddGame event, Emitter<AddGameState> emit) {
    emit(const AddGameInitial());
  }

  void _onSwitchTab(SwitchTab event, Emitter<AddGameState> emit) {
    if (event.tabIndex == 0) {
      emit(const ManualAddForm());
    } else if (event.tabIndex == 1) {
      emit(const ScanDirectoryForm());
    } else if (event.tabIndex == 2) {
      emit(const SteamGamesForm());
    }
  }

  /// Triggers background metadata fetch for a newly added game.
  ///
  /// Non-blocking: errors are swallowed to avoid interrupting the add flow.
  void _triggerMetadataFetch(Game game) {
    // ignore: unawaited_futures
    _fetchMetadataInBackground(game);
  }

  Future<void> _fetchMetadataInBackground(Game game) async {
    try {
      await _metadataRepository.fetchAndCacheMetadata(game.id, game.title);
    } catch (_) {
      // Metadata fetch failure is non-critical during game add.
      // The user can retry later via game detail page.
    }
  }
}

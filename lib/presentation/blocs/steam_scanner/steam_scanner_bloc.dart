import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:squirrel_play/core/services/platform_info.dart';
import 'package:squirrel_play/data/models/steam_game_data.dart';
import 'package:squirrel_play/data/services/steam_detector.dart';
import 'package:squirrel_play/data/services/steam_library_parser.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_bloc.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_event.dart';
import 'package:squirrel_play/presentation/blocs/steam_scanner/steam_scanner_event.dart';
import 'package:squirrel_play/presentation/blocs/steam_scanner/steam_scanner_state.dart';

export 'steam_scanner_event.dart';
export 'steam_scanner_state.dart';

/// BLoC for managing Steam game scanning and import.
///
/// Handles:
/// - Auto-detection of Steam installation
/// - Manual Steam path override
/// - Scanning Steam libraries for games
/// - Duplicate detection against existing library
/// - Importing selected games
/// - Triggering metadata fetch after import
class SteamScannerBloc extends Bloc<SteamScannerEvent, SteamScannerState> {
  final SteamDetector _steamDetector;
  final SteamLibraryParser _libraryParser;
  final SteamManifestParser _manifestParser;
  final GameRepository _gameRepository;
  final MetadataRepository _metadataRepository;
  final MetadataBloc _metadataBloc;
  final Uuid _uuid;

  String? _currentSteamPath;

  SteamScannerBloc({
    required SteamDetector steamDetector,
    required SteamLibraryParser libraryParser,
    required SteamManifestParser manifestParser,
    required GameRepository gameRepository,
    required MetadataRepository metadataRepository,
    required MetadataBloc metadataBloc,
    required PlatformInfo platformInfo,
    Uuid? uuid,
  })  : _steamDetector = steamDetector,
        _libraryParser = libraryParser,
        _manifestParser = manifestParser,
        _gameRepository = gameRepository,
        _metadataRepository = metadataRepository,
        _metadataBloc = metadataBloc,
        _uuid = uuid ?? const Uuid(),
        super(const SteamScannerInitial()) {
    on<DetectSteam>(_onDetectSteam);
    on<SetSteamPath>(_onSetSteamPath);
    on<ScanLibrary>(_onScanLibrary);
    on<ToggleGame>(_onToggleGame);
    on<SelectAll>(_onSelectAll);
    on<SelectNone>(_onSelectNone);
    on<ImportSelectedGames>(_onImportSelectedGames);
    on<ResetScanner>(_onResetScanner);
  }

  Future<void> _onDetectSteam(
    DetectSteam event,
    Emitter<SteamScannerState> emit,
  ) async {
    emit(const SteamScannerLoading(type: SteamScannerLoadingType.detecting));

    try {
      final steamPath = await _steamDetector.detectSteamPath();

      if (steamPath == null) {
        emit(const SteamScannerError(
          type: SteamScannerErrorType.notFound,
        ));
        return;
      }

      _currentSteamPath = steamPath;

      // Automatically start scanning after detection
      add(const ScanLibrary());
    } catch (e) {
      emit(SteamScannerError(
        type: SteamScannerErrorType.detectError,
        details: e.toString(),
      ));
    }
  }

  Future<void> _onSetSteamPath(
    SetSteamPath event,
    Emitter<SteamScannerState> emit,
  ) async {
    emit(const SteamScannerLoading(type: SteamScannerLoadingType.validating));

    try {
      final isValid = await _steamDetector.validateSteamPath(event.path);

      if (!isValid) {
        emit(SteamScannerError(
          type: SteamScannerErrorType.invalidPath,
          currentPath: event.path,
        ));
        return;
      }

      _currentSteamPath = event.path;

      // Automatically start scanning after setting path
      add(const ScanLibrary());
    } catch (e) {
      emit(SteamScannerError(
        type: SteamScannerErrorType.validateError,
        details: e.toString(),
        currentPath: event.path,
      ));
    }
  }

  Future<void> _onScanLibrary(
    ScanLibrary event,
    Emitter<SteamScannerState> emit,
  ) async {
    if (_currentSteamPath == null) {
      emit(const SteamScannerError(
        type: SteamScannerErrorType.noPathSet,
      ));
      return;
    }

    emit(const SteamScannerLoading(type: SteamScannerLoadingType.scanning));

    try {
      // Parse library folders
      final libraryPaths = await _libraryParser.parseLibraryFolders(
        _currentSteamPath!,
      );

      // Scan each library for games
      final allGames = <SteamGameData>[];
      for (final libraryPath in libraryPaths) {
        final manifests = await _manifestParser.scanLibrary(libraryPath);
        allGames.addAll(
          manifests.map(
            (m) => SteamGameData(
              appId: m.appId,
              name: m.name,
              installDir: m.installDir,
              libraryPath: m.libraryPath,
              installSize: m.installSize,
              possibleExecutablePaths: m.possibleExecutablePaths,
            ),
          ),
        );
      }

      // Check for duplicates and create view models
      final viewModels = <SteamGameViewModel>[];
      for (final game in allGames) {
        final isAlreadyAdded = await _isGameAlreadyAdded(game);
        viewModels.add(SteamGameViewModel(
          data: game,
          isSelected: false,
          isAlreadyAdded: isAlreadyAdded,
        ));
      }

      // Sort by name
      viewModels.sort((a, b) => a.data.name.compareTo(b.data.name));

      emit(SteamScannerLoaded(
        games: viewModels,
        steamPath: _currentSteamPath!,
      ));
    } catch (e) {
      emit(SteamScannerError(
        type: SteamScannerErrorType.scanError,
        details: e.toString(),
        currentPath: _currentSteamPath,
      ));
    }
  }

  Future<bool> _isGameAlreadyAdded(SteamGameData game) async {
    // Check if any of the possible executables are already in the library
    for (final executablePath in game.possibleExecutablePaths) {
      final exists = await _gameRepository.gameExists(executablePath);
      if (exists) {
        return true;
      }
    }
    return false;
  }

  void _onToggleGame(
    ToggleGame event,
    Emitter<SteamScannerState> emit,
  ) {
    if (state is SteamScannerLoaded) {
      final current = state as SteamScannerLoaded;
      final updatedGames = current.games.map((game) {
        if (game.data.appId == event.appId && !game.isAlreadyAdded) {
          return game.copyWith(isSelected: !game.isSelected);
        }
        return game;
      }).toList();

      emit(current.copyWith(games: updatedGames));
    }
  }

  void _onSelectAll(
    SelectAll event,
    Emitter<SteamScannerState> emit,
  ) {
    if (state is SteamScannerLoaded) {
      final current = state as SteamScannerLoaded;
      final updatedGames = current.games.map((game) {
        if (!game.isAlreadyAdded) {
          return game.copyWith(isSelected: true);
        }
        return game;
      }).toList();

      emit(current.copyWith(games: updatedGames));
    }
  }

  void _onSelectNone(
    SelectNone event,
    Emitter<SteamScannerState> emit,
  ) {
    if (state is SteamScannerLoaded) {
      final current = state as SteamScannerLoaded;
      final updatedGames = current.games.map((game) {
        return game.copyWith(isSelected: false);
      }).toList();

      emit(current.copyWith(games: updatedGames));
    }
  }

  Future<void> _onImportSelectedGames(
    ImportSelectedGames event,
    Emitter<SteamScannerState> emit,
  ) async {
    if (state is! SteamScannerLoaded) return;

    final current = state as SteamScannerLoaded;
    final selectedGames = current.games
        .where((g) => g.isSelected && !g.isAlreadyAdded)
        .map((g) => g.data)
        .toList();

    if (selectedGames.isEmpty) return;

    emit(SteamScannerImporting(
      total: selectedGames.length,
      completed: 0,
    ));

    int importedCount = 0;
    int skippedCount = 0;
    final errors = <SteamImportError>[];
    final addedGames = <Game>[];

    for (var i = 0; i < selectedGames.length; i++) {
      final steamGame = selectedGames[i];

      emit(SteamScannerImporting(
        total: selectedGames.length,
        completed: i,
        currentGame: steamGame.name,
      ));

      try {
        // Get primary executable
        final executablePath = steamGame.primaryExecutable;
        if (executablePath == null) {
          errors.add(SteamImportError(
            gameName: steamGame.name,
            noExecutable: true,
          ));
          skippedCount++;
          continue;
        }

        // Double-check for duplicate
        final exists = await _gameRepository.gameExists(executablePath);
        if (exists) {
          skippedCount++;
          continue;
        }

        // Create and save the game
        final game = Game(
          id: _uuid.v4(),
          title: steamGame.name,
          executablePath: executablePath,
          addedDate: DateTime.now(),
        );

        await _gameRepository.addGame(game);
        addedGames.add(game);
        importedCount++;

        // Create initial metadata with Steam app ID for metadata enrichment
        final initialMetadata = GameMetadata(
          gameId: game.id,
          externalId: 'steam:${steamGame.appId}',
          description: null,
          coverImageUrl: null,
          heroImageUrl: null,
          genres: const [],
          screenshots: const [],
          lastFetched: DateTime.now(),
        );
        await _metadataRepository.saveMetadata(initialMetadata);

        // Trigger metadata fetch for enrichment
        _metadataBloc.add(FetchMetadata(
          gameId: game.id,
          gameTitle: game.title,
          executablePath: game.executablePath,
        ));
      } catch (e) {
        errors.add(SteamImportError(
          gameName: steamGame.name,
          error: e.toString(),
        ));
        skippedCount++;
      }
    }

    emit(SteamScannerImportComplete(
      importedCount: importedCount,
      skippedCount: skippedCount,
      errors: errors,
    ));
  }

  void _onResetScanner(
    ResetScanner event,
    Emitter<SteamScannerState> emit,
  ) {
    _currentSteamPath = null;
    emit(const SteamScannerInitial());
  }
}

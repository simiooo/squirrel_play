import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:squirrel_play/data/models/discovered_executable_model.dart';
import 'package:squirrel_play/data/models/steam_game_data.dart';
import 'package:squirrel_play/data/repositories/home_repository_impl.dart';
import 'package:squirrel_play/data/services/file_scanner_service.dart';
import 'package:squirrel_play/data/services/steam_detector.dart';
import 'package:squirrel_play/data/services/steam_library_parser.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/repositories/scan_directory_repository.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_bloc.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_event.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/presentation/blocs/quick_scan/quick_scan_event.dart';
import 'package:squirrel_play/presentation/blocs/quick_scan/quick_scan_state.dart';

export 'quick_scan_event.dart';
export 'quick_scan_state.dart';

/// BLoC for managing quick background scanning of directories and Steam libraries.
///
/// Handles:
/// - Parallel scanning of saved directories and Steam libraries
/// - Cross-source deduplication
/// - Duplicate detection against existing games
/// - Auto-adding new games without user confirmation
/// - Triggering metadata fetch for new games
class QuickScanBloc extends Bloc<QuickScanEvent, QuickScanState> {
  final GameRepository _gameRepository;
  final ScanDirectoryRepository _scanDirectoryRepository;
  final FileScannerService _fileScannerService;
  final SteamDetector _steamDetector;
  final SteamLibraryParser _steamLibraryParser;
  final SteamManifestParser _steamManifestParser;
  final HomeRepositoryImpl _homeRepository;
  final MetadataBloc _metadataBloc;
  final MetadataRepository _metadataRepository;
  final Uuid _uuid;

  QuickScanBloc({
    required GameRepository gameRepository,
    required ScanDirectoryRepository scanDirectoryRepository,
    required FileScannerService fileScannerService,
    required SteamDetector steamDetector,
    required SteamLibraryParser steamLibraryParser,
    required SteamManifestParser steamManifestParser,
    required HomeRepositoryImpl homeRepository,
    required MetadataBloc metadataBloc,
    required MetadataRepository metadataRepository,
    required Uuid uuid,
  })  : _gameRepository = gameRepository,
        _scanDirectoryRepository = scanDirectoryRepository,
        _fileScannerService = fileScannerService,
        _steamDetector = steamDetector,
        _steamLibraryParser = steamLibraryParser,
        _steamManifestParser = steamManifestParser,
        _homeRepository = homeRepository,
        _metadataBloc = metadataBloc,
        _metadataRepository = metadataRepository,
        _uuid = uuid,
        super(const QuickScanIdle()) {
    on<QuickScanRequested>(_onQuickScanRequested);
    on<QuickScanCancelled>(_onQuickScanCancelled);
  }

  Future<void> _onQuickScanRequested(
    QuickScanRequested event,
    Emitter<QuickScanState> emit,
  ) async {
    // Debounce: ignore if already scanning
    if (state is QuickScanScanning) {
      return;
    }

    emit(const QuickScanScanning());

    try {
      // Get all saved directories
      final directories = await _scanDirectoryRepository.getAllDirectories();

      // Check if we have any sources to scan
      if (directories.isEmpty) {
        // Still try to detect Steam even without directories
        final steamPath = await _steamDetector.detectSteamPath();
        if (steamPath == null) {
          emit(const QuickScanNoNewGames(noDirectoriesConfigured: true));
          return;
        }
      }

      // Collect all discovered executables
      final allDiscoveredExecutables = <DiscoveredExecutableModel>[];
      final steamGames = <SteamGameData>[];

      // Scan directories and Steam in parallel
      await Future.wait([
        // Scan saved directories
        _scanDirectories(directories, allDiscoveredExecutables, emit),
        // Scan Steam libraries
        _scanSteamLibraries(steamGames),
      ]);

      // Cross-source deduplication: remove duplicate executable paths
      final uniqueExecutables = _deduplicateExecutables(allDiscoveredExecutables);
      final uniqueSteamGames = _deduplicateSteamGames(steamGames);

      // Filter out already-added games
      final newDirectoryGames = await _filterNewGames(uniqueExecutables);
      final newSteamGames = await _filterNewSteamGames(uniqueSteamGames);

      // Combine and add all new games
      final addedGames = <Game>[];

      // Add directory-discovered games
      for (final executable in newDirectoryGames) {
        final game = await _addGameFromExecutable(executable);
        if (game != null) {
          addedGames.add(game);
        }
      }

      // Add Steam games
      for (final steamGame in newSteamGames) {
        final game = await _addGameFromSteam(steamGame);
        if (game != null) {
          addedGames.add(game);
        }
      }

      // Notify home repository to refresh UI
      await _homeRepository.notifyGamesChanged();

      // Emit final state
      if (addedGames.isEmpty) {
        emit(const QuickScanNoNewGames());
      } else {
        emit(QuickScanComplete(
          newGamesFound: addedGames.length,
          addedGames: addedGames,
        ));
        await SoundService.instance.playScanComplete();
      }
    } catch (e) {
      emit(QuickScanError(message: 'Scan failed: $e'));
      await SoundService.instance.playScanError();
    }
  }

  Future<void> _onQuickScanCancelled(
    QuickScanCancelled event,
    Emitter<QuickScanState> emit,
  ) async {
    _fileScannerService.cancelScan();
    emit(const QuickScanIdle());
  }

  /// Scans all saved directories for executables.
  Future<void> _scanDirectories(
    List<dynamic> directories,
    List<DiscoveredExecutableModel> results,
    Emitter<QuickScanState> emit,
  ) async {
    if (directories.isEmpty) return;

    final directoryPaths = directories.map((d) => d.path as String).toList();
    final directoryIds = <String, String>{};
    for (final dir in directories) {
      directoryIds[dir.path as String] = dir.id as String;
    }

    try {
      await for (final progress in _fileScannerService.scanDirectories(
        directoryPaths,
        directoryIds: directoryIds,
      )) {
        if (progress.isComplete) {
          results.addAll(progress.executables);
        } else {
          // Update current path being scanned
          emit(QuickScanScanning(currentPath: progress.currentPath));
        }
      }
    } catch (e) {
      // Partial failure tolerance: log error but continue
      // The scan continues with other directories
    }
  }

  /// Scans Steam libraries for games.
  Future<void> _scanSteamLibraries(List<SteamGameData> results) async {
    try {
      final steamPath = await _steamDetector.detectSteamPath();
      if (steamPath == null) return;

      final libraryPaths = await _steamLibraryParser.parseLibraryFolders(steamPath);

      for (final libraryPath in libraryPaths) {
        try {
          final manifests = await _steamManifestParser.scanLibrary(libraryPath);
          for (final manifest in manifests) {
            // Skip games with null primaryExecutable (same as SteamScannerBloc)
            if (manifest.primaryExecutable == null) continue;

            results.add(SteamGameData(
              appId: manifest.appId,
              name: manifest.name,
              installDir: manifest.installDir,
              libraryPath: manifest.libraryPath,
              installSize: manifest.installSize,
              possibleExecutablePaths: manifest.possibleExecutablePaths,
            ));
          }
        } catch (e) {
          // Partial failure tolerance: continue with other libraries
        }
      }
    } catch (e) {
      // Steam scan failed but directory scan may have succeeded
    }
  }

  /// Removes duplicate executables by path (cross-source deduplication).
  List<DiscoveredExecutableModel> _deduplicateExecutables(
    List<DiscoveredExecutableModel> executables,
  ) {
    final seenPaths = <String>{};
    final unique = <DiscoveredExecutableModel>[];

    for (final exe in executables) {
      final normalizedPath = exe.path.toLowerCase();
      if (!seenPaths.contains(normalizedPath)) {
        seenPaths.add(normalizedPath);
        unique.add(exe);
      }
    }

    return unique;
  }

  /// Removes duplicate Steam games by appId.
  List<SteamGameData> _deduplicateSteamGames(List<SteamGameData> games) {
    final seenAppIds = <String>{};
    final unique = <SteamGameData>[];

    for (final game in games) {
      if (!seenAppIds.contains(game.appId)) {
        seenAppIds.add(game.appId);
        unique.add(game);
      }
    }

    return unique;
  }

  /// Filters out executables that already exist in the database.
  Future<List<DiscoveredExecutableModel>> _filterNewGames(
    List<DiscoveredExecutableModel> executables,
  ) async {
    final newGames = <DiscoveredExecutableModel>[];

    for (final exe in executables) {
      final exists = await _gameRepository.gameExists(exe.path);
      if (!exists) {
        newGames.add(exe);
      }
    }

    return newGames;
  }

  /// Filters out Steam games that already exist in the database.
  Future<List<SteamGameData>> _filterNewSteamGames(
    List<SteamGameData> games,
  ) async {
    final newGames = <SteamGameData>[];

    for (final game in games) {
      // Check if any of the possible executables are already in the library
      bool exists = false;
      for (final executablePath in game.possibleExecutablePaths) {
        final gameExists = await _gameRepository.gameExists(executablePath);
        if (gameExists) {
          exists = true;
          break;
        }
      }

      if (!exists) {
        newGames.add(game);
      }
    }

    return newGames;
  }

  /// Adds a game from a discovered executable.
  Future<Game?> _addGameFromExecutable(DiscoveredExecutableModel exe) async {
    try {
      final game = Game(
        id: _uuid.v4(),
        title: exe.fileName.replaceAll('.exe', ''),
        executablePath: exe.path,
        directoryId: exe.directoryId.isEmpty ? null : exe.directoryId,
        addedDate: DateTime.now(),
      );

      await _gameRepository.addGame(game);

      // Trigger metadata fetch
      _metadataBloc.add(FetchMetadata(
        gameId: game.id,
        gameTitle: game.title,
        executablePath: game.executablePath,
      ));

      return game;
    } catch (e) {
      return null;
    }
  }

  /// Adds a game from Steam data.
  Future<Game?> _addGameFromSteam(SteamGameData steamGame) async {
    try {
      final executablePath = steamGame.primaryExecutable;
      if (executablePath == null) return null;

      // Double-check for duplicate
      final exists = await _gameRepository.gameExists(executablePath);
      if (exists) return null;

      final game = Game(
        id: _uuid.v4(),
        title: steamGame.name,
        executablePath: executablePath,
        addedDate: DateTime.now(),
      );

      await _gameRepository.addGame(game);

      // Create initial metadata with Steam app ID
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

      return game;
    } catch (e) {
      return null;
    }
  }
}

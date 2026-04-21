import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/data/repositories/metadata_repository_impl.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/home_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';

part 'game_detail_state.dart';
part 'game_detail_event.dart';

/// BLoC for managing the game detail page state.
///
/// Handles loading game details, fetching metadata,
/// tracking running state changes, and game actions.
class GameDetailBloc extends Bloc<GameDetailEvent, GameDetailState> {
  final GameRepository _gameRepository;
  final MetadataRepository _metadataRepository;
  final GameLauncher _gameLauncher;
  final HomeRepository _homeRepository;
  StreamSubscription<Map<String, RunningGameInfo>>? _runningGamesSubscription;
  String? _currentGameId;

  GameDetailBloc({
    required GameRepository gameRepository,
    required MetadataRepository metadataRepository,
    required GameLauncher gameLauncher,
    required HomeRepository homeRepository,
  })  : _gameRepository = gameRepository,
        _metadataRepository = metadataRepository,
        _gameLauncher = gameLauncher,
        _homeRepository = homeRepository,
        super(const GameDetailLoading()) {
    on<GameDetailLoadRequested>(_onLoadRequested);
    on<GameDetailRunningStateChanged>(_onRunningStateChanged);
    on<GameDetailLaunchRequested>(_onLaunchRequested);
    on<GameDetailStopRequested>(_onStopRequested);
    on<GameDetailDeleteRequested>(_onDeleteRequested);
    on<GameDetailGameUpdated>(_onGameUpdated);
    on<GameDetailEditSaved>(_onEditSaved);
    on<GameDetailRefetchMetadataRequested>(_onRefetchMetadataRequested);

    // Subscribe to running games stream
    _runningGamesSubscription = _gameLauncher.runningGamesStream.listen(
      _handleRunningGamesUpdate,
    );
  }

  void _handleRunningGamesUpdate(Map<String, RunningGameInfo> runningGames) {
    final gameId = _currentGameId ??
        (state is GameDetailLoaded
            ? (state as GameDetailLoaded).game.id
            : null);
    if (gameId == null) return;
    final isRunning = runningGames.containsKey(gameId);
    add(GameDetailRunningStateChanged(isRunning: isRunning));
  }

  @override
  Future<void> close() {
    _runningGamesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    GameDetailLoadRequested event,
    Emitter<GameDetailState> emit,
  ) async {
    emit(const GameDetailLoading());
    _currentGameId = event.gameId;

    try {
      final game = await _gameRepository.getGameById(event.gameId);

      if (game == null) {
        emit(const GameDetailError(type: GameDetailErrorType.gameNotFound));
        return;
      }

      GameMetadata? metadata;
      String? apiConfigError;
      try {
        metadata = await _metadataRepository.getMetadataForGame(event.gameId);
      } on RawgApiNotConfiguredException catch (e) {
        apiConfigError = e.toString();
        metadata = null;
      } catch (e) {
        // Metadata fetch failure is non-critical
        metadata = null;
      }

      final isRunning = _gameLauncher.isGameRunning(game.id);

      emit(GameDetailLoaded(
        game: game,
        metadata: metadata,
        isRunning: isRunning,
        apiConfigError: apiConfigError,
      ));
    } catch (e) {
      emit(GameDetailError(
        type: GameDetailErrorType.loadFailed,
        details: e.toString(),
      ));
    }
  }

  void _onRunningStateChanged(
    GameDetailRunningStateChanged event,
    Emitter<GameDetailState> emit,
  ) {
    if (state is GameDetailLoaded) {
      final current = state as GameDetailLoaded;
      emit(current.copyWith(isRunning: event.isRunning));
    }
  }

  Future<void> _onLaunchRequested(
    GameDetailLaunchRequested event,
    Emitter<GameDetailState> emit,
  ) async {
    if (state is! GameDetailLoaded) return;

    final current = state as GameDetailLoaded;
    final game = current.game;

    try {
      final result = await _gameLauncher.launchGame(game);

      if (result.success) {
        // Increment play count and update last played date
        final updatedGame = await _gameRepository.incrementPlayCount(game.id);
        await _gameRepository.updateLastPlayed(game.id, DateTime.now());

        emit(current.copyWith(
          game: updatedGame.copyWith(lastPlayedDate: DateTime.now()),
          isRunning: true,
        ));
      } else {
        // Launch failed - show error dialog without leaving the detail page
        emit(current.copyWith(launchError: result.errorMessage));
      }
    } catch (e) {
      // Launch failed - show error dialog without leaving the detail page
      emit(current.copyWith(launchError: e.toString()));
    }
  }

  Future<void> _onStopRequested(
    GameDetailStopRequested event,
    Emitter<GameDetailState> emit,
  ) async {
    if (state is! GameDetailLoaded) return;

    final current = state as GameDetailLoaded;

    try {
      await _gameLauncher.stopGame(current.game.id);
      emit(current.copyWith(isRunning: false));
    } catch (e) {
      emit(GameDetailError(
        type: GameDetailErrorType.stopFailed,
        details: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteRequested(
    GameDetailDeleteRequested event,
    Emitter<GameDetailState> emit,
  ) async {
    if (state is! GameDetailLoaded) return;

    final current = state as GameDetailLoaded;

    try {
      await _gameRepository.deleteGame(current.game.id);

      // Notify home repository of the change
      try {
        await _homeRepository.notifyGamesChanged();
      } catch (_) {
        // Ignore notification errors
      }

      emit(const GameDetailDeleted());
    } catch (e) {
      emit(GameDetailError(
        type: GameDetailErrorType.deleteFailed,
        details: e.toString(),
      ));
    }
  }

  Future<void> _onGameUpdated(
    GameDetailGameUpdated event,
    Emitter<GameDetailState> emit,
  ) async {
    if (state is! GameDetailLoaded) return;

    final current = state as GameDetailLoaded;
    emit(current.copyWith(game: event.game));
  }

  Future<void> _onEditSaved(
    GameDetailEditSaved event,
    Emitter<GameDetailState> emit,
  ) async {
    if (state is! GameDetailLoaded) return;

    try {
      final updatedGame = await _gameRepository.updateGame(event.game);
      await _homeRepository.notifyGamesChanged();
      emit(GameDetailLoaded(
        game: updatedGame,
        metadata: (state as GameDetailLoaded).metadata,
        isRunning: (state as GameDetailLoaded).isRunning,
      ));
    } catch (e) {
      emit(GameDetailError(
        type: GameDetailErrorType.updateFailed,
        details: e.toString(),
      ));
    }
  }

  Future<void> _onRefetchMetadataRequested(
    GameDetailRefetchMetadataRequested event,
    Emitter<GameDetailState> emit,
  ) async {
    if (state is! GameDetailLoaded) return;

    final current = state as GameDetailLoaded;
    final game = current.game;

    emit(const GameDetailLoading());

    try {
      // Clear existing metadata first
      await _metadataRepository.clearMetadata(game.id);

      // Fetch fresh metadata
      final metadata = await _metadataRepository.fetchAndCacheMetadata(
        game.id,
        game.title,
      );

      emit(GameDetailLoaded(
        game: game,
        metadata: metadata,
        isRunning: current.isRunning,
      ));
    } on RawgApiNotConfiguredException catch (e) {
      emit(GameDetailLoaded(
        game: game,
        metadata: current.metadata,
        isRunning: current.isRunning,
        apiConfigError: e.toString(),
      ));
    } catch (e) {
      emit(GameDetailLoaded(
        game: game,
        metadata: current.metadata,
        isRunning: current.isRunning,
      ));
    }
  }
}

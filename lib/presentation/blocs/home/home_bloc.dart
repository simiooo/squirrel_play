import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/home_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';
import 'package:squirrel_play/domain/services/game_launcher.dart';

part 'home_state.dart';
part 'home_event.dart';

/// BLoC for managing the home page state.
///
/// Handles loading home rows, managing focused game state,
/// launching games, fetching metadata, tracking play counts,
/// and reacting to game changes.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  final GameRepository _gameRepository;
  final MetadataRepository _metadataRepository;
  final GameLauncher _gameLauncher;
  StreamSubscription<List<Game>>? _gamesSubscription;
  StreamSubscription<LaunchStatus>? _launchStatusSubscription;

  HomeBloc({
    required HomeRepository homeRepository,
    required GameRepository gameRepository,
    required MetadataRepository metadataRepository,
    required GameLauncher gameLauncher,
  })  : _homeRepository = homeRepository,
        _gameRepository = gameRepository,
        _metadataRepository = metadataRepository,
        _gameLauncher = gameLauncher,
        super(const HomeInitial()) {
    on<HomeLoadRequested>(_onLoadRequested);
    on<HomeGameFocused>(_onGameFocused);
    on<HomeGameLaunched>(_onGameLaunched);
    on<HomeRowHeaderFocused>(_onRowHeaderFocused);
    on<HomeRowHeaderActivated>(_onRowHeaderActivated);
    on<HomeGamesChanged>(_onGamesChanged);
    on<HomeLaunchStatusChanged>(_onLaunchStatusChanged);
    on<HomeRetryRequested>(_onRetryRequested);
    on<HomeFavoriteToggled>(_onFavoriteToggled);

    // Subscribe to game changes for reactive updates
    _gamesSubscription = _homeRepository.watchAllGames().listen(
          (games) => add(HomeGamesChanged(games)),
          onError: (error) => add(const HomeLoadRequested()), // Retry on error
        );

    // Subscribe to launch status changes
    _launchStatusSubscription = _gameLauncher.launchStatusStream.listen(
          (status) => add(HomeLaunchStatusChanged(status)),
        );
  }

  @override
  Future<void> close() {
    _gamesSubscription?.cancel();
    _launchStatusSubscription?.cancel();
    return super.close();
  }

  void _onLoadRequested(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());

    try {
      final rows = await _homeRepository.getHomeRows();

      if (rows.isEmpty) {
        emit(const HomeEmpty(hasScanDirectories: false));
      } else {
        // Set initial focus to first game in first row
        final firstRow = rows.first;
        final firstGame = firstRow.games.isNotEmpty ? firstRow.games.first : null;

        emit(HomeLoaded(
          rows: rows,
          focusedGame: firstGame,
          focusedRowIndex: 0,
          focusedCardIndex: firstRow.games.isNotEmpty ? 0 : -1,
          isLaunching: false,
        ));
      }
    } catch (e) {
      emit(HomeError(
        message: 'Failed to load games: $e',
        onRetry: () => add(const HomeLoadRequested()),
      ));
    }
  }

  void _onGameFocused(HomeGameFocused event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;

      // Fetch metadata for the newly focused game
      GameMetadata? metadata;
      try {
        metadata = await _metadataRepository.getMetadataForGame(event.game.id);
      } catch (e) {
        // Metadata fetch failure is non-critical
        debugPrint('[HomeBloc] Failed to fetch metadata: $e');
      }

      emit(current.copyWith(
        focusedGame: event.game,
        focusedGameMetadata: metadata,
        focusedRowIndex: event.rowIndex,
        focusedCardIndex: event.cardIndex,
      ));
    }
  }

  void _onGameLaunched(HomeGameLaunched event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      emit(current.copyWith(isLaunching: true));

      // Launch the game
      final result = await _gameLauncher.launchGame(event.game);

      if (result.success) {
        // Update play count and last played date
        try {
          await _gameRepository.incrementPlayCount(event.game.id);
          await _gameRepository.updateLastPlayed(event.game.id, DateTime.now());
        } catch (e) {
          debugPrint('[HomeBloc] Failed to update play stats: $e');
        }
      }
    }
  }

  void _onFavoriteToggled(HomeFavoriteToggled event, Emitter<HomeState> emit) async {
    try {
      await _gameRepository.toggleFavorite(event.gameId);
      // Reload home rows to reflect the change
      add(const HomeLoadRequested());
    } catch (e) {
      debugPrint('[HomeBloc] Failed to toggle favorite: $e');
    }
  }

  void _onRowHeaderFocused(HomeRowHeaderFocused event, Emitter<HomeState> emit) {
    // Row header is focused - could update UI to highlight the row
    // For now, we don't change the focused game when header is focused
  }

  void _onRowHeaderActivated(HomeRowHeaderActivated event, Emitter<HomeState> emit) {
    // Navigate to library if the row is navigable
    if (event.row.isNavigable && event.row.type == HomeRowType.allGames) {
      // Navigation will be handled by the widget layer
      // We could emit a state that triggers navigation
    }
  }

  void _onGamesChanged(HomeGamesChanged event, Emitter<HomeState> emit) async {
    // Reload the home rows when games change
    // This ensures the home page updates automatically
    if (state is! HomeInitial) {
      add(const HomeLoadRequested());
    }
  }

  void _onLaunchStatusChanged(HomeLaunchStatusChanged event, Emitter<HomeState> emit) {
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      emit(current.copyWith(
        isLaunching: event.status == LaunchStatus.launching,
      ));
    }
  }

  void _onRetryRequested(HomeRetryRequested event, Emitter<HomeState> emit) {
    add(const HomeLoadRequested());
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/data/repositories/home_repository_impl.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';

part 'game_library_state.dart';
part 'game_library_event.dart';

/// BLoC for managing the game library state.
///
/// Handles loading, refreshing, and deleting games from the library.
class GameLibraryBloc extends Bloc<GameLibraryEvent, GameLibraryState> {
  final GameRepository _gameRepository;
  final HomeRepositoryImpl _homeRepository;

  GameLibraryBloc({
    required GameRepository gameRepository,
    required HomeRepositoryImpl homeRepository,
  })  : _gameRepository = gameRepository,
        _homeRepository = homeRepository,
        super(const LibraryLoading()) {
    on<LoadGames>(_onLoadGames);
    on<Refresh>(_onRefresh);
    on<DeleteGame>(_onDeleteGame);
    on<GameAdded>(_onGameAdded);
    on<RetryLoad>(_onRetryLoad);
  }

  void _onLoadGames(LoadGames event, Emitter<GameLibraryState> emit) async {
    await _loadGames(emit);
  }

  void _onRefresh(Refresh event, Emitter<GameLibraryState> emit) async {
    await _loadGames(emit);
  }

  void _onDeleteGame(DeleteGame event, Emitter<GameLibraryState> emit) async {
    if (state is LibraryLoaded) {
      final current = state as LibraryLoaded;
      
      try {
        // Delete from repository
        await _gameRepository.deleteGame(event.gameId);
        
        // Notify home repository to trigger reactive update
        await _homeRepository.notifyGamesChanged();
        
        // Optimistically remove the game from the list
        final updatedGames = current.games.where((g) => g.id != event.gameId).toList();
        
        if (updatedGames.isEmpty) {
          emit(const LibraryEmpty());
        } else {
          emit(LibraryLoaded(
            games: updatedGames,
            focusedIndex: _calculateNewFocusIndex(current.focusedIndex, updatedGames.length),
          ));
        }
      } catch (e) {
        emit(LibraryError('Failed to delete game: $e'));
      }
    }
  }

  void _onGameAdded(GameAdded event, Emitter<GameLibraryState> emit) async {
    await _loadGames(emit);
  }

  void _onRetryLoad(RetryLoad event, Emitter<GameLibraryState> emit) async {
    await _loadGames(emit);
  }
  
  Future<void> _loadGames(Emitter<GameLibraryState> emit) async {
    emit(const LibraryLoading());
    
    try {
      final games = await _gameRepository.getAllGames();
      
      if (games.isEmpty) {
        emit(const LibraryEmpty());
      } else {
        int focusedIndex = 0;
        if (state is LibraryLoaded) {
          final current = state as LibraryLoaded;
          focusedIndex = current.focusedIndex.clamp(0, games.length - 1);
        }
        emit(LibraryLoaded(games: games, focusedIndex: focusedIndex));
      }
    } catch (e) {
      emit(LibraryError('Failed to load games: $e'));
    }
  }

  int _calculateNewFocusIndex(int currentIndex, int totalGames) {
    if (totalGames == 0) return 0;
    if (currentIndex >= totalGames) return totalGames - 1;
    return currentIndex;
  }
}

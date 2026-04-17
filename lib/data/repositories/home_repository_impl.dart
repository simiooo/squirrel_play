import 'dart:async';

import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/home_repository.dart';

/// Concrete implementation of [HomeRepository] using existing repositories.
///
/// Delegates to [GameRepository] for data access to avoid duplication.
/// Groups games into rows for the home page display.
class HomeRepositoryImpl implements HomeRepository {
  final GameRepository _gameRepository;
  final _gameChangeController = StreamController<List<Game>>.broadcast();
  StreamSubscription<List<Game>>? _gameChangeSubscription;

  HomeRepositoryImpl({
    required GameRepository gameRepository,
  }) : _gameRepository = gameRepository;

  @override
  Future<List<HomeRow>> getHomeRows() async {
    final allGames = await _gameRepository.getAllGames();

    if (allGames.isEmpty) {
      return [];
    }

    final rows = <HomeRow>[];

    // Row 1: Recently Added (sorted by addedDate descending)
    final recentlyAdded = List<Game>.from(allGames)
      ..sort((a, b) => b.addedDate.compareTo(a.addedDate));

    if (recentlyAdded.isNotEmpty) {
      rows.add(
        HomeRow(
          id: 'recently_added',
          titleKey: 'homeRowRecentlyAdded',
          games: recentlyAdded,
          type: HomeRowType.recentlyAdded,
          isNavigable: false,
        ),
      );
    }

    // Row 2: All Games
    if (allGames.isNotEmpty) {
      rows.add(
        HomeRow(
          id: 'all_games',
          titleKey: 'homeRowAllGames',
          games: allGames,
          type: HomeRowType.allGames,
          isNavigable: true,
        ),
      );
    }

    // Row 3: Favorites (only if there are favorites)
    final favorites = allGames.where((g) => g.isFavorite).toList();
    if (favorites.isNotEmpty) {
      rows.add(
        HomeRow(
          id: 'favorites',
          titleKey: 'homeRowFavorites',
          games: favorites,
          type: HomeRowType.favorites,
          isNavigable: false,
        ),
      );
    }

    // Row 4: Recently Played (only if there are played games)
    final playedGames = allGames
        .where((g) => g.lastPlayedDate != null)
        .toList()
      ..sort((a, b) => b.lastPlayedDate!.compareTo(a.lastPlayedDate!));

    if (playedGames.isNotEmpty) {
      // Show last 5-10 recently played games
      final recentGames = playedGames.take(10).toList();
      rows.add(
        HomeRow(
          id: 'recently_played',
          titleKey: 'homeRowRecentlyPlayed',
          games: recentGames,
          type: HomeRowType.recentlyPlayed,
          isNavigable: false,
        ),
      );
    }

    return rows;
  }

  @override
  Stream<List<Game>> watchAllGames() {
    // Return the stream controller's stream
    // This will be fed by external triggers (e.g., when games are added/deleted)
    return _gameChangeController.stream;
  }

  /// Notifies watchers that games have changed.
  ///
  /// Should be called by other repositories/services when games are
  /// added, deleted, or updated.
  Future<void> notifyGamesChanged() async {
    final games = await _gameRepository.getAllGames();
    _gameChangeController.add(games);
  }

  /// Disposes resources.
  void dispose() {
    _gameChangeSubscription?.cancel();
    _gameChangeController.close();
  }
}

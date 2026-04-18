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

    // Comprehensive sorting: combine recently played, favorites, and recently added
    final sortedGames = List<Game>.from(allGames)..sort((a, b) {
      // Priority 1: Recently played games (by lastPlayedDate descending)
      if (a.lastPlayedDate != null && b.lastPlayedDate != null) {
        final cmp = b.lastPlayedDate!.compareTo(a.lastPlayedDate!);
        if (cmp != 0) return cmp;
      } else if (a.lastPlayedDate != null) {
        return -1;
      } else if (b.lastPlayedDate != null) {
        return 1;
      }

      // Priority 2: Favorite games
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;

      // Priority 3: Recently added (by addedDate descending)
      return b.addedDate.compareTo(a.addedDate);
    });

    return [
      HomeRow(
        id: 'featured',
        titleKey: 'homeRowFeatured',
        games: sortedGames,
        type: HomeRowType.allGames,
        isNavigable: true,
      ),
    ];
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
  @override
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

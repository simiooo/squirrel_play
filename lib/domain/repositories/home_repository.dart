import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';

/// Abstract repository interface for home page operations.
///
/// Defines the contract for fetching games grouped by row type.
/// Implementations handle the actual database operations.
abstract class HomeRepository {
  /// Fetches games grouped by row type for the home page.
  ///
  /// Returns rows in this order:
  /// 1. Recently Added (sorted by addedDate descending)
  /// 2. All Games (all games in library)
  /// 3. Favorites (favorite games, or empty list if none)
  ///
  /// Rows with zero games are filtered out and not returned.
  Future<List<HomeRow>> getHomeRows();

  /// Returns a stream that emits whenever games change (add/delete/update).
  ///
  /// Used by HomeBloc for reactive updates. The stream emits the full
  /// list of games whenever any change occurs.
  Stream<List<Game>> watchAllGames();
}

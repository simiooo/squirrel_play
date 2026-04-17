import 'package:squirrel_play/domain/entities/game.dart';

/// Abstract repository interface for game operations.
///
/// Defines the contract for game data access. Implementations handle
/// the actual database or API operations.
abstract class GameRepository {
  /// Gets all games in the library.
  Future<List<Game>> getAllGames();

  /// Gets a game by its ID.
  Future<Game?> getGameById(String id);

  /// Gets a game by its executable path.
  Future<Game?> getGameByExecutablePath(String path);

  /// Adds a new game to the library.
  Future<Game> addGame(Game game);

  /// Updates an existing game.
  Future<Game> updateGame(Game game);

  /// Deletes a game from the library.
  Future<void> deleteGame(String id);

  /// Checks if a game with the given executable path already exists.
  Future<bool> gameExists(String executablePath);

  /// Gets games by scan directory ID.
  Future<List<Game>> getGamesByDirectoryId(String directoryId);

  /// Toggles the favorite status of a game.
  Future<Game> toggleFavorite(String id);

  /// Increments the play count of a game.
  Future<Game> incrementPlayCount(String id);

  /// Updates the last played date of a game.
  Future<Game> updateLastPlayed(String id, DateTime date);
}

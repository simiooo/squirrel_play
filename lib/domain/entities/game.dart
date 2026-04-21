import 'package:equatable/equatable.dart';

/// Game entity representing a game in the domain layer.
///
/// This is a business object used throughout the application.
/// It is independent of the database implementation.
class Game extends Equatable {
  /// Unique identifier.
  final String id;

  /// Game title.
  final String title;

  /// Full path to the executable file.
  final String executablePath;

  /// ID of the scan directory this game was discovered from (null if manually added).
  final String? directoryId;

  /// Date when the game was added to the library.
  final DateTime addedDate;

  /// Date when the game was last played (null if never played).
  final DateTime? lastPlayedDate;

  /// Whether the game is marked as favorite.
  final bool isFavorite;

  /// Number of times the game has been launched.
  final int playCount;

  /// Optional launch arguments for the game executable.
  final String? launchArguments;

  /// Platform the game belongs to (e.g., 'steam', 'manual').
  final String? platform;

  /// Platform-specific game ID (e.g., Steam appId).
  final String? platformGameId;

  /// Creates a Game entity.
  const Game({
    required this.id,
    required this.title,
    required this.executablePath,
    this.directoryId,
    required this.addedDate,
    this.lastPlayedDate,
    this.isFavorite = false,
    this.playCount = 0,
    this.launchArguments,
    this.platform,
    this.platformGameId,
  });

  /// Creates a copy of this Game with the given fields replaced.
  Game copyWith({
    String? id,
    String? title,
    String? executablePath,
    String? directoryId,
    DateTime? addedDate,
    DateTime? lastPlayedDate,
    bool? isFavorite,
    int? playCount,
    String? launchArguments,
    String? platform,
    String? platformGameId,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      executablePath: executablePath ?? this.executablePath,
      directoryId: directoryId ?? this.directoryId,
      addedDate: addedDate ?? this.addedDate,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      launchArguments: launchArguments ?? this.launchArguments,
      platform: platform ?? this.platform,
      platformGameId: platformGameId ?? this.platformGameId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        executablePath,
        directoryId,
        addedDate,
        lastPlayedDate,
        isFavorite,
        playCount,
        launchArguments,
        platform,
        platformGameId,
      ];
}

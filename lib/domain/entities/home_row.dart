import 'package:equatable/equatable.dart';

import 'package:squirrel_play/domain/entities/game.dart';

/// Home row entity representing a row of games on the home page.
///
/// Each row has a title (via i18n key), a list of games, and a type
/// that determines how the row is populated and displayed.
class HomeRow extends Equatable {
  /// Unique identifier for the row.
  final String id;

  /// i18n key for the row title.
  final String titleKey;

  /// List of games in this row.
  final List<Game> games;

  /// Type of the row (determines sorting and behavior).
  final HomeRowType type;

  /// Whether the row header is navigable (clicking navigates to library).
  final bool isNavigable;

  /// Creates a HomeRow entity.
  const HomeRow({
    required this.id,
    required this.titleKey,
    required this.games,
    required this.type,
    this.isNavigable = false,
  });

  /// Creates a copy of this HomeRow with the given fields replaced.
  HomeRow copyWith({
    String? id,
    String? titleKey,
    List<Game>? games,
    HomeRowType? type,
    bool? isNavigable,
  }) {
    return HomeRow(
      id: id ?? this.id,
      titleKey: titleKey ?? this.titleKey,
      games: games ?? this.games,
      type: type ?? this.type,
      isNavigable: isNavigable ?? this.isNavigable,
    );
  }

  @override
  List<Object?> get props => [id, titleKey, games, type, isNavigable];
}

/// Enum representing different types of home rows.
enum HomeRowType {
  /// Recently added games (sorted by addedDate descending).
  recentlyAdded,

  /// All games in the library.
  allGames,

  /// Favorite games.
  favorites,

  /// Recently played games (sorted by lastPlayedDate descending).
  recentlyPlayed,
}

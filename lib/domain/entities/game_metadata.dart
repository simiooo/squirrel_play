import 'package:equatable/equatable.dart';

/// Game metadata entity representing metadata in the domain layer.
///
/// This is a business object containing metadata fetched from external APIs.
class GameMetadata extends Equatable {
  /// Game ID (references the Game entity).
  final String gameId;

  /// External API ID (e.g., RAWG game ID).
  final String? externalId;

  /// Game description.
  final String? description;

  /// URL to cover image.
  final String? coverImageUrl;

  /// URL to hero/background image.
  final String? heroImageUrl;

  /// List of genre names.
  final List<String> genres;

  /// List of screenshot URLs.
  final List<String> screenshots;

  /// Release date.
  final DateTime? releaseDate;

  /// Game rating (0-5 scale).
  final double? rating;

  /// Developer name.
  final String? developer;

  /// Publisher name.
  final String? publisher;

  /// Date when metadata was last fetched.
  final DateTime lastFetched;

  /// Creates a GameMetadata entity.
  const GameMetadata({
    required this.gameId,
    this.externalId,
    this.description,
    this.coverImageUrl,
    this.heroImageUrl,
    this.genres = const [],
    this.screenshots = const [],
    this.releaseDate,
    this.rating,
    this.developer,
    this.publisher,
    required this.lastFetched,
  });

  /// Creates a copy of this GameMetadata with the given fields replaced.
  GameMetadata copyWith({
    String? gameId,
    String? externalId,
    String? description,
    String? coverImageUrl,
    String? heroImageUrl,
    List<String>? genres,
    List<String>? screenshots,
    DateTime? releaseDate,
    double? rating,
    String? developer,
    String? publisher,
    DateTime? lastFetched,
  }) {
    return GameMetadata(
      gameId: gameId ?? this.gameId,
      externalId: externalId ?? this.externalId,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      genres: genres ?? this.genres,
      screenshots: screenshots ?? this.screenshots,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      developer: developer ?? this.developer,
      publisher: publisher ?? this.publisher,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        externalId,
        description,
        coverImageUrl,
        heroImageUrl,
        genres,
        screenshots,
        releaseDate,
        rating,
        developer,
        publisher,
        lastFetched,
      ];
}

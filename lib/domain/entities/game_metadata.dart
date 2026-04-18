import 'package:equatable/equatable.dart';

/// Game metadata entity representing metadata in the domain layer.
///
/// This is a business object containing metadata fetched from external APIs.
class GameMetadata extends Equatable {
  /// Game ID (references the Game entity).
  final String gameId;

  /// External API ID (e.g., RAWG game ID).
  final String? externalId;

  /// Official title from metadata source (e.g., Steam/RAWG).
  final String? title;

  /// Game description.
  final String? description;

  /// URL to cover image.
  final String? coverImageUrl;

  /// URL to card/landscape image.
  final String? cardImageUrl;

  /// URL to hero/background image.
  final String? heroImageUrl;

  /// URL to logo image.
  final String? logoImageUrl;

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
    this.title,
    this.description,
    this.coverImageUrl,
    this.cardImageUrl,
    this.heroImageUrl,
    this.logoImageUrl,
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
    String? title,
    String? description,
    String? coverImageUrl,
    String? cardImageUrl,
    String? heroImageUrl,
    String? logoImageUrl,
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
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      logoImageUrl: logoImageUrl ?? this.logoImageUrl,
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
        title,
        description,
        coverImageUrl,
        cardImageUrl,
        heroImageUrl,
        logoImageUrl,
        genres,
        screenshots,
        releaseDate,
        rating,
        developer,
        publisher,
        lastFetched,
      ];
}

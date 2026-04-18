import 'package:json_annotation/json_annotation.dart';

import 'package:squirrel_play/data/datasources/local/database_constants.dart';

part 'game_metadata_model.g.dart';

/// Database model for the game_metadata table.
///
/// Represents metadata for a game fetched from external APIs.
/// Uses json_serializable for JSON serialization.
@JsonSerializable()
class GameMetadataModel {
  /// Game ID (foreign key to games table).
  @JsonKey(name: DatabaseConstants.colGameId)
  final String gameId;

  /// External API ID (e.g., RAWG game ID).
  @JsonKey(name: DatabaseConstants.colExternalId)
  final String? externalId;

  /// Official title from metadata source (e.g., Steam/RAWG).
  @JsonKey(name: DatabaseConstants.colMetadataTitle)
  final String? title;

  /// Game description.
  @JsonKey(name: DatabaseConstants.colDescription)
  final String? description;

  /// URL to cover image.
  @JsonKey(name: DatabaseConstants.colCoverImageUrl)
  final String? coverImageUrl;

  /// URL to card/landscape image.
  @JsonKey(name: DatabaseConstants.colCardImageUrl)
  final String? cardImageUrl;

  /// URL to hero/background image.
  @JsonKey(name: DatabaseConstants.colHeroImageUrl)
  final String? heroImageUrl;

  /// URL to logo image.
  @JsonKey(name: DatabaseConstants.colLogoImageUrl)
  final String? logoImageUrl;

  /// Release date (milliseconds since epoch).
  @JsonKey(
    name: DatabaseConstants.colReleaseDate,
    fromJson: _dateTimeFromJsonNullable,
    toJson: _dateTimeToJsonNullable,
  )
  final DateTime? releaseDate;

  /// Game rating (0-5 scale).
  @JsonKey(name: DatabaseConstants.colRating)
  final double? rating;

  /// Developer name.
  @JsonKey(name: DatabaseConstants.colDeveloper)
  final String? developer;

  /// Publisher name.
  @JsonKey(name: DatabaseConstants.colPublisher)
  final String? publisher;

  /// Date when metadata was last fetched (milliseconds since epoch).
  @JsonKey(
    name: DatabaseConstants.colLastFetched,
    fromJson: _dateTimeFromJsonNonNull,
    toJson: _dateTimeToJsonNonNull,
  )
  final DateTime lastFetched;

  /// Creates a GameMetadataModel instance.
  const GameMetadataModel({
    required this.gameId,
    this.externalId,
    this.title,
    this.description,
    this.coverImageUrl,
    this.cardImageUrl,
    this.heroImageUrl,
    this.logoImageUrl,
    this.releaseDate,
    this.rating,
    this.developer,
    this.publisher,
    required this.lastFetched,
  });

  /// Creates a GameMetadataModel from a database map.
  factory GameMetadataModel.fromMap(Map<String, dynamic> map) {
    return GameMetadataModel(
      gameId: map[DatabaseConstants.colGameId] as String,
      externalId: map[DatabaseConstants.colExternalId] as String?,
      title: map[DatabaseConstants.colMetadataTitle] as String?,
      description: map[DatabaseConstants.colDescription] as String?,
      coverImageUrl: map[DatabaseConstants.colCoverImageUrl] as String?,
      cardImageUrl: map[DatabaseConstants.colCardImageUrl] as String?,
      heroImageUrl: map[DatabaseConstants.colHeroImageUrl] as String?,
      logoImageUrl: map[DatabaseConstants.colLogoImageUrl] as String?,
      releaseDate: map[DatabaseConstants.colReleaseDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DatabaseConstants.colReleaseDate] as int,
            )
          : null,
      rating: map[DatabaseConstants.colRating] as double?,
      developer: map[DatabaseConstants.colDeveloper] as String?,
      publisher: map[DatabaseConstants.colPublisher] as String?,
      lastFetched: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConstants.colLastFetched] as int,
      ),
    );
  }

  /// Converts this GameMetadataModel to a database map.
  Map<String, dynamic> toMap() {
    return {
      DatabaseConstants.colGameId: gameId,
      DatabaseConstants.colExternalId: externalId,
      DatabaseConstants.colMetadataTitle: title,
      DatabaseConstants.colDescription: description,
      DatabaseConstants.colCoverImageUrl: coverImageUrl,
      DatabaseConstants.colCardImageUrl: cardImageUrl,
      DatabaseConstants.colHeroImageUrl: heroImageUrl,
      DatabaseConstants.colLogoImageUrl: logoImageUrl,
      DatabaseConstants.colReleaseDate: releaseDate?.millisecondsSinceEpoch,
      DatabaseConstants.colRating: rating,
      DatabaseConstants.colDeveloper: developer,
      DatabaseConstants.colPublisher: publisher,
      DatabaseConstants.colLastFetched: lastFetched.millisecondsSinceEpoch,
    };
  }

  /// Creates a GameMetadataModel from JSON.
  factory GameMetadataModel.fromJson(Map<String, dynamic> json) =>
      _$GameMetadataModelFromJson(json);

  /// Converts this GameMetadataModel to JSON.
  Map<String, dynamic> toJson() => _$GameMetadataModelToJson(this);

  /// Creates a copy of this GameMetadataModel with the given fields replaced.
  GameMetadataModel copyWith({
    String? gameId,
    String? externalId,
    String? title,
    String? description,
    String? coverImageUrl,
    String? cardImageUrl,
    String? heroImageUrl,
    String? logoImageUrl,
    DateTime? releaseDate,
    double? rating,
    String? developer,
    String? publisher,
    DateTime? lastFetched,
  }) {
    return GameMetadataModel(
      gameId: gameId ?? this.gameId,
      externalId: externalId ?? this.externalId,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      logoImageUrl: logoImageUrl ?? this.logoImageUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      developer: developer ?? this.developer,
      publisher: publisher ?? this.publisher,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  // JSON serialization helpers for DateTime
  static DateTime _dateTimeFromJsonNonNull(int milliseconds) {
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  static int _dateTimeToJsonNonNull(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  static DateTime? _dateTimeFromJsonNullable(int? milliseconds) {
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  static int? _dateTimeToJsonNullable(DateTime? dateTime) {
    return dateTime?.millisecondsSinceEpoch;
  }
}

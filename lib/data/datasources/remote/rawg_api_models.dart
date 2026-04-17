import 'package:json_annotation/json_annotation.dart';

part 'rawg_api_models.g.dart';

/// Genre model from RAWG API.
@JsonSerializable()
class Genre {
  /// Genre ID
  final int id;

  /// Genre name
  final String name;

  /// Genre slug
  final String slug;

  const Genre({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);
  Map<String, dynamic> toJson() => _$GenreToJson(this);
}

/// Developer model from RAWG API.
@JsonSerializable()
class Developer {
  /// Developer ID
  final int id;

  /// Developer name
  final String name;

  /// Developer slug
  final String slug;

  const Developer({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Developer.fromJson(Map<String, dynamic> json) => _$DeveloperFromJson(json);
  Map<String, dynamic> toJson() => _$DeveloperToJson(this);
}

/// Publisher model from RAWG API.
@JsonSerializable()
class Publisher {
  /// Publisher ID
  final int id;

  /// Publisher name
  final String name;

  /// Publisher slug
  final String slug;

  const Publisher({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory Publisher.fromJson(Map<String, dynamic> json) => _$PublisherFromJson(json);
  Map<String, dynamic> toJson() => _$PublisherToJson(this);
}

/// Screenshot model from RAWG API.
@JsonSerializable()
class Screenshot {
  /// Screenshot ID
  final int id;

  /// Image URL
  @JsonKey(name: 'image')
  final String url;

  const Screenshot({
    required this.id,
    required this.url,
  });

  factory Screenshot.fromJson(Map<String, dynamic> json) => _$ScreenshotFromJson(json);
  Map<String, dynamic> toJson() => _$ScreenshotToJson(this);
}

/// Game search result from RAWG API.
@JsonSerializable()
class GameSearchResult {
  /// Game ID
  final int id;

  /// Game name
  final String name;

  /// Game slug
  final String slug;

  /// Release date (ISO 8601 format)
  final String? released;

  /// Background image URL
  @JsonKey(name: 'background_image')
  final String? backgroundImage;

  /// Game rating (0-5 scale)
  final double? rating;

  /// List of genres
  final List<Genre>? genres;

  const GameSearchResult({
    required this.id,
    required this.name,
    required this.slug,
    this.released,
    this.backgroundImage,
    this.rating,
    this.genres,
  });

  factory GameSearchResult.fromJson(Map<String, dynamic> json) =>
      _$GameSearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$GameSearchResultToJson(this);
}

/// Game detail response from RAWG API.
@JsonSerializable()
class GameDetailResponse {
  /// Game ID
  final int id;

  /// Game name
  final String name;

  /// Game slug
  final String slug;

  /// Game description (HTML)
  final String? description;

  /// Game description (plain text)
  @JsonKey(name: 'description_raw')
  final String? descriptionRaw;

  /// Background image URL
  @JsonKey(name: 'background_image')
  final String? backgroundImage;

  /// Additional background image URL
  @JsonKey(name: 'background_image_additional')
  final String? backgroundImageAdditional;

  /// Release date (ISO 8601 format)
  final String? released;

  /// Game rating (0-5 scale)
  final double? rating;

  /// Maximum rating value
  @JsonKey(name: 'rating_top')
  final int? ratingTop;

  /// List of genres
  final List<Genre>? genres;

  /// List of developers
  final List<Developer>? developers;

  /// List of publishers
  final List<Publisher>? publishers;

  const GameDetailResponse({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.descriptionRaw,
    this.backgroundImage,
    this.backgroundImageAdditional,
    this.released,
    this.rating,
    this.ratingTop,
    this.genres,
    this.developers,
    this.publishers,
  });

  factory GameDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$GameDetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GameDetailResponseToJson(this);
}

/// Search response wrapper from RAWG API.
@JsonSerializable(genericArgumentFactories: true)
class RawgSearchResponse<T> {
  /// Total count of results
  final int count;

  /// URL for next page
  final String? next;

  /// URL for previous page
  final String? previous;

  /// List of results
  final List<T> results;

  const RawgSearchResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory RawgSearchResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$RawgSearchResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$RawgSearchResponseToJson(this, toJsonT);
}

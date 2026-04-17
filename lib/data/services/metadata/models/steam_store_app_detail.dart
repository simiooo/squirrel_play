import 'package:json_annotation/json_annotation.dart';

part 'steam_store_app_detail.g.dart';

/// JSON-serializable model for Steam Store API response.
@JsonSerializable()
class SteamStoreAppDetail {
  /// Whether the request was successful.
  final bool success;

  /// The app data if successful.
  final SteamStoreAppData? data;

  /// Creates a SteamStoreAppDetail instance.
  const SteamStoreAppDetail({
    required this.success,
    this.data,
  });

  /// Factory constructor for creating a new instance from JSON.
  factory SteamStoreAppDetail.fromJson(Map<String, dynamic> json) =>
      _$SteamStoreAppDetailFromJson(json);

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'success': success,
    'data': data?.toJson(),
  };
}

/// Data class containing detailed app information from Steam Store API.
@JsonSerializable()
class SteamStoreAppData {
  /// Game name.
  final String name;

  /// Short description of the game.
  @JsonKey(name: 'short_description')
  final String shortDescription;

  /// Header image URL.
  @JsonKey(name: 'header_image')
  final String headerImage;

  /// Raw background image URL (higher quality).
  @JsonKey(name: 'background_raw')
  final String? backgroundRaw;

  /// Background image URL (fallback).
  final String? background;

  /// List of screenshots.
  final List<SteamStoreScreenshot>? screenshots;

  /// List of developers.
  final List<String>? developers;

  /// List of publishers.
  final List<String>? publishers;

  /// List of genres.
  final List<SteamStoreGenre>? genres;

  /// Release date information.
  @JsonKey(name: 'release_date')
  final SteamStoreReleaseDate? releaseDate;

  /// Creates a SteamStoreAppData instance.
  const SteamStoreAppData({
    required this.name,
    required this.shortDescription,
    required this.headerImage,
    this.backgroundRaw,
    this.background,
    this.screenshots,
    this.developers,
    this.publishers,
    this.genres,
    this.releaseDate,
  });

  /// Factory constructor for creating a new instance from JSON.
  factory SteamStoreAppData.fromJson(Map<String, dynamic> json) =>
      _$SteamStoreAppDataFromJson(json);

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'short_description': shortDescription,
    'header_image': headerImage,
    'background_raw': backgroundRaw,
    'background': background,
    'screenshots': screenshots?.map((e) => e.toJson()).toList(),
    'developers': developers,
    'publishers': publishers,
    'genres': genres?.map((e) => e.toJson()).toList(),
    'release_date': releaseDate?.toJson(),
  };
}

/// Screenshot data from Steam Store API.
@JsonSerializable()
class SteamStoreScreenshot {
  /// Full path URL to the screenshot.
  @JsonKey(name: 'path_full')
  final String pathFull;

  /// Creates a SteamStoreScreenshot instance.
  const SteamStoreScreenshot({
    required this.pathFull,
  });

  /// Factory constructor for creating a new instance from JSON.
  factory SteamStoreScreenshot.fromJson(Map<String, dynamic> json) =>
      _$SteamStoreScreenshotFromJson(json);

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => _$SteamStoreScreenshotToJson(this);
}

/// Genre data from Steam Store API.
@JsonSerializable()
class SteamStoreGenre {
  /// Genre description/name.
  final String description;

  /// Creates a SteamStoreGenre instance.
  const SteamStoreGenre({
    required this.description,
  });

  /// Factory constructor for creating a new instance from JSON.
  factory SteamStoreGenre.fromJson(Map<String, dynamic> json) =>
      _$SteamStoreGenreFromJson(json);

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => _$SteamStoreGenreToJson(this);
}

/// Release date data from Steam Store API.
@JsonSerializable()
class SteamStoreReleaseDate {
  /// Release date string (various formats).
  final String date;

  /// Creates a SteamStoreReleaseDate instance.
  const SteamStoreReleaseDate({
    required this.date,
  });

  /// Factory constructor for creating a new instance from JSON.
  factory SteamStoreReleaseDate.fromJson(Map<String, dynamic> json) =>
      _$SteamStoreReleaseDateFromJson(json);

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => _$SteamStoreReleaseDateToJson(this);
}

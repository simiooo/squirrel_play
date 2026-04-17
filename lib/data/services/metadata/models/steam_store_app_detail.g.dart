// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steam_store_app_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SteamStoreAppDetail _$SteamStoreAppDetailFromJson(Map<String, dynamic> json) =>
    SteamStoreAppDetail(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : SteamStoreAppData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SteamStoreAppDetailToJson(
  SteamStoreAppDetail instance,
) => <String, dynamic>{'success': instance.success, 'data': instance.data};

SteamStoreAppData _$SteamStoreAppDataFromJson(Map<String, dynamic> json) =>
    SteamStoreAppData(
      name: json['name'] as String,
      shortDescription: json['short_description'] as String,
      headerImage: json['header_image'] as String,
      backgroundRaw: json['background_raw'] as String?,
      background: json['background'] as String?,
      screenshots: (json['screenshots'] as List<dynamic>?)
          ?.map((e) => SteamStoreScreenshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      developers: (json['developers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      publishers: (json['publishers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => SteamStoreGenre.fromJson(e as Map<String, dynamic>))
          .toList(),
      releaseDate: json['release_date'] == null
          ? null
          : SteamStoreReleaseDate.fromJson(
              json['release_date'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$SteamStoreAppDataToJson(SteamStoreAppData instance) =>
    <String, dynamic>{
      'name': instance.name,
      'short_description': instance.shortDescription,
      'header_image': instance.headerImage,
      'background_raw': instance.backgroundRaw,
      'background': instance.background,
      'screenshots': instance.screenshots,
      'developers': instance.developers,
      'publishers': instance.publishers,
      'genres': instance.genres,
      'release_date': instance.releaseDate,
    };

SteamStoreScreenshot _$SteamStoreScreenshotFromJson(
  Map<String, dynamic> json,
) => SteamStoreScreenshot(pathFull: json['path_full'] as String);

Map<String, dynamic> _$SteamStoreScreenshotToJson(
  SteamStoreScreenshot instance,
) => <String, dynamic>{'path_full': instance.pathFull};

SteamStoreGenre _$SteamStoreGenreFromJson(Map<String, dynamic> json) =>
    SteamStoreGenre(description: json['description'] as String);

Map<String, dynamic> _$SteamStoreGenreToJson(SteamStoreGenre instance) =>
    <String, dynamic>{'description': instance.description};

SteamStoreReleaseDate _$SteamStoreReleaseDateFromJson(
  Map<String, dynamic> json,
) => SteamStoreReleaseDate(date: json['date'] as String);

Map<String, dynamic> _$SteamStoreReleaseDateToJson(
  SteamStoreReleaseDate instance,
) => <String, dynamic>{'date': instance.date};

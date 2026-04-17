// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rawg_api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Genre _$GenreFromJson(Map<String, dynamic> json) => Genre(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  slug: json['slug'] as String,
);

Map<String, dynamic> _$GenreToJson(Genre instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
};

Developer _$DeveloperFromJson(Map<String, dynamic> json) => Developer(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  slug: json['slug'] as String,
);

Map<String, dynamic> _$DeveloperToJson(Developer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
};

Publisher _$PublisherFromJson(Map<String, dynamic> json) => Publisher(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  slug: json['slug'] as String,
);

Map<String, dynamic> _$PublisherToJson(Publisher instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
};

Screenshot _$ScreenshotFromJson(Map<String, dynamic> json) =>
    Screenshot(id: (json['id'] as num).toInt(), url: json['image'] as String);

Map<String, dynamic> _$ScreenshotToJson(Screenshot instance) =>
    <String, dynamic>{'id': instance.id, 'image': instance.url};

GameSearchResult _$GameSearchResultFromJson(Map<String, dynamic> json) =>
    GameSearchResult(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      released: json['released'] as String?,
      backgroundImage: json['background_image'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GameSearchResultToJson(GameSearchResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'released': instance.released,
      'background_image': instance.backgroundImage,
      'rating': instance.rating,
      'genres': instance.genres,
    };

GameDetailResponse _$GameDetailResponseFromJson(Map<String, dynamic> json) =>
    GameDetailResponse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      descriptionRaw: json['description_raw'] as String?,
      backgroundImage: json['background_image'] as String?,
      backgroundImageAdditional: json['background_image_additional'] as String?,
      released: json['released'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingTop: (json['rating_top'] as num?)?.toInt(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
      developers: (json['developers'] as List<dynamic>?)
          ?.map((e) => Developer.fromJson(e as Map<String, dynamic>))
          .toList(),
      publishers: (json['publishers'] as List<dynamic>?)
          ?.map((e) => Publisher.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GameDetailResponseToJson(GameDetailResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'description': instance.description,
      'description_raw': instance.descriptionRaw,
      'background_image': instance.backgroundImage,
      'background_image_additional': instance.backgroundImageAdditional,
      'released': instance.released,
      'rating': instance.rating,
      'rating_top': instance.ratingTop,
      'genres': instance.genres,
      'developers': instance.developers,
      'publishers': instance.publishers,
    };

RawgSearchResponse<T> _$RawgSearchResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => RawgSearchResponse<T>(
  count: (json['count'] as num).toInt(),
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>).map(fromJsonT).toList(),
);

Map<String, dynamic> _$RawgSearchResponseToJson<T>(
  RawgSearchResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'count': instance.count,
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results.map(toJsonT).toList(),
};

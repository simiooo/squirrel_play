// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_metadata_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameMetadataModel _$GameMetadataModelFromJson(Map<String, dynamic> json) =>
    GameMetadataModel(
      gameId: json['game_id'] as String,
      externalId: json['external_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      cardImageUrl: json['card_image_url'] as String?,
      heroImageUrl: json['hero_image_url'] as String?,
      logoImageUrl: json['logo_image_url'] as String?,
      releaseDate: GameMetadataModel._dateTimeFromJsonNullable(
        (json['release_date'] as num?)?.toInt(),
      ),
      rating: (json['rating'] as num?)?.toDouble(),
      developer: json['developer'] as String?,
      publisher: json['publisher'] as String?,
      lastFetched: GameMetadataModel._dateTimeFromJsonNonNull(
        (json['last_fetched'] as num).toInt(),
      ),
    );

Map<String, dynamic> _$GameMetadataModelToJson(GameMetadataModel instance) =>
    <String, dynamic>{
      'game_id': instance.gameId,
      'external_id': instance.externalId,
      'title': instance.title,
      'description': instance.description,
      'cover_image_url': instance.coverImageUrl,
      'card_image_url': instance.cardImageUrl,
      'hero_image_url': instance.heroImageUrl,
      'logo_image_url': instance.logoImageUrl,
      'release_date': GameMetadataModel._dateTimeToJsonNullable(
        instance.releaseDate,
      ),
      'rating': instance.rating,
      'developer': instance.developer,
      'publisher': instance.publisher,
      'last_fetched': GameMetadataModel._dateTimeToJsonNonNull(
        instance.lastFetched,
      ),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameModel _$GameModelFromJson(Map<String, dynamic> json) => GameModel(
  id: json['id'] as String,
  title: json['title'] as String,
  executablePath: json['executable_path'] as String,
  directoryId: json['directory_id'] as String?,
  addedDate: GameModel._dateTimeFromJsonNonNull(
    (json['added_date'] as num).toInt(),
  ),
  lastPlayedDate: GameModel._dateTimeFromJsonNullable(
    (json['last_played_date'] as num?)?.toInt(),
  ),
  isFavorite: json['is_favorite'] == null
      ? false
      : GameModel._boolFromJson((json['is_favorite'] as num).toInt()),
  playCount: (json['play_count'] as num?)?.toInt() ?? 0,
  launchArguments: json['launch_arguments'] as String?,
);

Map<String, dynamic> _$GameModelToJson(GameModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'executable_path': instance.executablePath,
  'directory_id': instance.directoryId,
  'added_date': GameModel._dateTimeToJsonNonNull(instance.addedDate),
  'last_played_date': GameModel._dateTimeToJsonNullable(
    instance.lastPlayedDate,
  ),
  'is_favorite': GameModel._boolToJson(instance.isFavorite),
  'play_count': instance.playCount,
  'launch_arguments': instance.launchArguments,
};

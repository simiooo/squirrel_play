// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'steam_game_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SteamGameData _$SteamGameDataFromJson(Map<String, dynamic> json) =>
    SteamGameData(
      appId: json['app_id'] as String,
      name: json['name'] as String,
      installDir: json['install_dir'] as String,
      libraryPath: json['library_path'] as String,
      installSize: (json['install_size'] as num?)?.toInt(),
      possibleExecutablePaths:
          (json['possible_executable_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SteamGameDataToJson(SteamGameData instance) =>
    <String, dynamic>{
      'app_id': instance.appId,
      'name': instance.name,
      'install_dir': instance.installDir,
      'library_path': instance.libraryPath,
      'install_size': instance.installSize,
      'possible_executable_paths': instance.possibleExecutablePaths,
    };

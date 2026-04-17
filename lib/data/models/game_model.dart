import 'package:json_annotation/json_annotation.dart';

import 'package:squirrel_play/data/datasources/local/database_constants.dart';

part 'game_model.g.dart';

/// Database model for the games table.
///
/// Represents a game entry in the local SQLite database.
/// Uses json_serializable for JSON serialization.
@JsonSerializable()
class GameModel {
  /// Unique identifier (UUID v4).
  @JsonKey(name: DatabaseConstants.colId)
  final String id;

  /// Game title.
  @JsonKey(name: DatabaseConstants.colTitle)
  final String title;

  /// Full path to the executable file.
  @JsonKey(name: DatabaseConstants.colExecutablePath)
  final String executablePath;

  /// ID of the scan directory this game was discovered from (null if manually added).
  @JsonKey(name: DatabaseConstants.colDirectoryId)
  final String? directoryId;

  /// Date when the game was added to the library (milliseconds since epoch).
  @JsonKey(
    name: DatabaseConstants.colAddedDate,
    fromJson: _dateTimeFromJsonNonNull,
    toJson: _dateTimeToJsonNonNull,
  )
  final DateTime addedDate;

  /// Date when the game was last played (milliseconds since epoch, null if never played).
  @JsonKey(
    name: DatabaseConstants.colLastPlayedDate,
    fromJson: _dateTimeFromJsonNullable,
    toJson: _dateTimeToJsonNullable,
  )
  final DateTime? lastPlayedDate;

  /// Whether the game is marked as favorite.
  @JsonKey(
    name: DatabaseConstants.colIsFavorite,
    fromJson: _boolFromJson,
    toJson: _boolToJson,
  )
  final bool isFavorite;

  /// Number of times the game has been launched.
  @JsonKey(name: DatabaseConstants.colPlayCount)
  final int playCount;

  /// Creates a GameModel instance.
  const GameModel({
    required this.id,
    required this.title,
    required this.executablePath,
    this.directoryId,
    required this.addedDate,
    this.lastPlayedDate,
    this.isFavorite = false,
    this.playCount = 0,
  });

  /// Creates a GameModel from a database map.
  factory GameModel.fromMap(Map<String, dynamic> map) {
    return GameModel(
      id: map[DatabaseConstants.colId] as String,
      title: map[DatabaseConstants.colTitle] as String,
      executablePath: map[DatabaseConstants.colExecutablePath] as String,
      directoryId: map[DatabaseConstants.colDirectoryId] as String?,
      addedDate: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConstants.colAddedDate] as int,
      ),
      lastPlayedDate: map[DatabaseConstants.colLastPlayedDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DatabaseConstants.colLastPlayedDate] as int,
            )
          : null,
      isFavorite: (map[DatabaseConstants.colIsFavorite] as int) == 1,
      playCount: map[DatabaseConstants.colPlayCount] as int,
    );
  }

  /// Converts this GameModel to a database map.
  Map<String, dynamic> toMap() {
    return {
      DatabaseConstants.colId: id,
      DatabaseConstants.colTitle: title,
      DatabaseConstants.colExecutablePath: executablePath,
      DatabaseConstants.colDirectoryId: directoryId,
      DatabaseConstants.colAddedDate: addedDate.millisecondsSinceEpoch,
      DatabaseConstants.colLastPlayedDate: lastPlayedDate?.millisecondsSinceEpoch,
      DatabaseConstants.colIsFavorite: isFavorite ? 1 : 0,
      DatabaseConstants.colPlayCount: playCount,
    };
  }

  /// Creates a GameModel from JSON.
  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  /// Converts this GameModel to JSON.
  Map<String, dynamic> toJson() => _$GameModelToJson(this);

  /// Creates a copy of this GameModel with the given fields replaced.
  GameModel copyWith({
    String? id,
    String? title,
    String? executablePath,
    String? directoryId,
    DateTime? addedDate,
    DateTime? lastPlayedDate,
    bool? isFavorite,
    int? playCount,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      executablePath: executablePath ?? this.executablePath,
      directoryId: directoryId ?? this.directoryId,
      addedDate: addedDate ?? this.addedDate,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
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

  // JSON serialization helpers for bool
  static bool _boolFromJson(int value) => value == 1;
  static int _boolToJson(bool value) => value ? 1 : 0;
}

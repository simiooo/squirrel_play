import 'package:json_annotation/json_annotation.dart';

import 'package:squirrel_play/data/datasources/local/database_constants.dart';

part 'scan_directory_model.g.dart';

/// Database model for the scan_directories table.
///
/// Represents a directory that has been added for game scanning.
/// Uses json_serializable for JSON serialization.
@JsonSerializable()
class ScanDirectoryModel {
  /// Unique identifier (UUID v4).
  @JsonKey(name: DatabaseConstants.colId)
  final String id;

  /// Full path to the directory.
  @JsonKey(name: DatabaseConstants.colPath)
  final String path;

  /// Date when the directory was added (milliseconds since epoch).
  @JsonKey(
    name: DatabaseConstants.colAddedDate,
    fromJson: _dateTimeFromJsonNonNull,
    toJson: _dateTimeToJsonNonNull,
  )
  final DateTime addedDate;

  /// Date when the directory was last scanned (milliseconds since epoch, null if never scanned).
  @JsonKey(
    name: DatabaseConstants.colLastScannedDate,
    fromJson: _dateTimeFromJsonNullable,
    toJson: _dateTimeToJsonNullable,
  )
  final DateTime? lastScannedDate;

  /// Creates a ScanDirectoryModel instance.
  const ScanDirectoryModel({
    required this.id,
    required this.path,
    required this.addedDate,
    this.lastScannedDate,
  });

  /// Creates a ScanDirectoryModel from a database map.
  factory ScanDirectoryModel.fromMap(Map<String, dynamic> map) {
    return ScanDirectoryModel(
      id: map[DatabaseConstants.colId] as String,
      path: map[DatabaseConstants.colPath] as String,
      addedDate: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseConstants.colAddedDate] as int,
      ),
      lastScannedDate: map[DatabaseConstants.colLastScannedDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map[DatabaseConstants.colLastScannedDate] as int,
            )
          : null,
    );
  }

  /// Converts this ScanDirectoryModel to a database map.
  Map<String, dynamic> toMap() {
    return {
      DatabaseConstants.colId: id,
      DatabaseConstants.colPath: path,
      DatabaseConstants.colAddedDate: addedDate.millisecondsSinceEpoch,
      DatabaseConstants.colLastScannedDate: lastScannedDate?.millisecondsSinceEpoch,
    };
  }

  /// Creates a ScanDirectoryModel from JSON.
  factory ScanDirectoryModel.fromJson(Map<String, dynamic> json) =>
      _$ScanDirectoryModelFromJson(json);

  /// Converts this ScanDirectoryModel to JSON.
  Map<String, dynamic> toJson() => _$ScanDirectoryModelToJson(this);

  /// Creates a copy of this ScanDirectoryModel with the given fields replaced.
  ScanDirectoryModel copyWith({
    String? id,
    String? path,
    DateTime? addedDate,
    DateTime? lastScannedDate,
  }) {
    return ScanDirectoryModel(
      id: id ?? this.id,
      path: path ?? this.path,
      addedDate: addedDate ?? this.addedDate,
      lastScannedDate: lastScannedDate ?? this.lastScannedDate,
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

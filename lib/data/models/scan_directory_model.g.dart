// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_directory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanDirectoryModel _$ScanDirectoryModelFromJson(Map<String, dynamic> json) =>
    ScanDirectoryModel(
      id: json['id'] as String,
      path: json['path'] as String,
      addedDate: ScanDirectoryModel._dateTimeFromJsonNonNull(
        (json['added_date'] as num).toInt(),
      ),
      lastScannedDate: ScanDirectoryModel._dateTimeFromJsonNullable(
        (json['last_scanned_date'] as num?)?.toInt(),
      ),
    );

Map<String, dynamic> _$ScanDirectoryModelToJson(
  ScanDirectoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'path': instance.path,
  'added_date': ScanDirectoryModel._dateTimeToJsonNonNull(instance.addedDate),
  'last_scanned_date': ScanDirectoryModel._dateTimeToJsonNullable(
    instance.lastScannedDate,
  ),
};

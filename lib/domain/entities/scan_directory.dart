import 'package:equatable/equatable.dart';

/// Scan directory entity representing a scan directory in the domain layer.
///
/// This is a business object representing a directory added for game scanning.
class ScanDirectory extends Equatable {
  /// Unique identifier.
  final String id;

  /// Full path to the directory.
  final String path;

  /// Date when the directory was added.
  final DateTime addedDate;

  /// Date when the directory was last scanned (null if never scanned).
  final DateTime? lastScannedDate;

  /// Creates a ScanDirectory entity.
  const ScanDirectory({
    required this.id,
    required this.path,
    required this.addedDate,
    this.lastScannedDate,
  });

  /// Creates a copy of this ScanDirectory with the given fields replaced.
  ScanDirectory copyWith({
    String? id,
    String? path,
    DateTime? addedDate,
    DateTime? lastScannedDate,
  }) {
    return ScanDirectory(
      id: id ?? this.id,
      path: path ?? this.path,
      addedDate: addedDate ?? this.addedDate,
      lastScannedDate: lastScannedDate ?? this.lastScannedDate,
    );
  }

  @override
  List<Object?> get props => [id, path, addedDate, lastScannedDate];
}

import 'package:squirrel_play/domain/entities/scan_directory.dart';

/// Abstract repository interface for scan directory operations.
///
/// Defines the contract for scan directory data access. Implementations handle
/// the actual database operations.
abstract class ScanDirectoryRepository {
  /// Gets all scan directories.
  Future<List<ScanDirectory>> getAllDirectories();

  /// Gets a scan directory by its ID.
  Future<ScanDirectory?> getDirectoryById(String id);

  /// Gets a scan directory by its path.
  Future<ScanDirectory?> getDirectoryByPath(String path);

  /// Adds a new scan directory.
  Future<ScanDirectory> addDirectory(String path);

  /// Deletes a scan directory.
  Future<void> deleteDirectory(String id);

  /// Updates the last scanned date of a directory.
  Future<ScanDirectory> updateLastScanned(String id, DateTime date);

  /// Checks if a directory with the given path already exists.
  Future<bool> directoryExists(String path);
}

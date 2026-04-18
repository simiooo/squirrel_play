/// Mutable data holder for the metadata chain of responsibility.
///
/// Carries the executable file information through the chain,
/// with mutable fields that handlers populate.
class DirectoryContext {
  /// Full path to the executable file.
  final String executablePath;

  /// Filename of the executable (e.g., "game.exe").
  final String fileName;

  /// Path to the directory containing the executable.
  final String directoryPath;

  /// Parsed title, set by handlers.
  String? title;

  /// Steam App ID, set by [SteamDirectoryHandler].
  String? steamAppId;

  /// Creates a [DirectoryContext] with the given immutable fields.
  ///
  /// [title] and [steamAppId] start as null and are populated by handlers.
  DirectoryContext({
    required this.executablePath,
    required this.fileName,
    required this.directoryPath,
  });

  @override
  String toString() {
    return 'DirectoryContext('
        'executablePath: $executablePath, '
        'fileName: $fileName, '
        'directoryPath: $directoryPath, '
        'title: $title, '
        'steamAppId: $steamAppId)';
  }
}

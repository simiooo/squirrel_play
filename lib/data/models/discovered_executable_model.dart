/// Runtime model for discovered executable files during directory scanning.
///
/// This model is NOT persisted to the database. It represents a discovered
/// .exe file during the scanning process, with selection state for the UI.
/// No .g.dart file is generated for this model.
class DiscoveredExecutableModel {
  /// Full path to the executable file.
  final String path;

  /// Filename of the executable (e.g., "game.exe").
  final String fileName;

  /// ID of the scan directory this executable was found in.
  final String directoryId;

  /// Whether this executable is selected for addition to the library.
  bool isSelected;

  /// Whether this executable is already in the game library.
  final bool isAlreadyAdded;

  /// Creates a DiscoveredExecutableModel instance.
  DiscoveredExecutableModel({
    required this.path,
    required this.fileName,
    required this.directoryId,
    this.isSelected = false,
    this.isAlreadyAdded = false,
  });

  /// Creates a copy of this DiscoveredExecutableModel with the given fields replaced.
  DiscoveredExecutableModel copyWith({
    String? path,
    String? fileName,
    String? directoryId,
    bool? isSelected,
    bool? isAlreadyAdded,
  }) {
    return DiscoveredExecutableModel(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      directoryId: directoryId ?? this.directoryId,
      isSelected: isSelected ?? this.isSelected,
      isAlreadyAdded: isAlreadyAdded ?? this.isAlreadyAdded,
    );
  }

  /// Toggles the selection state.
  void toggleSelection() {
    isSelected = !isSelected;
  }

  @override
  String toString() {
    return 'DiscoveredExecutableModel('
        'path: $path, '
        'fileName: $fileName, '
        'directoryId: $directoryId, '
        'isSelected: $isSelected, '
        'isAlreadyAdded: $isAlreadyAdded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredExecutableModel &&
        other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}

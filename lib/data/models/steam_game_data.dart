import 'package:json_annotation/json_annotation.dart';

part 'steam_game_data.g.dart';

/// Pure data model representing a Steam game.
///
/// This model is JSON-serializable and represents the core data
/// about a Steam game installation. UI state (selection, etc.)
/// is managed separately in the BLoC.
@JsonSerializable()
class SteamGameData {
  /// Steam application ID.
  @JsonKey(name: 'app_id')
  final String appId;

  /// Game name.
  @JsonKey(name: 'name')
  final String name;

  /// Installation directory name (within steamapps/common/).
  @JsonKey(name: 'install_dir')
  final String installDir;

  /// Library path where this game is installed.
  @JsonKey(name: 'library_path')
  final String libraryPath;

  /// Installation size in bytes.
  @JsonKey(name: 'install_size')
  final int? installSize;

  /// List of possible executable paths found in the install directory.
  @JsonKey(name: 'possible_executable_paths')
  final List<String> possibleExecutablePaths;

  /// Creates a SteamGameData instance.
  const SteamGameData({
    required this.appId,
    required this.name,
    required this.installDir,
    required this.libraryPath,
    this.installSize,
    this.possibleExecutablePaths = const [],
  });

  /// Full installation path.
  String get installPath => '$libraryPath/steamapps/common/$installDir';

  /// Primary executable (first in the list) or null if none found.
  String? get primaryExecutable =>
      possibleExecutablePaths.isNotEmpty ? possibleExecutablePaths.first : null;

  /// Whether the game appears to be installed (has at least one executable).
  bool get isInstalled => possibleExecutablePaths.isNotEmpty;

  /// Factory constructor for creating a new instance from JSON.
  factory SteamGameData.fromJson(Map<String, dynamic> json) =>
      _$SteamGameDataFromJson(json);

  /// Converts this instance to JSON.
  Map<String, dynamic> toJson() => _$SteamGameDataToJson(this);

  /// Creates a copy with the given fields replaced.
  SteamGameData copyWith({
    String? appId,
    String? name,
    String? installDir,
    String? libraryPath,
    int? installSize,
    List<String>? possibleExecutablePaths,
  }) {
    return SteamGameData(
      appId: appId ?? this.appId,
      name: name ?? this.name,
      installDir: installDir ?? this.installDir,
      libraryPath: libraryPath ?? this.libraryPath,
      installSize: installSize ?? this.installSize,
      possibleExecutablePaths:
          possibleExecutablePaths ?? this.possibleExecutablePaths,
    );
  }

  @override
  String toString() {
    return 'SteamGameData(appId: $appId, name: $name, installDir: $installDir, '
        'libraryPath: $libraryPath, installSize: $installSize, '
        'executables: ${possibleExecutablePaths.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SteamGameData && other.appId == appId;
  }

  @override
  int get hashCode => appId.hashCode;
}

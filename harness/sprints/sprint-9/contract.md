# Sprint Contract: Steam Game Scanning Integration

## Scope
Add a new "Steam Games" tab to the Add Game dialog that detects installed Steam games by parsing Steam's library configuration files (VDF/ACF) and allows users to import them directly into the Squirrel Play library.

**Dependencies**: Sprint 3 (Add Game dialog), Sprint 8 (picker button fixes) - both completed.

## Implementation Plan

### 1. Platform Abstraction for Testability

#### PlatformInfo Interface (`lib/core/platform/platform_info.dart`)
```dart
abstract class PlatformInfo {
  bool get isWindows;
  bool get isLinux;
  bool get isMacOS;
  String get homeDirectory;
  String get pathSeparator;
}

class PlatformInfoImpl implements PlatformInfo {
  @override
  bool get isWindows => Platform.isWindows;
  @override
  bool get isLinux => Platform.isLinux;
  @override
  bool get isMacOS => Platform.isMacOS;
  @override
  String get homeDirectory => Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  @override
  String get pathSeparator => Platform.pathSeparator;
}
```
- Register `PlatformInfo` as singleton in DI
- All Steam services receive `PlatformInfo` via constructor injection
- Enables unit testing of platform-specific path logic on any OS

### 2. Three New Services for Steam Integration

#### SteamDetector (`lib/data/services/steam_detector.dart`)
**Dependencies**: `PlatformInfo`

- Detect Steam installation directory per platform:
  - Windows: `C:\Program Files (x86)\Steam` or `C:\Program Files\Steam`
  - Linux: `~/.steam/steam` or `~/.local/share/Steam`
  - macOS: `~/Library/Application Support/Steam`
- Use injected `PlatformInfo` for platform detection (testable)
- Fall back to checking common paths if auto-detection fails
- Provide method to validate a manually specified path

#### SteamLibraryParser (`lib/data/services/steam_library_parser.dart`)
**Dependencies**: `PlatformInfo`

- Parse `steamapps/libraryfolders.vdf` to find all Steam library locations
- Implement VDF format parser with robustness features:
  - Handle UTF-8 BOM at file start
  - Handle both CRLF and LF line endings
  - Handle Unicode characters in paths
  - Gracefully skip malformed entries
- Extract `path` values for each library folder entry
- Return list of library folder paths

#### SteamManifestParser (`lib/data/services/steam_manifest_parser.dart`)
**Dependencies**: `PlatformInfo`, `FileScannerService` (for executable discovery)

- Scan each `steamapps` directory for `appmanifest_*.acf` files
- Parse ACF format with robustness features (same as VDF: BOM, line endings, Unicode)
- Extract fields:
  - `appid`: Steam application ID
  - `name`: Game name
  - `installdir`: Installation directory name
  - `StagingSize`: Installation size in bytes
- **Cross-platform executable discovery** (replaces hardcoded `.exe`):
  - Construct install path: `{library_path}/steamapps/common/{installdir}`
  - Scan install directory for executable files using `FileScannerService` patterns
  - Return list of possible executable paths (not just one)
  - On Windows: prioritize `.exe` files
  - On Linux: look for files without extension with executable permissions
  - On macOS: look for `.app` bundles or executables

### 3. Data Models

#### SteamGameData (`lib/data/models/steam_game_model.dart`)
Pure data model (no UI state):
```dart
class SteamGameData {
  final String appId;
  final String name;
  final String installDir;
  final String libraryPath;
  final int? installSize;
  final List<String> possibleExecutablePaths;
  
  String get installPath => '$libraryPath/steamapps/common/$installDir';
  String? get primaryExecutable => possibleExecutablePaths.isNotEmpty ? possibleExecutablePaths.first : null;
  bool get isInstalled => possibleExecutablePaths.isNotEmpty;
  
  SteamGameData copyWith({...});
}
```

#### SteamGameViewModel (in BLoC state)
UI state managed by BLoC:
```dart
class SteamGameViewModel {
  final SteamGameData data;
  final bool isSelected;
  final bool isAlreadyAdded;
  
  SteamGameViewModel({...});
}
```

### 4. SteamScannerBloc (`lib/presentation/blocs/steam_scanner/steam_scanner_bloc.dart`)

**Dependencies**: `SteamDetector`, `SteamLibraryParser`, `SteamManifestParser`, `GameRepository`, `MetadataBloc` (via getIt), `PlatformInfo`

**States**:
- `SteamScannerInitial` - Initial state, ready to detect
- `SteamScannerLoading` - Detecting/scanning in progress
- `SteamScannerLoaded` - Games found, showing list with checkboxes
  - Contains: `List<SteamGameViewModel> games`, `int selectedCount`
- `SteamScannerError` - Steam not found or permission error
- `SteamScannerImporting` - Importing selected games (with progress)
- `SteamScannerImportComplete` - Import finished, contains results

**Events**:
- `DetectSteam` - Start auto-detection of Steam installation
- `SetSteamPath(String path)` - Manual override for Steam path
- `ScanSteamLibrary` - Scan detected Steam libraries for games
- `ToggleGameSelection(String appId)` - Toggle checkbox for a game
- `SelectAllGames` / `DeselectAllGames` - Bulk selection
- `ImportSelectedGames` - Import checked games to library
- `ResetScanner` - Reset to initial state

**Duplicate Detection**:
- Inject `GameRepository` in constructor
- When scanning, call `_gameRepository.gameExists(executablePath)` for each game's primary executable
- Set `isAlreadyAdded` on view model based on result

**Metadata Fetch Integration (Option A)**:
- After importing games via `GameRepository.addGame()`, dispatch `FetchGameMetadata` event to `MetadataBloc` via `getIt<MetadataBloc>().add(FetchGameMetadata(gameId: newGame.id))`
- This triggers automatic RAWG metadata fetch for each imported Steam game

### 5. SteamGamesTab Widget (`lib/presentation/widgets/steam_games_tab.dart`)

**Features**:
- Show loading state while detecting/scanning Steam
- Show error state if Steam not found with manual path input
- Display list of installed Steam games with checkboxes
- Show game name, app ID, installation path, install size (if available)
- Filter out already-imported games (check against existing library via BLoC)
- "Select All" / "Select None" buttons
- "Import X Games" confirm button
- Manual Steam path override option if auto-detection fails

**Gamepad Navigation**:
- All checkboxes focusable via D-pad
- Confirm button focusable
- Manual path input focusable (when in error state)

### 6. Integration with AddGameDialog

**Changes to `lib/presentation/widgets/add_game_dialog.dart`**:
- Add third tab: "Steam Games" (index 2)
- Add third FocusNode for the new tab
- Update `_buildTabContent()` to include SteamGamesTab when index == 2
- Update keyboard navigation (arrow keys) to handle 3 tabs instead of 2
- Wrap SteamGamesTab with BlocProvider for SteamScannerBloc

**Changes to `lib/presentation/blocs/add_game/add_game_bloc.dart`**:
- Update `_onSwitchTab` handler to handle `tabIndex == 2`:
```dart
void _onSwitchTab(SwitchTab event, Emitter<AddGameState> emit) {
  if (event.tabIndex == 0) {
    emit(const ManualAddForm());
  } else if (event.tabIndex == 1) {
    emit(const ScanDirectoryForm());
  } else if (event.tabIndex == 2) {
    emit(const SteamGamesForm());
  }
}
```
- Add new state `SteamGamesForm` to `AddGameState` union

**Changes to `lib/app/di.dart`**:
- Register `PlatformInfo` as singleton
- Register `SteamDetector`, `SteamLibraryParser`, `SteamManifestParser` as singletons (with `PlatformInfo` injected)
- Register `SteamScannerBloc` as factory with all dependencies:
  - `SteamDetector`, `SteamLibraryParser`, `SteamManifestParser`
  - `GameRepository` (for duplicate detection)
  - `getIt<MetadataBloc>()` (for metadata fetch)
  - `PlatformInfo`

### 7. VDF/ACF File Parsing with Robustness

**VDF/ACF Format Characteristics**:
- Key-value format with quoted strings
- Nested sections using curly braces
- May contain UTF-8 BOM at start
- May use CRLF or LF line endings
- Values may contain Unicode characters

**Parser Implementation**:
- Strip BOM (`\xEF\xBB\xBF`) if present at file start
- Normalize line endings to LF before parsing
- Handle quoted strings with escaped quotes (`\"`)
- Track nesting level with brace counting
- Return `Map<String, dynamic>` structure
- Gracefully skip malformed entries rather than crashing
- Log warnings for unparseable lines

## Success Criteria

| Criterion | How to Verify |
|-----------|---------------|
| 1. Steam auto-detection works on Linux | Open Steam Games tab on Linux system with Steam installed → Steam path auto-detected |
| 2. libraryfolders.vdf is parsed correctly | Given multiple library folders → all paths extracted and scanned |
| 3. appmanifest_*.acf files are parsed correctly | Games show correct name, app ID, install directory, and size |
| 4. Steam games list displays with checkboxes | Each game has checkbox, name, app ID, path, and size visible |
| 5. Already-added games are filtered out | Games already in library show as "Already Added" and disabled (uses GameRepository) |
| 6. Selected games can be imported | Check games → click Import → games appear in library |
| 7. Imported games trigger metadata fetch | After import, RAWG metadata is fetched automatically (via MetadataBloc event) |
| 8. Manual Steam path override works | When auto-detect fails, user can enter path manually |
| 9. Error state when Steam not found | On system without Steam, shows helpful error message |
| 10. Gamepad navigation works | Can navigate to all checkboxes and buttons via D-pad |
| 11. Tab switching works with 3 tabs | Left/right arrows cycle through all 3 tabs correctly (AddGameBloc handles index 2) |
| 12. Cross-platform executable discovery | On Linux, executable path is NOT hardcoded to `.exe` - scans for actual executables |
| 13. VDF/ACF parser handles edge cases | BOM, CRLF/LF, Unicode, and malformed entries handled gracefully |

## Out of Scope for This Sprint

1. **Windows/macOS Steam detection testing** - Will implement paths but primary testing on Linux
2. **Steam Workshop/mod integration** - Not included
3. **Steam playtime/import metadata** - Only basic game import
4. **Non-Steam games in Steam libraries** - Only parse official appmanifest files
5. **Steam authentication/API integration** - File-based scanning only
6. **Automatic Steam path persistence** - Manual override is per-session only
7. **Multiple executable selection per game** - Uses first discovered executable

## Files to Create/Modify

### New Files:
- `lib/core/platform/platform_info.dart` (PlatformInfo interface and implementation)
- `lib/data/services/steam_detector.dart`
- `lib/data/services/steam_library_parser.dart`
- `lib/data/services/steam_manifest_parser.dart`
- `lib/data/models/steam_game_model.dart`
- `lib/presentation/blocs/steam_scanner/steam_scanner_bloc.dart`
- `lib/presentation/blocs/steam_scanner/steam_scanner_event.dart`
- `lib/presentation/blocs/steam_scanner/steam_scanner_state.dart`
- `lib/presentation/widgets/steam_games_tab.dart`

### Modified Files:
- `lib/presentation/widgets/add_game_dialog.dart` (add third tab)
- `lib/presentation/blocs/add_game/add_game_bloc.dart` (handle tabIndex == 2)
- `lib/presentation/blocs/add_game/add_game_state.dart` (add SteamGamesForm state)
- `lib/app/di.dart` (register new services, PlatformInfo, and bloc with all dependencies)

## Testing Approach

1. Unit tests for PlatformInfo with mocked implementation
2. Unit tests for VDF/ACF parsers with sample files (including BOM, CRLF, Unicode)
3. Unit tests for SteamDetector with mocked PlatformInfo
4. Unit tests for SteamManifestParser with mocked FileScannerService
5. Widget tests for SteamGamesTab with mocked SteamScannerBloc
6. Integration test: Open dialog → switch to Steam tab → verify loading state
7. Cross-platform test: Verify executable discovery works on Linux (no .exe hardcoding)

## Acceptance Criteria (from spec)

- Given Steam is installed on the system, when the user opens the Steam Games tab, then the tab detects the Steam installation directory
- Given Steam is detected, when scanning completes, then all installed Steam games are listed with game names
- Given the Steam games list, when the user checks specific games and confirms, then the selected games are imported to the Squirrel Play library
- Given a Steam game is imported, when viewing the library, then the game appears with metadata fetched from RAWG
- Given Steam is not installed, when the user opens the Steam Games tab, then an error message is shown with an option to manually specify the Steam path
- Given a Steam game is already in the library, when scanning, then that game is shown as "Already Added" and disabled from selection
- Given the Steam Games tab, when the user navigates via D-pad, then all interactive elements (checkboxes, confirm button, cancel button) are focusable

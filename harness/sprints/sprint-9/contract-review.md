# Contract Review: Sprint 9

## Assessment: NEEDS_REVISION

The contract is largely well-structured and covers the core Steam scanning functionality, but there are several architectural concerns, missing details, and design inconsistencies with the existing codebase that need to be addressed before implementation proceeds.

## Scope Coverage

The contract aligns with the Sprint 9 section of the spec (lines 563-625) in terms of the three-service architecture and tab integration. However, there are notable gaps:

1. **Platform-specific executable path logic is wrong for Linux**: The contract's `SteamGame` model hardcodes `executablePath` as `{libraryPath}/steamapps/common/{installdir}/{installdir}.exe`. This `.exe` extension is Windows-only. The spec says the target platforms are Linux, Windows, and macOS. On Linux, executables typically have no extension; on macOS they're often `.app` bundles. The executable path derivation needs platform awareness, not just a hard-coded `.exe` suffix. This is a **functional correctness issue** — on Linux (the primary dev/test platform), no `.exe` files will be found and `isInstalled` will always return `false`.

2. **Missing integration with `GameRepository` for "already added" detection**: Criterion 5 says "Games already in library show as 'Already Added' and disabled." The contract mentions `isAlreadyAdded` in the `SteamGame` model but doesn't specify how this is determined. The existing `AddGameBloc` uses `_gameRepository.gameExists(executablePath)` for duplicate detection. The contract needs to clarify that `SteamScannerBloc` must inject `GameRepository` to check existing games, or explain how this cross-referencing works. Without this, the "already added" filtering won't work.

3. **Metadata fetching integration is underspecified**: Criterion 7 says "Imported games trigger metadata fetch" and the spec acceptance criteria say "the game appears with metadata fetched from RAWG." The contract mentions `_onGamesAdded` callback pattern in its integration section but doesn't specify how `SteamScannerBloc` will trigger metadata fetching. Looking at the existing `AddGameBloc`, it uses an `OnGamesAddedCallback` parameter passed through the dialog's `BlocProvider`. The contract needs to explicitly define how `SteamScannerBloc` interacts with `MetadataBloc` — does it use a similar callback mechanism, dispatch an event, or rely on the parent `AddGameBloc` to coordinate?

4. **Platform detection via `Platform` won't work in tests**: The contract specifies using `Platform.isWindows`, `Platform.isLinux`, `Platform.isMacOS` directly in `SteamDetector`. This is a hard dependency on `dart:io`'s `Platform` class which cannot be mocked or overridden in tests. The contract should specify that `SteamDetector` accepts a platform-abstraction (interface) for testability, so unit tests can verify Linux/Windows/macOS path logic without running on those actual platforms.

## Success Criteria Review

- **Criterion 1 (Steam auto-detection on Linux)**: Specific and testable ✅
- **Criterion 2 (libraryfolders.vdf parsing)**: Specific and testable ✅
- **Criterion 3 (appmanifest parsing)**: Specific but lacks edge case testing — what about corrupted/incomplete ACF files? ⚠️
- **Criterion 4 (Game list with checkboxes)**: Specific and testable ✅
- **Criterion 5 (Already-added filtering)**: Specific but implementation path unclear as noted above ⚠️
- **Criterion 6 (Import selected games)**: Specific and testable ✅
- **Criterion 7 (Metadata fetch after import)**: Measurable but implementation details missing ⚠️
- **Criterion 8 (Manual path override)**: Specific and testable ✅
- **Criterion 9 (Error state when Steam not found)**: Specific and testable ✅
- **Criterion 10 (Gamepad navigation)**: Specific and testable ✅
- **Criterion 11 (3-tab switching)**: Specific and testable ✅

## Suggested Changes

### 1. Fix executable path for cross-platform support (Critical)
The `SteamGame` model must not hardcode `.exe`. Instead:
- On Windows: use `{installdir}.exe`
- On Linux: use `{installdir}` (no extension) or look for an actual executable file in the install directory
- On macOS: use `{installdir}.app` or look for actual executables
- Consider scanning the `installdir` for actual executable files rather than assuming a naming convention, since many Steam games don't follow the `installdir}/{installdir}.exe` pattern at all. The existing `FileScannerService` already does executable discovery — could this be reused?

Consider making `executablePath` optional or making `isInstalled` more sophisticated — perhaps the import should create a `Game` with the game directory as a starting point and let the user/edit flow resolve the exact executable later.

### 2. Specify GameRepository injection for duplicate detection (Important)
The `SteamScannerBloc` needs `GameRepository` injected to check `gameExists()` for each discovered Steam game. Add this explicitly to the BLoC's constructor dependencies and to the DI registration in `di.dart`.

### 3. Specify metadata fetch integration (Important)
Explicitly define how metadata fetching works after Steam game import. Options:
- **Option A**: `SteamScannerBloc` dispatches events to `MetadataBloc` via `getIt` after importing
- **Option B**: Use `OnGamesAddedCallback` pattern similar to `AddGameBloc`
- **Option C**: Parent `AddGameDialog` coordinates — dialog listens to `SteamScannerBloc` completion and triggers metadata fetch

Whichever is chosen, document it. Option A is simplest.

### 4. Add platform abstraction for testability (Recommended)
Define a `PlatformInfo` interface in `core/`:
```dart
abstract class PlatformInfo {
  bool get isWindows;
  bool get isLinux;
  bool get isMacOS;
  String get homeDirectory;
}
```
With a `PlatformInfoImpl` that delegates to `dart:io`'s `Platform`. Register in DI. `SteamDetector` takes `PlatformInfo` as a constructor parameter. This makes all three services independently testable.

### 5. Address the SteamScannerBloc vs AddGameBloc relationship (Important)
The contract creates a **separate** `SteamScannerBloc`. This is the right call — the `AddGameBloc` is already complex (315 lines). But the contract doesn't specify:
- How the dialog coordinates between two blocs (AddGameBloc for tab state, SteamScannerBloc for Steam-specific state)
- Whether `AddGameBloc.SwitchTab` needs a `tabIndex == 2` handler (currently it only handles 0 and 1 per the code on line 308-313)
- How the "Import X Games" action interacts with `AddGameBloc` — does `SteamScannerBloc` directly save games via `GameRepository`, or does it emit an event that `AddGameBloc` coordinates?

The `SwitchTab` event currently does:
```dart
void _onSwitchTab(SwitchTab event, Emitter<AddGameState> emit) {
    if (event.tabIndex == 0) {
      emit(const ManualAddForm());
    } else {
      emit(const ScanDirectoryForm());
    }
}
```
This will break when `tabIndex == 2`. Either `AddGameBloc` needs updating or `SwitchTab` handling needs to be clarified.

### 6. File location inconsistency with spec (Minor)
The spec says the Steam tab widget should be at `lib/presentation/widgets/add_game/steam_games_tab.dart`, but the contract puts it at `lib/presentation/widgets/steam_games_tab.dart`. The existing tabs (`manual_add_tab.dart`, `scan_directory_tab.dart`) are directly under `lib/presentation/widgets/` (not in an `add_game/` subdirectory), so the contract's placement is actually consistent with the current codebase. The spec is slightly off. Keep the contract's location.

### 7. VDF/ACF parser robustness (Minor)
The contract mentions handling "quoted strings with escaped quotes" but doesn't mention:
- Handling BOM (byte order mark) in Steam config files
- Handling files with different line endings (CRLF vs LF)
- Handling empty or malformed entries gracefully
- Character encoding considerations (Steam game names can contain Unicode)

### 8. SteamScannerBloc state design consideration (Minor)
The contract adds `SteamScannerImporting` state. The spec only lists 4 states (`Initial`, `Loading`, `Loaded`, `Error`). The importing state is reasonable (it shows progress while adding games to library), but consider whether `SteamScannerLoaded` should carry data about the import result (success/partial failure) before returning to `Loaded` or transitioning to a success state that closes the dialog.

### 9. Missing: `isSelected` on `SteamGame` should not be in the data model (Minor)
The `SteamGame` model includes `isSelected` and `isAlreadyAdded` — these are UI state, not data. This mirrors the pattern used in `DiscoveredExecutableModel` which also mixes data and UI state. It works but it's not clean. Consider splitting into `SteamGameData` (pure data) and having selection state managed in the BLoC state classes.

### 10. Missing: Steam installation size data (Minor)
The contract includes `StagingSize` in the manifest parser but the `SteamGame` model doesn't have a field for it. Either add it to the model or clarify it's deliberately excluded.

## Test Plan Preview

When evaluating the completed sprint, I will:

1. **Steam detection**: Verify `SteamDetector` finds Steam on the current Linux system. Test with a non-existent path to verify error handling.
2. **VDF/ACF parsing**: Test with real `libraryfolders.vdf` and `appmanifest_*.acf` files from a Steam installation. Also test with malformed/empty files.
3. **Tab switching**: Open Add Game dialog, verify all 3 tabs work with keyboard arrows (left/right).
4. **Game list**: Verify Steam games appear with correct names, paths, and app IDs.
5. **Already-added filtering**: Import a game, re-scan, verify it shows as already added.
6. **Import flow**: Import selected games, verify they appear in the library with metadata.
7. **Manual path override**: Enter an invalid path, verify error handling; enter a valid Steam path, verify scanning works.
8. **Gamepad navigation**: Tab through all checkboxes and buttons via D-pad/arrow keys.
9. **Edge cases**: Empty Steam library, Steam with no games installed, Steam path with spaces/special characters.
10. **Linux executable path**: Verify that on Linux, the executable path is NOT hardcoded to `.exe`.
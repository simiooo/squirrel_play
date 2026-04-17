# Handoff: Sprint 9 — Round 2 (Fixes Applied)

## Status: Ready for Re-Evaluation

## Fixes Applied (Post Round 1 Evaluation)

### 1. CRITICAL: Fixed Install Path Calculation Bug
**File:** `lib/data/services/steam_manifest_parser.dart`, line 166

**Problem:** Broken string interpolation `'$_joinPath(libraryPath, "steamapps/common")$installDir'` was not actually calling `_joinPath` - it was interpolating the method tear-off as a string, producing garbage paths.

**Fix:** Changed to proper nested `_joinPath` calls:
```dart
final commonPath = _joinPath(_joinPath(libraryPath, 'steamapps'), 'common');
final installPath = _joinPath(commonPath, installDir);
```

This ensures correct paths like `/home/user/.steam/steam/steamapps/common/Half-Life 2` instead of `Closure: ...Hollow Knight`.

### 2. Removed Unused FileScannerService Parameter
**File:** `lib/data/services/steam_manifest_parser.dart`

**Problem:** Constructor accepted `FileScannerService` but never stored or used it.

**Fix:** Removed the parameter from constructor and updated DI registration in `lib/app/di.dart`.

### 3. Fixed Platform Usage in SteamGamesTab
**File:** `lib/presentation/widgets/steam_games_tab.dart`

**Problem:** `_getDefaultSteamPath()` used `dart:io` `Platform.isLinux` etc directly, bypassing the `PlatformInfo` abstraction.

**Fix:** 
- Removed `import 'dart:io'`
- Added `import '../../../core/services/platform_info.dart'`
- Changed `_getDefaultSteamPath()` to get `PlatformInfo` from DI via `context.read<PlatformInfo>()`

### 4. Fixed Platform.pathSeparator in SteamManifestData
**File:** `lib/data/services/steam_manifest_parser.dart`

**Problem:** `SteamManifestData.installPath` getter used `Platform.pathSeparator` directly.

**Fix:** Added `pathSeparator` as a constructor parameter to `SteamManifestData`, passed from `_platformInfo.pathSeparator` when creating instances. The `installPath` getter now uses the injected `pathSeparator`.

## Verification

- ✅ `flutter analyze` - No errors (only pre-existing info/warnings)
- ✅ `flutter test` - All 307 tests pass

## What to Test

### 1. Steam Auto-Detection
1. Open the Add Game dialog (press "Add Game" in top bar)
2. Navigate to the "Steam Games" tab (right arrow twice)
3. The tab should automatically start detecting Steam
4. If Steam is installed on your Linux system, it should detect it at `~/.steam/steam` or `~/.local/share/Steam`

### 2. Steam Library Scanning
1. After Steam is detected, the library scanning should start automatically
2. All installed Steam games should appear in the list
3. Each game should show:
   - Game name
   - App ID
   - Checkbox (for games not already in library)
   - "Already Added" badge (for games already in library)

### 3. Game Selection and Import
1. Use D-pad to navigate to game checkboxes
2. Press A to toggle selection
3. Try "Select All" and "Select None" buttons
4. Select some games and press "Import X Games"
5. Import progress should show with game names
6. After import, games should appear in the library

### 4. Manual Path Override
1. If Steam is not auto-detected, an error message appears
2. Enter a manual path (e.g., `/home/user/.steam/steam`)
3. Click "Set Path & Scan"
4. Library should scan from the specified path

### 5. Duplicate Detection
1. Try importing a game that's already in the library
2. The game should show "Already Added" and be disabled
3. Importing should skip duplicates

### 6. Metadata Fetch
1. After importing Steam games, metadata should be fetched automatically
2. Check the library - imported games should have cover images and descriptions

### 7. Tab Navigation
1. Use left/right arrows to switch between all 3 tabs
2. Focus should move correctly between tabs
3. Tab content should update correctly

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

## Known Gaps

1. **Testing on Windows/macOS**: The implementation includes platform-specific paths for Windows and macOS, but primary testing has been on Linux.

2. **Steam path persistence**: Manual path override is per-session only. The path is not persisted between app restarts.

3. **Multiple executable selection**: If a game has multiple executables, only the first one is used. There's no UI to select which executable to use.

4. **Steam Workshop/Mods**: Not included in this sprint - only official appmanifest files are parsed.

## Files Changed

### New Files:
- `lib/core/services/platform_info.dart`
- `lib/data/services/steam_detector.dart`
- `lib/data/services/steam_library_parser.dart`
- `lib/data/services/steam_manifest_parser.dart`
- `lib/data/models/steam_game_data.dart`
- `lib/data/models/steam_game_data.g.dart` (generated)
- `lib/presentation/blocs/steam_scanner/steam_scanner_bloc.dart`
- `lib/presentation/blocs/steam_scanner/steam_scanner_event.dart`
- `lib/presentation/blocs/steam_scanner/steam_scanner_state.dart`
- `lib/presentation/widgets/steam_games_tab.dart`

### Modified Files:
- `lib/presentation/widgets/add_game_dialog.dart`
- `lib/presentation/blocs/add_game/add_game_bloc.dart`
- `lib/presentation/blocs/add_game/add_game_state.dart`
- `lib/app/di.dart`
- `lib/core/theme/design_tokens.dart`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_zh.dart`

## Verification Checklist

- [ ] Steam auto-detection works on your system
- [ ] Library scanning finds your installed Steam games
- [ ] Games display with correct names and app IDs
- [ ] Already-added games are marked correctly
- [ ] Checkboxes work with gamepad navigation
- [ ] Select All / Select None buttons work
- [ ] Import button imports selected games
- [ ] Imported games appear in library
- [ ] Metadata is fetched for imported games
- [ ] Manual path override works if auto-detection fails
- [ ] Tab navigation works with 3 tabs
- [ ] All 307 tests pass

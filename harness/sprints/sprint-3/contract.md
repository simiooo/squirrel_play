# Sprint Contract: Sprint 3 — Extract and Localize All Hardcoded Strings

## Scope

Extract every user-visible hardcoded English string from the four target widget files and replace them with `AppLocalizations` lookups, adding corresponding English and Chinese entries to the ARB files.

**Target files:**
- `lib/presentation/widgets/manual_add_tab.dart`
- `lib/presentation/widgets/scan_directory_tab.dart`
- `lib/presentation/widgets/steam_games_tab.dart`
- `lib/presentation/widgets/gamepad_file_browser.dart`

**ARB files:**
- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`

---

## Implementation Plan

### 1. Catalog and Extract Strings

For each of the four widget files, identify all user-visible hardcoded strings (labels, hints, button text, error messages, empty-state text, dynamic status text) and replace them with `AppLocalizations.of(context)!.key` or `AppLocalizations.of(context)?.key ?? 'fallback'`.

#### manual_add_tab.dart
| Hardcoded String | ARB Key |
|---|---|
| "Executable File" | `manualAddExecutableLabel` |
| "Browse..." | `manualAddBrowseButton` |
| "No file selected" | `manualAddNoFileSelected` |
| "Invalid file" | `manualAddInvalidFileError` |
| "Game Name" | `manualAddGameNameLabel` |
| "Enter game name" | `manualAddGameNameHint` |
| "Invalid name" | `manualAddInvalidNameError` |
| "Add Game" | `manualAddConfirmButton` |

#### scan_directory_tab.dart
| Hardcoded String | ARB Key | Notes |
|---|---|---|
| "Add Directory" | `scanDirectoryAddDirectoryButton` | |
| "Start Scan" | `scanDirectoryStartScanButton` | |
| "Cancel" | `buttonCancel` | **Reuse** existing generic key |
| "Found X executables (Y selected)" | `scanDirectoryFoundExecutables` | Placeholders: `totalCount` (int), `selectedCount` (int) |
| "Select All" | `scanDirectorySelectAllButton` | |
| "Select None" | `scanDirectorySelectNoneButton` | |
| "Add X Games" | `scanDirectoryAddGamesButton` | Placeholder: `count` (int) |
| "No executables found" | `scanDirectoryNoExecutablesTitle` | |
| "Try selecting a different directory or check that .exe files exist." | `scanDirectoryNoExecutablesSubtitle` | |
| "Select Different Directories" | `scanDirectorySelectDifferentDirectories` | |
| "Adding games..." | `scanDirectoryAddingGames` | |

#### steam_games_tab.dart
| Hardcoded String | ARB Key | Notes |
|---|---|---|
| "Initializing..." | `steamGamesInitializing` | |
| "Default: {path}" | `steamGamesDefaultPath` | Placeholder: `path` (String) |
| "Browse for Steam Folder" | `steamGamesBrowseSteamFolder` | |
| "Steam Path:" | `steamGamesSteamPathLabel` | |
| "Select All" | `steamGamesSelectAllButton` | |
| "Select None" | `steamGamesSelectNoneButton` | |
| "Rescan" | `topBarRescan` | **Reuse** existing generic key |
| "Found X games (Y already added)" | `steamGamesFoundGames` | Placeholders: `count` (int), `alreadyAddedCount` (int) |
| "No Steam games found" | `steamGamesNoGamesFound` | |
| "App ID: {appId}" | `steamGamesAppId` | Placeholder: `appId` (String) |
| "Already Added" | `steamGamesAlreadyAdded` | |
| "Importing games..." | `steamGamesImporting` | |
| "X of Y" | `steamGamesImportProgress` | Placeholders: `completed` (int), `total` (int) |
| "Import Complete!" | `steamGamesImportComplete` | |
| "X games imported" | `steamGamesImportedCount` | Placeholder: `count` (int) |
| "X skipped" | `steamGamesSkippedCount` | Placeholder: `count` (int) |
| "Errors:" | `steamGamesErrorsLabel` | |
| "Close" | `dialogClose` | **Reuse** existing generic key |
| "Import Selected Games" | `steamGamesImportButton` | Zero-selection state |
| "Import {count} Games" | `steamGamesImportCountButton` | Placeholder: `count` (int) |

#### gamepad_file_browser.dart
| Hardcoded String | ARB Key | Notes |
|---|---|---|
| "Select" (A button hint, file mode) | `gamepadNavSelect` | **Reuse** existing key; replace hardcoded fallback usage |
| "Open" (A button hint, directory mode) | `gamepadNavOpen` | **New key** |
| "Back" (B button hint) | `gamepadNavBack` | Already uses l10n with fallback; verify no hardcode remains |
| "Select Current" (Select button hint) | `gamepadNavSelectCurrent` | **New key** |
| "Toggle" (X button hint) | `gamepadNavToggle` | Already uses l10n with fallback; verify no hardcode remains |

The fallback strings `'Select File'` (title) and `'No items'` (empty state) already have l10n fallbacks using existing keys (`fileBrowserTitle`, `fileBrowserNoItems`). These will be verified but are expected to require no changes.

Gamepad button identifiers (`'A'`, `'B'`, `'X'`, `'Select'`) passed to `GamepadButtonIcon` are hardware labels and will **not** be localized.

### 2. Add English Strings to `app_en.arb`

Append all new keys to `lib/l10n/app_en.arb` with proper `@description` metadata for each entry. Dynamic strings will include `placeholders` definitions with appropriate types (`int` or `String`).

### 3. Add Chinese Translations to `app_zh.arb`

Append matching keys to `lib/l10n/app_zh.arb` with accurate Simplified Chinese translations and identical `@description` metadata (descriptions may be translated for consistency with existing `app_zh.arb` style).

### 4. Regenerate Localization Code

Run `flutter gen-l10n` to generate updated `app_localizations.dart` and language-specific delegates.

### 5. Verify Analysis and Tests

Run `flutter analyze` and `flutter test` to ensure no regressions.

---

## Success Criteria

1. **All user-visible strings are looked up via `AppLocalizations.of(context)`** (with null-safe fallbacks where appropriate). No user-facing string is rendered directly from a hardcoded literal without first attempting an l10n lookup. Hardware button identifiers (`'A'` / `'B'` / `'X'` / `'Select'`) are the only allowed exceptions.
2. **`app_en.arb` contains all new keys** with proper `@description` metadata and `placeholders` definitions for dynamic strings.
3. **`app_zh.arb` contains accurate Chinese translations** for all new keys.
4. **`flutter gen-l10n` completes without errors** and the generated `AppLocalizations` class contains all new keys.
5. **`flutter analyze` passes** with zero issues in the modified files.
6. **All 370 existing tests pass** (`flutter test`).
7. **Null-safe fallback pattern** is used where appropriate (`AppLocalizations.of(context)?.key ?? 'fallback'`), especially in dialog contexts where localization might not be immediately available.

---

## Out of Scope for This Sprint

- Adding new languages beyond English and Chinese.
- Localizing strings in files outside the four listed target files.
- Changing gamepad button identifier labels (`A`, `B`, `X`, `Select`) — these are hardware conventions.
- Refactoring widget logic or focus behavior (Sprints 1 and 2 scope).
- Adding new UI features or tests.
- Localizing file system conventions like `'..'` (parent directory) or `'/'` (root path separator).
- Dynamic messages originating from BLoC states (e.g., `SteamScannerLoading.message`, `ScanDirectoryForm.errorMessage`) are not covered by this sprint because their source strings reside outside the four target widget files.

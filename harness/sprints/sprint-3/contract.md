# Sprint Contract: Game Library Management — Add, Scan, Store

## Sprint Goal

Implement the complete game library management system: local SQLite database with all required tables, JSON-serializable data models, repository pattern for data access, and the full "Add Game" workflow including manual file selection, recursive directory scanning with progress indication, checkbox-based executable selection, and the Game Library grid page with gamepad navigation.

## Scope

### In Scope

1. **Database Layer**
   - SQLite database setup using `sqflite_common` (v2.5.6)
   - All 5 tables per schema: `games`, `game_metadata`, `game_genres`, `game_screenshots`, `scan_directories`
   - Database helper class with initialization, migration support, and connection management
   - Foreign key constraints and cascade deletes

2. **Data Models (JSON Serializable)**
   - `GameModel` — database DTO for games table
   - `GameMetadataModel` — database DTO for game_metadata table
   - `ScanDirectoryModel` — database DTO for scan_directories table
   - `DiscoveredExecutableModel` — runtime model for scan results (not persisted, no .g.dart)
   - All database models use `json_serializable` with generated `.g.dart` files

3. **Domain Layer (Repository Pattern)**
   - Abstract repository interfaces in `domain/repositories/`
   - `GameRepository` — CRUD operations for games
   - `ScanDirectoryRepository` — manage scan directories
   - Concrete implementations in `data/repositories/`

4. **Add Game Dialog (Complete Rewrite)**
   - Two-tab layout: "Manual Add" and "Scan Directory"
   - Tab switching with gamepad/keyboard support (left/right arrows)
   - Proper focus management within dialog

5. **Manual Add Flow**
   - File picker integration (`file_picker` v11.0.2) for .exe selection
   - Form with game name input validated using `formz` (v0.8.0)
   - Save to database on confirmation
   - Duplicate detection: silently skip executables already in library

6. **Scan Directory Flow**
   - Directory picker supporting multiple directory selection
   - Recursive file system scan for .exe files
   - Progress indicator showing: directories scanned, files found, current path
   - Cancelable scan operation
   - Results displayed as checkbox list with filename, path, and selection state
   - Check/uncheck individual items or select all/none
   - Save selected executables as games to database
   - Persist scan directories for future rescans
   - Manage Directories section: list saved directories with delete button (gamepad-focusable)

7. **Game Library Page**
   - Responsive grid layout using updated `GameCard` widgets with real data
   - Grid displays all games from database
   - Gamepad navigation: D-pad moves between cards (row/column traversal)
   - Focus animations on cards (scale/glow — already implemented in Sprint 2)
   - Empty state when no games exist
   - Game deletion via X button on focused card (gamepad `contextAction`)

8. **Rescan Functionality**
   - Rescan button in top bar opens Add Game dialog in "Scan Directory" tab
   - Pre-populated with saved directories, auto-starts scanning
   - Compare discovered executables against existing games
   - Present only new executables in checkbox list for confirmation
   - Add confirmed new games to library

9. **Game Deletion (Gamepad-Compatible)**
   - Press X button (gamepad `contextAction`) on focused GameCard to trigger deletion
   - Confirmation dialog with "Delete" and "Cancel" buttons (both gamepad-focusable)
   - Remove from database and refresh grid
   - Focus moves to adjacent card after deletion

10. **Error Handling**
    - Database failure: Show error message with retry button
    - Scan errors (permission denied): Show error message in scan results area
    - Duplicate games: Skip silently (don't add same executable twice)
    - Empty scan results: Show "No executables found" message
    - File picker cancelled: Return to form without error

### Out of Scope

- External API integration (metadata fetching) — Sprint 5
- Game launching/execution — Sprint 4
- Favorites system — Sprint 6
- Play count tracking — Sprint 6
- Game detail overlay/page — Sprint 4
- Cover/hero images (will use placeholders) — Sprint 5
- Home page Netflix-style rows — Sprint 4
- Scan directory removal UI deferred — Addressed in this sprint via Manage Directories section

## Detailed Deliverables

### 1. Database Layer

| File | Purpose |
|------|---------|
| `lib/data/datasources/local/database_helper.dart` | Database initialization, table creation, migration support |
| `lib/data/datasources/local/database_constants.dart` | Table names, column names, SQL statements |

**Schema Implementation:**
```sql
-- games table
CREATE TABLE games (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  executable_path TEXT NOT NULL UNIQUE,
  directory_id TEXT,
  added_date INTEGER NOT NULL,
  last_played_date INTEGER,
  is_favorite INTEGER NOT NULL DEFAULT 0,
  play_count INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (directory_id) REFERENCES scan_directories(id) ON DELETE SET NULL
);

-- game_metadata table
CREATE TABLE game_metadata (
  game_id TEXT PRIMARY KEY,
  external_id TEXT,
  description TEXT,
  cover_image_url TEXT,
  hero_image_url TEXT,
  release_date INTEGER,
  rating REAL,
  developer TEXT,
  publisher TEXT,
  last_fetched INTEGER NOT NULL,
  FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE
);

-- game_genres table
CREATE TABLE game_genres (
  game_id TEXT REFERENCES games(id) ON DELETE CASCADE,
  genre TEXT,
  PRIMARY KEY (game_id, genre)
);

-- game_screenshots table
CREATE TABLE game_screenshots (
  game_id TEXT REFERENCES games(id) ON DELETE CASCADE,
  screenshot_url TEXT,
  sort_order INTEGER,
  PRIMARY KEY (game_id, screenshot_url)
);

-- scan_directories table
CREATE TABLE scan_directories (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  added_date INTEGER NOT NULL,
  last_scanned_date INTEGER
);
```

**Date Storage Format:** All date fields stored as INTEGER (milliseconds since epoch). Conversion: `DateTime.fromMillisecondsSinceEpoch()` and `dateTime.millisecondsSinceEpoch`.

**Game ID Generation:** UUID v4 using the `uuid` package (`Uuid().v4()`).

### 2. Data Models

| File | Purpose |
|------|---------|
| `lib/data/models/game_model.dart` | Game database model with JSON serialization |
| `lib/data/models/game_model.g.dart` | Generated serialization code |
| `lib/data/models/game_metadata_model.dart` | Metadata database model |
| `lib/data/models/game_metadata_model.g.dart` | Generated serialization code |
| `lib/data/models/scan_directory_model.dart` | Scan directory database model |
| `lib/data/models/scan_directory_model.g.dart` | Generated serialization code |
| `lib/data/models/discovered_executable_model.dart` | Runtime model for scan results (not DB persisted, no .g.dart) |

### 3. Domain Layer

| File | Purpose |
|------|---------|
| `lib/domain/entities/game.dart` | Game entity (business object) |
| `lib/domain/entities/game_metadata.dart` | Metadata entity |
| `lib/domain/entities/scan_directory.dart` | Scan directory entity |
| `lib/domain/repositories/game_repository.dart` | Abstract GameRepository interface |
| `lib/domain/repositories/scan_directory_repository.dart` | Abstract ScanDirectoryRepository interface |

### 4. Repository Implementations

| File | Purpose |
|------|---------|
| `lib/data/repositories/game_repository_impl.dart` | Concrete GameRepository using SQLite |
| `lib/data/repositories/scan_directory_repository_impl.dart` | Concrete ScanDirectoryRepository using SQLite |

### 5. Services

| File | Purpose |
|------|---------|
| `lib/data/services/file_scanner_service.dart` | Recursive .exe file scanning with progress callbacks |
| `lib/data/services/game_launcher_service.dart` | Stub for game launching (full implementation in Sprint 4) |

### 6. BLoCs

| File | Purpose |
|------|---------|
| `lib/presentation/blocs/add_game/add_game_bloc.dart` | State machine for add game flow |
| `lib/presentation/blocs/add_game/add_game_event.dart` | Events: StartScan, SelectDirectory, ToggleExecutable, ConfirmSelection, etc. |
| `lib/presentation/blocs/add_game/add_game_state.dart` | States: Initial, Scanning, ScanComplete, Adding, Error |
| `lib/presentation/blocs/game_library/game_library_bloc.dart` | State machine for library grid |
| `lib/presentation/blocs/game_library/game_library_event.dart` | Events: LoadGames, DeleteGame, Refresh |
| `lib/presentation/blocs/game_library/game_library_state.dart` | States: Loading, Loaded, Empty, Error |

### 7. UI Components

| File | Purpose |
|------|---------|
| `lib/presentation/widgets/add_game_dialog.dart` | **Complete rewrite** — two-tab dialog with manual add and scan directory |
| `lib/presentation/widgets/manual_add_tab.dart` | Manual add tab content: file picker, name form |
| `lib/presentation/widgets/scan_directory_tab.dart` | Scan directory tab: directory picker, progress, results, manage directories |
| `lib/presentation/widgets/executable_checkbox_list.dart` | Checkbox list of discovered executables |
| `lib/presentation/widgets/scan_progress_indicator.dart` | Progress bar with stats (dirs scanned, files found) |
| `lib/presentation/pages/game_library_page.dart` | Full library page with responsive grid |
| `lib/presentation/widgets/game_grid.dart` | Responsive grid widget using GameCard |
| `lib/presentation/widgets/game_card.dart` | **Updated** — accepts GameModel, displays real title and placeholder cover |
| `lib/presentation/widgets/delete_game_dialog.dart` | Confirmation dialog for game deletion (Delete/Cancel buttons, gamepad-focusable) |
| `lib/presentation/widgets/manage_directories_section.dart` | List saved directories with delete buttons |
| `lib/presentation/widgets/error_state_widget.dart` | Reusable error display with retry button |
| `lib/presentation/widgets/empty_state_widget.dart` | Empty state with message and CTA |

### 8. Form Validation

| File | Purpose |
|------|---------|
| `lib/domain/validators/game_name_input.dart` | Formz input validator for game name |
| `lib/domain/validators/executable_path_input.dart` | Formz input validator for executable path |

### 9. Dependency Injection Updates

| File | Purpose |
|------|---------|
| `lib/app/di.dart` | Register new repositories, services, and BLoCs |

### 10. Unit Tests

| File | Purpose |
|------|---------|
| `test/data/repositories/game_repository_impl_test.dart` | GameRepository CRUD tests, cascade delete tests |
| `test/data/repositories/scan_directory_repository_impl_test.dart` | ScanDirectoryRepository tests |
| `test/data/services/file_scanner_service_test.dart` | File scanner service tests |

**Minimum Coverage:** All repository CRUD operations must have tests. All model fromJson/toJson roundtrips must be tested. Foreign key cascade deletes must be tested.

## Technical Constraints

### Required Dependencies
All these dependencies must be added to `pubspec.yaml`:

```yaml
dependencies:
  sqflite_common: ^2.5.6
  json_annotation: ^4.9.0
  formz: ^0.8.0
  file_picker: ^11.0.2
  mime: ^2.0.0
  uuid: ^4.0.0
  path: ^1.9.0

dev_dependencies:
  json_serializable: ^6.13.1
  build_runner: ^2.4.0
```

### Code Generation
- All data models MUST use `json_serializable` — no manual `fromJson`/`toJson`
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after model changes
- Generated `.g.dart` files must be committed to version control
- `DiscoveredExecutableModel` is runtime-only and does NOT have a `.g.dart` file

### Architecture Rules
- Repository pattern: abstract interfaces in `domain/repositories/`, concrete in `data/repositories/`
- Data models (DTOs) in `data/models/` — entities in `domain/entities/`
- Database operations only in repository implementations
- BLoCs handle business logic and state management
- UI widgets are "dumb" — they display state and emit events

### File Scanning Rules
- Only scan for `.exe` files (Windows executables)
- Use `mime` package to verify file type when possible
- Skip common non-game executables: `setup.exe`, `uninstall.exe`, `launcher.exe` (configurable skip list)
- Recursive scanning with depth limit (default: 10 levels)
- Progress callbacks every 100ms or 100 files (whichever comes first)
- Scan must be cancelable (use Stream or async with cancellation token)
- Duplicate detection: compare executable_path against existing games, skip silently

### Gamepad Navigation Requirements
- All interactive elements in Add Game dialog must be reachable via D-pad
- Tab switching: left/right arrows switch between Manual Add and Scan Directory tabs
- Checkbox list: up/down to navigate, A/Enter to toggle checkbox
- Focus must be trapped within dialog while open
- Escape/B closes dialog and returns focus to trigger button
- X button (contextAction) on focused GameCard triggers delete confirmation
- Delete dialog: Delete and Cancel buttons both focusable with D-pad

### Responsive Grid Breakpoints (Aligned with Spec)

| Breakpoint | Window Size | Columns | Card Size | Notes |
|------------|-------------|---------|-----------|-------|
| Compact | < 640px | 1 | 280×420 | Single column for small windows |
| Medium | 640–1024px | 2 | 200×300 | 2-column grid |
| Expanded | 1024–1440px | 3 | 200×300 | 3-column grid |
| Large | > 1440px | 4-5 | 240×360 | 4 columns at 1440-1920px, 5 columns above |

**Deviation Note:** The Library page uses the spec's breakpoints. The 1-column compact layout ensures readability on small screens, while the 4-5 column large layout maximizes screen real estate.

## Success Criteria

### Database & Models

| Criterion | Verification Method |
|-----------|---------------------|
| 1. Database initializes on app startup without errors | Check logs for "Database initialized" message; no exceptions |
| 2. All 5 tables are created with correct schema | Query `sqlite_master` table; verify table structures match spec |
| 3. GameModel has generated `.g.dart` file with working fromJson/toJson | Unit test: create model, serialize to JSON, deserialize, verify equality |
| 4. Foreign key constraints work (deleting game cascades to metadata) | Unit test: insert game with metadata, delete game, verify metadata deleted |
| 5. Dates stored as INTEGER milliseconds, converted correctly | Unit test: verify DateTime roundtrip through database |
| 6. Game IDs are UUID v4 format | Unit test: verify ID format matches UUID v4 pattern |

### Repository Pattern

| Criterion | Verification Method |
|-----------|---------------------|
| 7. GameRepository interface is in domain layer, implementation in data layer | File structure verification |
| 8. GameRepository can CRUD games (create, read, update, delete) | Unit tests for all CRUD operations |
| 9. ScanDirectoryRepository can add, list, and delete scan directories | Unit tests for directory management |
| 10. Repository methods return proper entities (not models) | Unit test: verify return type is Entity; code review |

### Manual Add Flow

| Criterion | Verification Method |
|-----------|---------------------|
| 11. "Manual Add" tab shows file picker when button pressed | Manual test: click "Select Executable" button, file picker opens |
| 12. File picker filters for .exe files | Manual test: verify filter is applied in file picker dialog |
| 13. Game name input validates with formz (required, min 1 char) | Manual test: empty name shows validation error; valid name accepted |
| 14. Confirming manual add saves game to database | Manual test: add game, query database, verify record exists |
| 15. Added game appears in Game Library grid | Manual test: after adding, navigate to Library, see new game card |
| 16. Duplicate executable is silently skipped | Manual test: try to add same .exe twice, second attempt shows no error, no duplicate in DB |

### Scan Directory Flow

| Criterion | Verification Method |
|-----------|---------------------|
| 17. "Scan Directory" tab allows selecting multiple directories | Manual test: click "Add Directory", select folder, repeat, see multiple listed |
| 18. "Start Scan" button begins recursive .exe scan | Manual test: click Start Scan, see progress indicator appear |
| 19. Progress indicator shows directories scanned count | Manual test: verify counter increases during scan |
| 20. Progress indicator shows files found count | Manual test: verify counter increases when .exe files found |
| 21. Scan can be cancelled with Cancel button | Manual test: click Cancel during scan, scanning stops, UI returns to ready state |
| 22. Scan results display as checkbox list with filename and path | Manual test: after scan, see list of discovered executables with checkboxes |
| 23. User can check/uncheck individual executables | Manual test: navigate to item, press A/Enter, checkbox toggles |
| 24. "Select All" and "Select None" buttons work | Manual test: click buttons, verify all checkboxes toggle |
| 25. Confirming selection saves checked games to database | Manual test: check some items, click Confirm, verify games added to DB |
| 26. Scan directories are persisted to database | Manual test: restart app, see previously added directories still listed |
| 27. Manage Directories section shows saved directories with delete | Manual test: see list of directories, each with delete button, gamepad-focusable |
| 28. Empty scan results show "No executables found" message | Manual test: scan empty directory, see empty state message |
| 29. Scan permission errors show error in results area | Manual test: scan inaccessible directory, see error message |

### Game Library Page

| Criterion | Verification Method |
|-----------|---------------------|
| 30. Library page shows responsive grid of GameCards | Visual verification: grid adapts to window size (1-5 columns per breakpoints) |
| 31. All games from database are displayed | Add 5 games, verify all 5 appear in grid |
| 32. D-pad navigation moves between cards with focus animation | Manual test: use arrow keys/gamepad to navigate, see scale/glow effects |
| 33. Empty state shown when no games in library | Clear database, open Library, see "No games" message with "Add Game" button that opens dialog |
| 34. Game deletion removes game from database and grid | Press X on focused card, confirm delete, verify it disappears from grid and DB |
| 35. GameCard displays real game title from database | Visual verification: card shows actual game title, not mock data |
| 36. GameCard shows placeholder cover when no image | Visual verification: placeholder gradient/color shown for games without cover |

### Rescan Functionality

| Criterion | Verification Method |
|-----------|---------------------|
| 37. Rescan button opens Add Game dialog in Scan Directory tab | Click Rescan, see dialog open with Scan Directory tab active |
| 38. Rescan auto-starts with saved directories | Dialog opens, scanning starts automatically with saved directories |
| 39. Rescan only shows new executables (not already in library) | Add directory, scan, add all. Add new .exe to directory, rescan, only new one shown |
| 40. Confirming rescan results adds new games to library | Rescan, check new items, confirm, verify new games appear in Library |
| 41. Deleted game reappears on rescan if executable still exists | Delete game, rescan, see executable in results list again |

### Gamepad/Keyboard Support

| Criterion | Verification Method |
|-----------|---------------------|
| 42. Left/right arrows switch tabs in Add Game dialog | Open dialog, press left/right, tabs switch |
| 43. Tab content updates when tab switched | Switch tabs, verify content changes (Manual vs Scan UI) |
| 44. Focus is maintained within dialog while open | Try to focus element outside dialog (should not work) |
| 45. Escape closes dialog and returns focus to trigger | Press Escape, dialog closes, focus returns to Add Game button |
| 46. All dialog interactive elements reachable via D-pad | Navigate to every button, checkbox, input field using arrow keys |
| 47. X button triggers delete dialog on focused GameCard | Focus a card, press X, delete confirmation dialog appears |
| 48. Delete dialog buttons are gamepad-focusable | In delete dialog, navigate between Delete and Cancel with D-pad |

### Error Handling

| Criterion | Verification Method |
|-----------|---------------------|
| 49. Database error shows message with retry button | Simulate DB error, see error widget with retry button |
| 50. File picker cancelled returns to form without error | Cancel file picker, verify no error shown, form still visible |

## Dependencies & Assumptions

### Dependencies from Previous Sprints

| Component | Sprint | Status | Usage in Sprint 3 |
|-----------|--------|--------|-------------------|
| `GameCard` widget | Sprint 2 | ⚠️ Modified | Updated to accept real Game data |
| `FocusableButton` | Sprint 2 | ✅ Complete | Dialog buttons, tab buttons |
| `FocusTraversalService` | Sprint 2 | ✅ Complete | Grid navigation, dialog focus trapping |
| `SoundService` | Sprint 2 | ✅ Complete | Sound hooks on actions |
| `TopBar` | Sprint 2 | ✅ Complete | Rescan button integration |
| `AddGameDialog` | Sprint 2 | ⚠️ Placeholder | **Complete rewrite required** |
| `MockGames` | Sprint 2 | ❌ Replaced | **Replaced with real database data** |

### Assumptions

1. **Sprint 2 code is stable** — The AddGameDialog placeholder can be completely replaced without breaking other functionality
2. **Windows platform** — File scanning targets .exe files; macOS/Linux support is future work
3. **File permissions** — App has permission to read selected directories
4. **No network required** — This sprint is local-only; no API calls for metadata
5. **Single user** — No multi-user support; database is per-machine

### New Dependencies to Add

```yaml
# pubspec.yaml additions
sqflite_common: ^2.5.6
json_annotation: ^4.9.0
formz: ^0.8.0
file_picker: ^11.0.2
mime: ^2.0.0
uuid: ^4.0.0
path: ^1.9.0

# dev_dependencies
json_serializable: ^6.13.1
build_runner: ^2.4.0
```

## Implementation Notes

### File Scanner Service Design

The file scanner should use a Stream-based API for progress reporting:

```dart
class FileScannerService {
  Stream<ScanProgress> scanDirectories(
    List<String> directories, {
    Set<String> skipPatterns = const {'setup', 'uninstall', 'launcher'},
    int maxDepth = 10,
  });
  
  void cancelScan();
}

class ScanProgress {
  final int directoriesScanned;
  final int filesFound;
  final String currentPath;
  final List<DiscoveredExecutable> executables;
  final bool isComplete;
  final String? error; // Error message if scan failed for a directory
}
```

### AddGameBloc State Machine

```
AddGameInitial
  ├── StartManualAdd → ManualAddForm
  ├── StartScanFlow → ScanDirectoryForm
  │     ├── DirectoriesSelected → ReadyToScan
  │     ├── StartScan → Scanning
  │     │     ├── ProgressUpdate → Scanning (with progress)
  │     │     ├── ScanError → ScanDirectoryForm (with error)
  │     │     ├── CancelScan → ScanDirectoryForm
  │     │     └── ScanComplete → ScanResults
  │     └── ScanResults
  │           ├── ToggleExecutable → ScanResults (updated selections)
  │           ├── ConfirmSelection → Adding → AddGameInitial (success)
  │           ├── EmptyResults → EmptyScanResults (show message)
  │           └── Cancel → ScanDirectoryForm
  └── ManualAddForm
        ├── FileSelected → ManualAddForm (with path)
        ├── FilePickerCancelled → ManualAddForm (no error)
        ├── NameChanged → ManualAddForm (with validation)
        ├── Confirm → Adding → AddGameInitial (success)
        └── DuplicateError → ManualAddForm (show error)
```

### GameLibraryBloc State Machine

```
LibraryLoading
  └── LoadGames → LibraryLoaded (games: [...]) OR LibraryEmpty

LibraryLoaded
  ├── Refresh → LibraryLoading
  ├── DeleteGame → LibraryLoading → LibraryLoaded/Empty
  ├── GameAdded (external event) → LibraryLoading → LibraryLoaded
  └── DatabaseError → LibraryError (message, retry callback)

LibraryEmpty
  ├── Refresh → LibraryLoading → LibraryLoaded/Empty
  └── AddGamePressed → (opens AddGameDialog)

LibraryError
  └── Retry → LibraryLoading
```

### GameCard Real Data Integration

The `GameCard` widget must be updated to accept real game data:

```dart
class GameCard extends StatelessWidget {
  final GameModel game;  // Changed from mock data
  final bool isFocused;
  final VoidCallback? onPressed;
  final VoidCallback? onContextAction;  // X button for delete
  
  // Displays:
  // - Title: game.title
  // - Cover: Placeholder gradient (Sprint 5 will add real images)
  // - Subtitle: Optional file path or added date
}
```

### Game Deletion Flow

1. User focuses a GameCard in the grid (D-pad navigation)
2. User presses X button (gamepad `contextAction`)
3. `DeleteGameDialog` appears with:
   - Title: "Delete Game?"
   - Message: "Are you sure you want to remove '[game.title]' from your library?"
   - Buttons: "Delete" (destructive, red), "Cancel" (neutral)
   - Both buttons are gamepad-focusable
4. User selects "Delete":
   - Game deleted from database
   - Dialog closes
   - Grid refreshes
   - Focus moves to adjacent card (or empty state if last game)
5. User selects "Cancel":
   - Dialog closes
   - Focus returns to the GameCard

### Rescan UI Flow

1. User clicks "Rescan" button in TopBar
2. AddGameDialog opens with "Scan Directory" tab active
3. Saved directories are pre-populated in the list
4. Scanning starts automatically
5. Progress indicator shows scan status
6. Only new executables (not already in library) appear in checkbox list
7. User checks desired games and confirms
8. New games added to library
9. Dialog closes, Library page refreshes

### Error State Specifications

**Database Error:**
- Display: Full-screen error widget or SnackBar
- Message: "Failed to load games. Please try again."
- Action: "Retry" button (gamepad-focusable)
- Location: Shown in GameLibraryPage when LibraryError state occurs

**Scan Error (Permission Denied):**
- Display: Error message within Scan Directory tab
- Message: "Cannot access [directory path]. Check permissions."
- Action: "Remove Directory" button to remove inaccessible directory from list
- Location: Shown in scan results area

**Duplicate Game:**
- Display: Silent skip (no UI shown)
- Behavior: When adding games, check executable_path against existing games. If duplicate found, skip that executable without adding.
- Log: Debug log entry: "Skipping duplicate: [executable_path]"

**Empty Scan Results:**
- Display: Empty state widget in scan results area
- Message: "No executables found in the selected directories."
- Sub-message: "Try selecting a different directory or check that .exe files exist."
- Action: "Select Different Directories" button

**File Picker Cancelled:**
- Display: No error shown
- Behavior: Return to form in previous state, no changes made

### Manage Directories Section

Located in the Scan Directory tab:

```dart
class ManageDirectoriesSection extends StatelessWidget {
  // Shows:
  // - Header: "Saved Directories"
  // - List of saved ScanDirectoryModel items
  // - Each item shows: directory path, last scanned date
  // - Each item has: delete button (X icon, gamepad-focusable)
  // - Delete button removes directory from database and list
}
```

## Out of Scope Reminders

The following are explicitly NOT part of Sprint 3:

- ❌ External API integration (RAWG/IGDB) — Sprint 5
- ❌ Metadata fetching or display — Sprint 5
- ❌ Cover/hero images — Sprint 5
- ❌ Game launching — Sprint 4
- ❌ Favorites functionality — Sprint 6
- ❌ Play count tracking — Sprint 6
- ❌ Home page Netflix-style rows — Sprint 4
- ❌ Game detail overlay/page — Sprint 4
- ❌ Settings page — Sprint 6
- ❌ i18n string extraction for new UI — Sprint 6 (use hardcoded strings for now)

## Handoff Checklist

Before submitting for evaluation, verify:

- [ ] All 5 database tables created with correct schema
- [ ] All data models have `.g.dart` files committed (except DiscoveredExecutableModel)
- [ ] Repository pattern correctly implemented (abstract in domain, concrete in data)
- [ ] Add Game dialog has two functional tabs
- [ ] Manual Add flow works end-to-end (file picker → form → save → appears in Library)
- [ ] Scan Directory flow works end-to-end (directory picker → scan → checkbox list → save)
- [ ] Manage Directories section allows removing saved directories
- [ ] Game Library page displays games in responsive grid (1-5 columns per breakpoints)
- [ ] GameCard updated to display real game data (title from database)
- [ ] Gamepad navigation works in grid and dialog
- [ ] X button triggers delete confirmation dialog on focused GameCard
- [ ] Rescan button opens dialog in Scan Directory tab with only new executables
- [ ] Duplicate executables are silently skipped
- [ ] Empty scan results show appropriate message
- [ ] Error states show user-friendly messages with retry where applicable
- [ ] Unit tests for repositories and scanner service
- [ ] No hardcoded mock data — all data comes from database
- [ ] Code follows Clean Architecture (no UI layer database access)

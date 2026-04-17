# Contract Review: Sprint 3

## Assessment: CHANGES_REQUESTED

The contract is comprehensive and well-structured, covering the majority of Sprint 3 deliverables from the spec. The database schema, data models, repository pattern, BLoC state machines, and UI component breakdown are all detailed and thoughtful. However, there are several gaps and ambiguities that need to be resolved before implementation begins. The most critical issues are: (1) the responsive grid breakpoints conflict with the spec, (2) the game deletion mechanism is undefined for gamepad input, (3) several edge cases in the scan/add flow are unspecified, and (4) the GameCard widget integration with real data is not addressed.

---

## Scope Coverage

### Fully Covered Deliverables

- ✅ **SQLite database setup** — All 5 tables from the spec schema are included with correct column definitions, foreign keys, and cascade deletes. Including `game_genres` and `game_screenshots` tables now (even though metadata fetching is Sprint 5) is good forward-planning.

- ✅ **JSON-serializable models** — All required models are listed with `.g.dart` generated files. `DiscoveredExecutableModel` correctly noted as runtime-only (no `.g.dart`).

- ✅ **Repository pattern** — Abstract interfaces in `domain/repositories/`, concrete implementations in `data/repositories/`. Clean Architecture compliance is explicit.

- ✅ **Add Game dialog two-tab layout** — Manual Add and Scan Directory tabs with gamepad tab switching. Complete rewrite of Sprint 2 placeholder is specified.

- ✅ **Manual Add flow** — File picker for .exe, formz-validated name input, save to database. Well-specified.

- ✅ **Scan Directory flow** — Directory picker, recursive scan with progress, cancelable operation, checkbox list with select all/none, save to database, persist directories. Thoroughly specified.

- ✅ **Rescan functionality** — Rescan button, comparison against existing games, present only new executables. Well-defined.

- ✅ **BLoC state machines** — Both `AddGameBloc` and `GameLibraryBloc` have clear state machine diagrams. The `AddGameBloc` state machine is particularly well-designed with clear transitions.

- ✅ **Form validation** — `formz` validators for game name and executable path. Good.

- ✅ **Dependency injection** — `di.dart` updates noted. Good.

- ✅ **Technical constraints** — Required dependencies, code generation rules, architecture rules, file scanning rules, and gamepad navigation requirements are all clearly specified.

### Partially Covered Deliverables

- ⚠️ **Game Library page** — The grid layout and gamepad navigation are specified, but the responsive breakpoints conflict with the spec (see Issue #1). The empty state is mentioned but not detailed (what does it look like? what's the CTA?).

- ⚠️ **Game deletion** — Listed as a deliverable but the mechanism is vague: "context menu or detail view." Since the detail view is Sprint 4's scope, only the context menu path is available, and context menus don't work well with gamepad input (see Issue #2).

- ⚠️ **GameCard integration** — The contract says the Library page uses "existing `GameCard` widgets" but doesn't specify that `GameCard` needs to be updated to accept real game data instead of Sprint 2's mock data (see Issue #5).

### Missing Deliverables

- ❌ **Unit test files** — The handoff checklist mentions "Unit tests for repositories and models" but no test files are listed in the deliverables table. Success criteria 3, 4, 6, and 7 reference unit tests, but there's no specification of what test files to create or minimum coverage requirements (see Issue #7).

- ❌ **Error state UI specifications** — The BLoC states include `Error` states, but there's no specification for what the user sees when errors occur (see Issue #3).

---

## Success Criteria Review

### Well-Specified Criteria

- **Criteria 1-4 (Database & Models)**: Clear, testable, with specific verification methods. ✅
- **Criteria 9-13 (Manual Add Flow)**: Good end-to-end flow with specific verification steps. ✅
- **Criteria 14-23 (Scan Directory Flow)**: Thorough coverage of the scan workflow. ✅
- **Criteria 32-36 (Gamepad/Keyboard Support)**: Specific and testable. ✅

### Criteria Needing Revision

- **Criterion 8** ("Repository methods return proper entities (not models)"): Verification method is "Code review" — this should also include a functional test (e.g., calling a repository method and verifying the returned type is an Entity, not a Model). Code review alone is insufficient.

- **Criterion 24** ("Library page shows responsive grid of GameCards"): Says "grid adapts to window size (2-5 columns)" but the spec says 1-5 columns (1 column at compact, 2 at medium, 3 at expanded, 4-5 at large). The contract's breakpoints are off (see Issue #1).

- **Criterion 27** ("Empty state shown when no games in library"): Says 'see "No games" message with Add Game CTA' but doesn't specify what the CTA does (opens Add Game dialog? navigates to a page?). Should be explicit.

- **Criterion 28** ("Game deletion removes game from database and grid"): Doesn't specify how deletion is triggered via gamepad. "Context menu or detail view" is vague for a gamepad-first app (see Issue #2).

- **Criterion 30** ("Rescan only shows new executables"): The test scenario is good ("Add directory, scan, add all. Add new .exe to directory, rescan, only new one shown") but doesn't specify what happens if the user deletes a game that was previously added from a scan directory and then rescans — does the deleted game's executable show up again? This edge case should be addressed.

---

## Issues and Suggested Changes

### Issue #1: Responsive Grid Breakpoints Conflict with Spec (Severity: Major)

**Problem**: The contract specifies these breakpoints:
| < 640px | 2 columns |
| 640–1024px | 3 columns |
| 1024–1440px | 4 columns |
| > 1440px | 5 columns |

But the spec specifies:
| < 640px (Compact) | Single column |
| 640–1024px (Medium) | 2-column grid |
| 1024–1440px (Expanded) | 3-column grid |
| > 1440px (Large) | 4-5 column grid |

The contract adds an extra column at every breakpoint. While a Library grid page can reasonably show more columns than the home page's horizontal rows, the card sizes should still match the spec at each breakpoint, and the compact breakpoint should probably be 1-2 columns (not 2) since 2 columns of 140×210 cards on a < 640px screen would be very cramped.

**Suggested Fix**: Align the breakpoints with the spec for the Library page:
| < 640px | 2 columns, 140×210 cards |
| 640–1024px | 3 columns, 170×255 cards |
| 1024–1440px | 4 columns, 200×300 cards |
| > 1440px | 5 columns, 240×360 cards |

OR justify the deviation by noting that the Library grid page intentionally shows more columns than the home page rows. Either way, the contract should explicitly acknowledge the spec's breakpoints and explain any deviation.

### Issue #2: Game Deletion Mechanism Undefined for Gamepad (Severity: Major)

**Problem**: The contract says "Delete game from library (context menu or detail view)" but:
1. Context menus (right-click) don't work with gamepad input — this is a gamepad-first app.
2. The detail view is Sprint 4's scope, so it won't exist yet.
3. No alternative gamepad-compatible deletion mechanism is specified (e.g., X button on focused card, long-press, or a delete button in a card action bar).

**Suggested Fix**: Specify a gamepad-compatible deletion mechanism. Options:
- **Option A**: Press X button on a focused GameCard to trigger deletion (matches the gamepad mapping in the spec: X = "Context action (details)"). A confirmation dialog appears.
- **Option B**: Long-press Enter on a GameCard to open an action menu with "Delete" option.
- **Option C**: Add a small delete icon/button that appears on the focused card.

I recommend **Option A** (X button) since it aligns with the spec's gamepad mapping and is the most gamepad-friendly. The contract should specify:
- How deletion is triggered (gamepad X button or keyboard equivalent)
- The confirmation dialog UI (which is already listed as `delete_game_dialog.dart`)
- What happens after deletion (grid refreshes, focus moves to adjacent card)

### Issue #3: Missing Error Handling Specifications (Severity: Major)

**Problem**: The contract's BLoC states include `Error` states (`AddGameState.Error`, `GameLibraryState.Error`) but there's no specification for:
1. What the user sees when a database operation fails (e.g., can't open database, write fails)
2. What the user sees when a file scan fails (e.g., permission denied on a directory)
3. What the user sees when the file picker is cancelled or returns no file
4. What happens when adding a duplicate game (executable_path is UNIQUE in the schema)
5. What happens when a scan finds 0 executables

**Suggested Fix**: Add error state specifications:
- Database errors: Show a SnackBar or dialog with error message and retry option
- Scan permission errors: Show error in scan results area, allow user to remove the inaccessible directory
- File picker cancelled: Return to the form without error (user just chose not to select a file)
- Duplicate game: Show a user-friendly message like "This game is already in your library" and don't add it again
- Empty scan results: Show a message like "No executables found in the selected directories" with an option to try different directories

### Issue #4: Missing Scan Directory Removal (Severity: Minor)

**Problem**: The contract specifies adding and persisting scan directories, and the `ScanDirectoryRepository` has "add, list, and delete" operations. However, the UI flow for removing a scan directory is not specified. Can the user remove a directory from their saved list? If so, how?

**Suggested Fix**: Add a UI element in the Scan Directory tab for managing saved directories (e.g., a list of saved directories with a remove button next to each). This doesn't need to be elaborate — a simple list with X buttons is sufficient. If this is deferred to a later sprint, state it explicitly in "Out of Scope."

### Issue #5: GameCard Widget Needs Real Data Integration (Severity: Major)

**Problem**: The contract says the Library page uses "existing `GameCard` widgets" from Sprint 2, but Sprint 2's `GameCard` uses mock data (hardcoded title, color, description from `MockGames`). The contract doesn't specify how `GameCard` will be updated to accept real `Game` entity data (title from database, executable path, placeholder cover image).

**Suggested Fix**: Add `GameCard` to the list of modified files with a note that it will be updated to accept a `Game` entity parameter instead of mock data. Specify what data the card displays:
- Title: `game.title`
- Cover image: Placeholder gradient (same as Sprint 2) since metadata fetching is Sprint 5
- Subtitle: File path or "Added [date]" (optional)
- The card's `onPressed` callback should be updated to work with real game data

### Issue #6: Rescan UI Flow Unclear (Severity: Minor)

**Problem**: Criterion 29 says "Rescan button in top bar triggers rescan of all saved directories" and the rescan section says "Present only new executables in checkbox list for confirmation." But it's unclear whether:
1. The rescan opens the Add Game dialog in scan mode, or
2. The rescan shows a separate dialog/overlay, or
3. The rescan happens inline on the Library page

**Suggested Fix**: Specify the rescan UI flow explicitly. I recommend: clicking Rescan opens the Add Game dialog in Scan Directory tab, pre-populated with saved directories, and automatically starts scanning. New executables are shown in the checkbox list for confirmation. This reuses existing UI rather than creating a new flow.

### Issue #7: Unit Test Deliverables Not Specified (Severity: Minor)

**Problem**: The handoff checklist includes "Unit tests for repositories and models" and success criteria 3, 4, 6, and 7 reference unit tests, but no test files are listed in the deliverables table. There's no specification of test file locations, minimum coverage, or which operations must be tested.

**Suggested Fix**: Add a test deliverables section:
| File | Purpose |
|------|---------|
| `test/data/models/game_model_test.dart` | GameModel serialization tests |
| `test/data/models/game_metadata_model_test.dart` | GameMetadataModel serialization tests |
| `test/data/models/scan_directory_model_test.dart` | ScanDirectoryModel serialization tests |
| `test/data/repositories/game_repository_impl_test.dart` | GameRepository CRUD tests |
| `test/data/repositories/scan_directory_repository_impl_test.dart` | ScanDirectoryRepository tests |
| `test/data/services/file_scanner_service_test.dart` | File scanner service tests |

Minimum: All repository CRUD operations must have tests. All model fromJson/toJson roundtrips must be tested. Foreign key cascade deletes must be tested.

### Issue #8: Date Storage Format Not Explicit (Severity: Minor)

**Problem**: The database schema uses `INTEGER` for all date fields (`added_date`, `last_played_date`, `last_scanned_date`, `last_fetched`), implying Unix timestamps (milliseconds since epoch). The domain entities use `DateTime`. The contract should explicitly state the conversion strategy.

**Suggested Fix**: Add a note to the implementation notes: "All date fields are stored as INTEGER (Unix timestamp in milliseconds). Repository implementations must convert between DateTime and int using `dateTime.millisecondsSinceEpoch` and `DateTime.fromMillisecondsSinceEpoch()`."

### Issue #9: Missing Specification for Game ID Generation (Severity: Minor)

**Problem**: The `uuid` package is listed as a dependency and the `games` table has `id TEXT PRIMARY KEY`, but the contract doesn't explicitly state that UUIDs will be used for game IDs or which UUID version.

**Suggested Fix**: Add a note: "All entity IDs are generated using `uuid` package (v4 UUIDs). The `id` field is set at creation time and never changes."

### Issue #10: DiscoveredExecutableModel Missing from Deliverables Table (Severity: Minor)

**Problem**: `DiscoveredExecutableModel` is listed in the Data Models section but not in the Detailed Deliverables table (section 2). It's only mentioned in the File Scanner Service Design section. It should be in the deliverables table for completeness.

**Suggested Fix**: Add `lib/data/models/discovered_executable_model.dart` to the Data Models deliverables table.

---

## Test Plan Preview

When evaluating Sprint 3, I plan to test:

1. **Database initialization**: Verify all 5 tables are created with correct schema on app startup
2. **Manual Add flow end-to-end**: Select .exe file → enter name → save → verify game appears in Library
3. **Scan Directory flow end-to-end**: Select directory → scan → see progress → checkbox list → confirm → games appear in Library
4. **Scan cancellation**: Start scan → cancel → verify UI returns to ready state
5. **Rescan flow**: Add directory → scan → add all games → add new .exe to directory → rescan → only new .exe shown
6. **Game deletion**: Delete game → confirm → verify game removed from grid and database
7. **Duplicate game handling**: Try to add same .exe twice → verify error message
8. **Empty scan results**: Scan directory with no .exe files → verify empty state message
9. **Gamepad navigation in dialog**: Tab switching, checkbox navigation, focus trapping
10. **Gamepad navigation in grid**: D-pad movement between cards, focus animations
11. **Responsive grid**: Resize window and verify column count changes
12. **Data persistence**: Add games → restart app → verify games still in Library
13. **Database cascade deletes**: Delete a game → verify metadata is also deleted

---

## Summary

The contract is strong in its technical specification — the database schema, BLoC state machines, file scanner service design, and architecture rules are all well-defined. The main issues are around **edge cases and UI flow details** that would cause ambiguity during implementation and evaluation:

1. **Grid breakpoints** need to align with or explicitly deviate from the spec
2. **Game deletion** needs a gamepad-compatible mechanism
3. **Error states** need UI specifications
4. **GameCard** needs to be listed as a modified file with real data integration
5. **Unit test files** need to be in the deliverables

These are all addressable without reducing scope. I recommend the Generator revise the contract to address Issues #1-5 (major) and incorporate #6-10 (minor) before proceeding.
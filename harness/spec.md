# Product Specification: Legacy Focus System Cleanup (Sprint 4)

## Background

Sprint 3 successfully migrated the app's focus system from a fully custom implementation to Flutter's native `FocusScope` architecture. However, several components still carry remnants of the old system — specifically the explicit `enterDialogMode()` / `exitDialogMode()` calls on `FocusTraversalService` that are now redundant because Flutter's `showDialog()` already creates a `FocusScope` that traps focus automatically.

Additionally, the Settings button in the bottom nav bar and the custom file browser need focus-related polish to work correctly with the new architecture.

## Problem Statement

1. **Legacy dialog mode calls**: All dialogs (`AddGameDialog`, `DeleteGameDialog`, `ApiKeyDialog`, `MetadataSearchDialog`, `GamepadFileBrowser`) still call `FocusTraversalService.instance.enterDialogMode()` and `exitDialogMode()`. These are no longer needed because:
   - `showDialog()` automatically wraps content in a `FocusScope`
   - The dialog's own `KeyboardListener` handles arrow keys and Escape
   - The redundant dialog mode tracking creates confusion and potential bugs

2. **FocusTraversalService bloat**: The service still maintains `_isInDialogMode`, `_dialogTriggerNode`, `_dialogCancelCallback`, and related methods that serve no purpose in the FocusScope architecture.

3. **Settings button cross-scope navigation**: The `_SettingsNavButton` in `GamepadNavBar` uses `FocusableButton` but cross-scope navigation from Content → BottomNav and back may not be fully handled.

4. **File browser focus polish**: `GamepadFileBrowser` has a `FocusScope` but also uses dialog mode, and its keyboard navigation could be improved.

5. **AddGameDialog consolidation**: Verify there is only one `AddGameDialog` implementation (there is — no consolidation needed).

## Goals

1. Remove all `enterDialogMode()` / `exitDialogMode()` calls from dialogs and file browser
2. Simplify `FocusTraversalService` by removing dialog mode state and methods
3. Update `FocusTraversalService` to detect dialog presence via focus tree inspection instead of explicit mode tracking
4. Ensure Settings button works with cross-scope navigation
5. Ensure GamepadFileBrowser focus works correctly without dialog mode
6. All 370 existing tests must continue to pass

## Architecture

### Current Focus Architecture (Post-Sprint 3)

```
App (Scaffold)
├── FocusScope (TopBarScope)     ← _ShellWithFocusScope
│   └── TopBar
├── Expanded
│   └── AppShell
│       └── FocusScope (ContentScope)
│           └── Page Content (HomePage, LibraryPage, SettingsPage)
└── GamepadNavBar
    └── _SettingsNavButton (FocusableButton)
```

Dialogs open via `showDialog()` which creates:
```
Overlay
└── ModalRoute
    └── FocusScope (automatic, traps focus)
        └── Dialog content
```

### FocusTraversalService Responsibilities (After Cleanup)

1. **Cross-scope wrapping**: TopBar ↔ Content
2. **Row/grid navigation**: `registerRow()` / `registerGrid()` for GameCardRow and GameGrid
3. **Sound effects**: playFocusMove() on focus changes
4. **Keyboard/gamepad event routing**: Global handler that delegates to `focusInDirection()`
5. **Focus history**: Track recently focused nodes for recovery
6. **Activation**: `activateCurrentNode()` using `Actions.invoke()`

**Removed responsibilities:**
- Dialog mode tracking (no longer needed)
- Dialog trigger node restoration (handled by `showDialog` / `FocusScope`)
- Dialog cancel callback (handled by dialog's own `KeyboardListener`)

## Sprint Breakdown

### Sprint 1: Core Cleanup — Remove Legacy Dialog Mode

Remove all legacy dialog mode usage from FocusTraversalService and all dialogs/file browser.

**Success Criteria:**
- SC1: No file contains `enterDialogMode` or `exitDialogMode` calls
- SC2: `FocusTraversalService` does not have `_isInDialogMode`, `_dialogTriggerNode`, `_dialogCancelCallback` fields
- SC3: `FocusTraversalService` uses focus tree inspection to detect dialogs
- SC4: Dialogs still trap focus correctly (arrow keys stay within dialog)
- SC5: Escape key closes dialogs
- SC6: All 370 tests pass, no analyzer warnings

### Sprint 2: Polish — Settings Button & File Browser

Ensure Settings button and file browser work correctly with the cleaned-up focus system.

**Success Criteria:**
- SC1: Settings button in GamepadNavBar can be focused via keyboard/gamepad
- SC2: Cross-scope navigation works: Content → BottomNav → Content
- SC3: GamepadFileBrowser keyboard navigation works without dialog mode
- SC4: All 370 tests pass, no analyzer warnings

## Files to Modify

### Sprint 1

| File | Changes |
|------|---------|
| `lib/presentation/navigation/focus_traversal.dart` | Remove dialog mode state/methods; add focus-tree-based dialog detection |
| `lib/presentation/widgets/add_game_dialog.dart` | Remove `enterDialogMode`/`exitDialogMode` calls |
| `lib/presentation/widgets/delete_game_dialog.dart` | Remove `enterDialogMode`/`exitDialogMode` calls |
| `lib/presentation/widgets/api_key_dialog.dart` | Remove `enterDialogMode`/`exitDialogMode` calls |
| `lib/presentation/widgets/metadata_search_dialog.dart` | Remove `enterDialogMode`/`exitDialogMode` calls |
| `lib/presentation/widgets/gamepad_file_browser.dart` | Remove `enterDialogMode`/`exitDialogMode` calls |

### Sprint 2

| File | Changes |
|------|---------|
| `lib/presentation/widgets/gamepad_nav_bar.dart` | Ensure Settings button participates in focus traversal, possibly add FocusScope wrapper |
| `lib/presentation/navigation/focus_traversal.dart` | Add Content ↔ BottomNav wrapping logic |
| `lib/presentation/widgets/gamepad_file_browser.dart` | Focus polish (ensure proper focus trapping) |

## Testing Requirements

- All 370 existing tests must pass (`flutter test`)
- No new test files needed (this is a refactoring)
- Run `flutter analyze` — no new warnings

## Non-Goals

- Rewriting the entire focus system (already done in Sprint 3)
- Adding new UI features
- Changing the behavior of row/grid navigation (works correctly)
- Modifying FocusableButton/FocusableListTile/etc. widgets

# Self-Evaluation: Sprint 2

## What Was Built

This sprint polished the focus system after Sprint 1's legacy dialog mode cleanup:

1. **BottomNav FocusScope** (`router.dart`):
   - Added `_bottomNavScopeNode = FocusScopeNode(debugLabel: 'BottomNavScope')` to `_ShellWithFocusScopeState`.
   - Registered it with `FocusTraversalService.instance.setBottomNavContainer()` in `initState()`.
   - Wrapped `GamepadNavBar` in `FocusScope(node: _bottomNavScopeNode)` inside the shell Column.
   - Added proper disposal of `_bottomNavScopeNode`.

2. **FocusTraversalService cross-scope wrapping** (`focus_traversal.dart`):
   - Added `_bottomNavFocusNode` field.
   - Added `setBottomNavContainer(FocusScopeNode node)` setter.
   - Added `wrapToBottomNav()` method that focuses the most recently focused bottom-nav descendant (or first descendant as fallback).
   - Updated `moveFocus()`:
     - `direction == down` from Content scope → `wrapToBottomNav()`
     - `direction == up` from BottomNav scope → `wrapToContent()`
   - Updated `_isFocusInsideDialog()` to exclude `_bottomNavFocusNode` from dialog detection.
   - Updated `_isOnNonInteractiveScope()` to exclude `_bottomNavFocusNode`.
   - Updated `_recoverFocusFromScope()` to try BottomNav scope as final fallback.
   - Updated `_focusFirstAvailableNode()` to try BottomNav scope as final fallback.
   - Removed stale "Dialog mode tracking" reference from class-level doc comment.

3. **GamepadFileBrowser focus polish** (`gamepad_file_browser.dart`):
   - Set `canRequestFocus: false` on `_keyboardFocusNode` so the `KeyboardListener` does not steal autofocus when the dialog opens.
   - The dialog's internal `FocusScope` (in `AlertDialog.content`) continues to trap focus correctly.
   - `_loadDirectory()` still focuses the first item via post-frame callback.

4. **Stale documentation cleanup** (`gamepad_hint_provider.dart`):
   - Updated class doc from "FocusTraversalService dialog mode" to "FocusTraversalService dialog detection via `isDialogOpen`".

## Success Criteria Check

- [x] **SC1: Settings button is inside a registered FocusScope** — Verified in `router.dart` (line 300-302) and `focus_traversal.dart` (line 48, `setBottomNavContainer` at line 193-195).
- [x] **SC2: Cross-scope navigation Content → BottomNav** — Verified in `focus_traversal.dart` `moveFocus()` (line 596-599): when `direction == down` and current node is in content scope, calls `wrapToBottomNav()`.
- [x] **SC3: Cross-scope navigation BottomNav → Content** — Verified in `focus_traversal.dart` `moveFocus()` (line 601-604): when `direction == up` and current node is in bottom nav scope, calls `wrapToContent()`.
- [x] **SC4: GamepadFileBrowser keyboard navigation works without dialog mode** — `canRequestFocus: false` prevents keyboard listener from stealing focus. Dialog `FocusScope` traps focus. List item `Focus` widgets handle arrow up/down/left/enter. Escape closes dialog. First item is focused on open via post-frame callback.
- [x] **SC5: Stale documentation cleaned up** — `FocusTraversalService` class doc no longer mentions "Dialog mode tracking". `GamepadHintProvider` class doc no longer mentions "dialog mode".
- [x] **SC6: All 370 tests pass, no new analyzer warnings** — `flutter test` reports `All tests passed!` (370 tests). `flutter analyze` reports only the same 4 pre-existing issues from Sprint 1 (none introduced by Sprint 2 changes).

## Known Issues

None. All contract criteria are met.

## Decisions Made

- Wrapped the entire `GamepadNavBar` in `FocusScope` in `router.dart` rather than modifying `gamepad_nav_bar.dart`. This is correct because `GamepadNavBar` already wraps its hints in `ExcludeFocus`, so only `_SettingsNavButton` is focusable within the BottomNav scope.
- `wrapToBottomNav()` mirrors `wrapToTopBar()` implementation: it tries focus history first, then falls back to the first traversal descendant. This keeps behavior consistent across all three scopes.
- `_recoverFocusFromScope()` now tries content → top bar → bottom nav in that order, which is a sensible fallback priority.

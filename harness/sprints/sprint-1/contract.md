# Sprint 1 Contract: Core Cleanup — Remove Legacy Dialog Mode

## Overview
Remove all legacy `enterDialogMode()` / `exitDialogMode()` calls from dialogs and `FocusTraversalService`, eliminate the now-redundant dialog mode state fields, and replace dialog detection with focus-tree inspection so Flutter's native `showDialog()` `FocusScope` handles trapping automatically.

## Success Criteria

### SC1: No `enterDialogMode` or `exitDialogMode` calls remain in the codebase
- A grep for `enterDialogMode` or `exitDialogMode` anywhere under `lib/` returns zero matches.
- The methods `enterDialogMode()` and `exitDialogMode()` are removed from `FocusTraversalService`.

### SC2: `FocusTraversalService` no longer contains dialog mode state fields
- The following fields are deleted from `FocusTraversalService`:
  - `bool _isInDialogMode`
  - `FocusNode? _dialogTriggerNode`
  - `VoidCallback? _dialogCancelCallback`
- The method `bool isInDialogMode()` is deleted.

### SC3: `FocusTraversalService` uses focus-tree inspection to detect dialogs
- A new helper method (e.g., `bool _isFocusInsideDialog()`) is added that inspects the focus tree (e.g., by walking up ancestors of `WidgetsBinding.instance.focusManager.primaryFocus` and checking for `ModalScope` or `FocusScope` nodes created by `showDialog`).
- `_handleKeyEvent` no longer references `_isInDialogMode`; instead, if a dialog is detected via focus-tree inspection, arrow keys and Escape are allowed to pass through to the dialog's own `KeyboardListener`.
- `_handleCancel` no longer references `_isInDialogMode`; if focus is inside a dialog, the method returns early (letting the dialog handle its own close logic).
- `_addToHistory` no longer skips history when `_isInDialogMode`; instead, it skips nodes that are inside a dialog scope (detected via focus-tree inspection).
- `moveFocus` no longer has a special `_isInDialogMode` branch; it lets Flutter's built-in `FocusScope` handle dialog trapping.

### SC4: Dialogs still trap focus correctly
- Each dialog already wraps its content in either `FocusScope` or `KeyboardListener`; this must remain unchanged.
- Arrow-key navigation within each dialog must continue to work via the dialog's own `KeyboardListener` (not via `FocusTraversalService`).

### SC5: Escape key closes dialogs
- `AddGameDialog`, `DeleteGameDialog`, `ApiKeyDialog`, `MetadataSearchDialog`, and `GamepadFileBrowser` each have their own `KeyboardListener` that handles `LogicalKeyboardKey.escape` to close the dialog. These listeners must remain functional after removing `enterDialogMode`/`exitDialogMode`.
- The `showDialog` barrier and dialog close animations continue to work as before.

### SC6: Focus restoration on dialog close remains intact
- Each dialog's `show()` static method (or equivalent) already captures `FocusManager.instance.primaryFocus` before opening and restores it after close. This behavior must be preserved.

### SC7: `gamepad_hint_provider.dart` updated to use focus-tree inspection
- `gamepad_hint_provider.dart` currently calls `FocusTraversalService.instance.isInDialogMode()`. It must be updated to use a new public helper on `FocusTraversalService` (or equivalent focus-tree check) to determine whether the current focus is inside a dialog.

### SC8: All 370 existing tests pass and analyzer is clean
- `flutter test` exits with 0 failures.
- `flutter analyze` produces no new warnings or errors.

## Files to Modify

| File | Expected Changes |
|------|-----------------|
| `lib/presentation/navigation/focus_traversal.dart` | Remove `_isInDialogMode`, `_dialogTriggerNode`, `_dialogCancelCallback`, `isInDialogMode()`, `enterDialogMode()`, `exitDialogMode()`. Remove all `_isInDialogMode` references in `_handleKeyEvent`, `_handleCancel`, `_addToHistory`, `moveFocus`. Add `_isFocusInsideDialog()` helper using ancestor walk (e.g., checking for `ModalScope` in `debugLabel`). Update `_handleKeyEvent`, `_handleCancel`, `_addToHistory`, `moveFocus` to use the new helper. |
| `lib/presentation/widgets/add_game_dialog.dart` | Remove `enterDialogMode` call from `initState`. Remove `exitDialogMode` call from `_closeDialog`. Remove `_triggerNode` field (no longer needed). Keep focus restoration in `show()` and `KeyboardListener` escape handling. |
| `lib/presentation/widgets/delete_game_dialog.dart` | Remove `enterDialogMode` call from `initState`. Remove `exitDialogMode` calls from `_confirmDelete` and `_cancel`. Remove `_triggerNode` field. Keep focus restoration in `show()` and `KeyboardListener` escape handling. |
| `lib/presentation/widgets/api_key_dialog.dart` | Remove `enterDialogMode` call from `initState`. Remove `exitDialogMode` calls from `_save`, `_skip`, and `dispose`. Remove `_triggerNode` field. Keep focus restoration in `show()` and `KeyboardListener` escape handling. |
| `lib/presentation/widgets/metadata_search_dialog.dart` | Remove `_enterDialogMode()` method and its call from `initState`. Remove `exitDialogMode` calls from `_confirmSelection`, `_cancel`, and `dispose`. Remove `_triggerNode` field. Keep `KeyboardListener` escape handling. |
| `lib/presentation/widgets/gamepad_file_browser.dart` | Remove `isInDialogMode()` check and `exitDialogMode()` call from `dispose`. Remove `enterDialogMode` call from `_loadDirectory`. Remove `_triggerNode` field. Keep `FocusScope` wrapper and `KeyboardListener` escape handling. |
| `lib/presentation/navigation/gamepad_hint_provider.dart` | Replace `FocusTraversalService.instance.isInDialogMode()` with a focus-tree-based check (either via a new public `bool isDialogOpen` getter on `FocusTraversalService` or an inline equivalent). |

## Files to Delete
None.

## Implementation Notes

### Focus-tree-based dialog detection pattern
Flutter's `showDialog` creates a `ModalRoute` which introduces a `FocusScope` whose `debugLabel` contains `"ModalScope"` or `"Focus Scope"`. The helper should walk up from `WidgetsBinding.instance.focusManager.primaryFocus` and return `true` if any ancestor is a `FocusScopeNode` that is NOT `_topBarFocusNode` or `_contentFocusNode` and has a label suggesting it's a modal/dialog scope. A recommended signature:

```dart
bool _isFocusInsideDialog() {
  final node = WidgetsBinding.instance.focusManager.primaryFocus;
  if (node == null) return false;
  var current = node.parent;
  while (current != null) {
    if (current is FocusScopeNode &&
        current != _topBarFocusNode &&
        current != _contentFocusNode) {
      final label = current.debugLabel ?? '';
      if (label.contains('ModalScope') || label.contains('Dialog')) {
        return true;
      }
    }
    current = current.parent;
  }
  return false;
}
```

This is a refinement of the existing `_isOnNonInteractiveScope` pattern already present in `FocusTraversalService`.

### What to keep
- **Do NOT** remove `FocusScope` wrappers from dialog content.
- **Do NOT** remove `KeyboardListener` escape handlers from dialogs.
- **Do NOT** remove focus-restoration logic in `show()` methods.
- **Do NOT** modify row/grid navigation, cross-scope wrapping (`wrapToTopBar`/`wrapToContent`), activation callbacks, or focus history beyond replacing the `_isInDialogMode` guard.

### What to remove
- `_triggerNode` fields in dialogs are safe to remove because `showDialog` already restores focus when the dialog closes (each dialog's `show()` captures and restores the trigger node explicitly).
- In `ApiKeyDialog`, the `exitDialogMode()` call in `dispose()` is safe to remove because the dialog's `show()` method restores focus after the dialog is popped.
- In `GamepadFileBrowser`, the `exitDialogMode()` call in `dispose()` and the `enterDialogMode()` call in `_loadDirectory()` are safe to remove because `showDialog` handles focus scope automatically.

## Testing Instructions
1. Run `flutter analyze` — verify no warnings or errors.
2. Run `flutter test` — verify all 370 tests pass.
3. Manual verification (if evaluator has UI access):
   - Open each dialog (`AddGameDialog`, `DeleteGameDialog`, `ApiKeyDialog`, `MetadataSearchDialog`, `GamepadFileBrowser`) using the app.
   - Confirm arrow keys navigate within the dialog only (focus does not escape to the page behind).
   - Confirm Escape / B button closes the dialog.
   - Confirm focus returns to the element that opened the dialog.
4. Run `grep -rn "enterDialogMode\|exitDialogMode" lib/` — verify zero matches.

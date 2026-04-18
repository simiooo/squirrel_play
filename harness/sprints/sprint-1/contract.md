# Sprint 1 Contract: Fix GamepadFileBrowser A-Key and B-Key Actions

## Deliverables
1. Fix A-button/Enter activation on file/directory items inside `GamepadFileBrowser`.
2. Fix B-button cancellation inside `GamepadFileBrowser` so the dialog closes from any focused element.
3. Ensure no `ActivateIntent not handled` exceptions appear in logs during file browser usage.
4. Preserve all existing focus traversal behavior (arrow keys, D-pad, cross-scope wrapping).
5. All 370 existing tests continue to pass (`flutter test`).

## Success Criteria
1. **A-Key Activation Works**: Pressing gamepad A (or Enter) on a focused file item in `GamepadFileBrowser` (file mode) selects the file, invokes `onSelected`, and closes the dialog.
2. **A-Key Opens Directories**: Pressing gamepad A (or Enter) on a focused directory item opens that directory.
3. **B-Key Cancels Dialog**: Pressing gamepad B inside `GamepadFileBrowser` closes the dialog regardless of which element (file item, Select button, or Cancel button) currently has focus.
4. **No Exceptions**: No `ActivateIntent not handled` or similar exceptions in debug logs during normal file browser usage.
5. **Keyboard Navigation Preserved**: Existing keyboard arrow navigation (Up/Down for item traversal, Left for parent directory) continues to work.
6. **Test Suite Passes**: `flutter test` exits with zero failures.

## Files to Modify
- `lib/presentation/widgets/gamepad_file_browser.dart` — Reorder `Actions` and `Focus` widget hierarchy per item; add `gameButtonB` handling to `KeyboardListener` or rely on `FocusTraversalService`.
- `lib/presentation/navigation/focus_traversal.dart` — Modify `_handleCancel()` so it actively pops the dialog when focus is inside a dialog scope instead of returning early silently.

## Technical Approach

### A-Key Fix: Actions Must Wrap Focus (Not the Other Way Around)
**Root cause**: In `_buildContent()` inside `gamepad_file_browser.dart`, each file/directory item is built as:
```dart
Focus(
  focusNode: _itemFocusNodes[index],
  child: Actions(
    actions: { ActivateIntent: CallbackAction(...) },
    child: GestureDetector(...),
  ),
)
```
`FocusTraversalService.activateCurrentNode()` calls `Actions.invoke(context, const ActivateIntent())` using the **focused node's context** (the `Focus` widget). `Actions.invoke` walks **up** the tree from the given context. Because `Actions` is a *descendant* of `Focus`, the lookup never finds the `ActivateIntent` mapping, causing the exception.

**Fix**: Swap the widget order so `Actions` is an **ancestor** of `Focus`:
```dart
Actions(
  actions: <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(...),
  },
  child: Focus(
    focusNode: _itemFocusNodes[index],
    onKeyEvent: ...,
    child: GestureDetector(...),
  ),
)
```
This way, when `Actions.invoke` walks up from the `Focus` widget's context, it encounters the `Actions` widget and resolves the intent successfully. The `onKeyEvent` handler inside `Focus` already handles `LogicalKeyboardKey.enter`, `select`, and `gameButtonA` manually, but the `Actions` wrapper ensures that `FocusTraversalService.activateCurrentNode()` (which uses `Actions.invoke`) also works.

### B-Key Fix: `_handleCancel()` Must Pop Dialogs
**Root cause**: In `focus_traversal.dart`, `_handleCancel()` currently does:
```dart
void _handleCancel() {
  if (_isFocusInsideDialog()) {
    return; // Silently does nothing
  }
  // ... router pop logic
}
```
`GamepadFileBrowser` has its own `KeyboardListener` that handles `LogicalKeyboardKey.escape`, but it does **not** handle the gamepad B button (`GamepadAction.cancel`). When B is pressed, `FocusTraversalService` receives the cancel action, detects the dialog scope, and returns early — leaving the dialog open.

**Fix**: Change `_handleCancel()` so that when focus is inside a dialog, it looks up the `BuildContext` from the currently focused node and calls `Navigator.of(context).pop()` to close the dialog:
```dart
void _handleCancel() {
  if (_isFocusInsideDialog()) {
    final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
    if (context != null && context.mounted) {
      SoundService.instance.playFocusBack();
      Navigator.of(context).pop();
    }
    return;
  }
  // ... existing router pop logic
}
```
This change is minimal and preserves the existing behavior for non-dialog contexts. The dialog's own `KeyboardListener` continues to handle Escape independently, while the service now also handles gamepad B for dialogs.

### Alternative / Complementary: Add B-Key to Dialog's KeyboardListener
As a defensive measure, also add `LogicalKeyboardKey.gameButtonB` (and any platform-specific B-button mapping) to the `_handleKeyEvent` inside `GamepadFileBrowser` so the dialog can close itself directly via its `KeyboardListener`. However, the primary fix is in `FocusTraversalService._handleCancel()` because that is the canonical path for gamepad B actions across the app.

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Swapping `Actions`/`Focus` order breaks existing `onKeyEvent` handling. | The `onKeyEvent` callback lives on `Focus`, which remains functionally identical after the reorder. The `Actions` widget only adds intent handling and does not intercept key events. Verify arrow-key navigation still works after the change. |
| `_handleCancel()` popping dialogs could accidentally close other dialogs (e.g., Add Game dialog) when B is pressed. | `_isFocusInsideDialog()` correctly identifies `GamepadFileBrowser` because its `FocusScope` is inside an `AlertDialog`. Popping via `Navigator.of(context).pop()` from the focused node's context is safe and standard Flutter behavior. The Add Game dialog is a separate route and not affected. |
| `Actions.invoke` still throws after reorder due to other context issues. | Add a `try/catch` around `Actions.invoke` in `activateCurrentNode()` (already present) and log clearly. The reorder fixes the structural cause; the catch is a safety net. |
| Test regressions from changed focus hierarchy. | Run `flutter test` after each file change. No tests should fail because the widget reorder is semantically equivalent for all non-activation paths. |
| Gamepad B button maps to a different `LogicalKeyboardKey` on Linux. | `FocusTraversalService` listens to `GamepadService` which abstracts platform specifics. The fix operates at the `GamepadAction.cancel` level, not raw keyboard keys, so platform mappings are already handled. |

## Out of Scope for This Sprint
- PickerButton focus traversal (Sprint 2).
- i18n string extraction (Sprint 3).
- Refactoring the broader `FocusTraversalService` API beyond `_handleCancel()`.
- Adding new tests (existing 370 tests must pass; new tests are optional).

# Contract Review: Sprint 1

## Assessment: APPROVED

## Scope Coverage

The contract is tightly aligned with the Sprint 1 scope defined in the spec. It correctly limits itself to:
- Fixing A-key/Enter activation on file/directory items inside `GamepadFileBrowser`
- Fixing B-key cancellation inside `GamepadFileBrowser`
- Preserving existing focus traversal behavior
- Ensuring the test suite continues to pass

The contract does not overstep into Sprint 2 (PickerButton traversal) or Sprint 3 (i18n extraction), and explicitly lists these as out of scope.

## Strengths

1. **Accurate root cause analysis for A-key**: The contract correctly identifies that `Actions` is a *descendant* of `Focus` in `gamepad_file_browser.dart` (lines 525–639), which causes `Actions.invoke(context, const ActivateIntent())` — walking **up** from the `Focus` widget's context — to miss the `ActivateIntent` mapping entirely. Swapping the order so `Actions` is an ancestor is the correct structural fix.

2. **Accurate root cause analysis for B-key**: The contract correctly identifies that `FocusTraversalService._handleCancel()` returns early when `_isFocusInsideDialog()` is true, and that `GamepadFileBrowser._handleKeyEvent()` only handles `LogicalKeyboardKey.escape`, not gamepad B (`GamepadAction.cancel`). The proposed fix to pop the dialog via `Navigator.of(context).pop()` from the focused node's context is sound.

3. **Testable success criteria**: Each criterion is specific, verifiable, and maps directly to user-facing behavior (A selects files, A opens directories, B cancels, no exceptions, keyboard nav preserved, tests pass).

4. **Good risk documentation**: The risks table covers widget reorder breakage, accidental dialog closing, `Actions.invoke` edge cases, test regressions, and platform-specific gamepad mappings.

## Gaps, Risks, and Missing Details

### 1. Verify `_isFocusInsideDialog()` actually catches `GamepadFileBrowser`
The contract assumes `_isFocusInsideDialog()` returns `true` for the file browser dialog. Looking at the implementation (lines 271–288), it walks up the focus tree looking for a `FocusScopeNode` whose `debugLabel` contains `'ModalScope'` or `'Dialog'`. `GamepadFileBrowser.show()` uses `showDialog<void>()`, which Flutter implements via a `_ModalScope` route whose focus scope label contains `'ModalScope'`. This *should* work, but the contract should explicitly verify this during implementation — add a debug assertion or manual log check, since if the label format changes in a future Flutter version, the B-key fix will silently regress.

### 2. The "Alternative / Complementary" `KeyboardListener` suggestion is potentially confusing
The contract suggests adding `LogicalKeyboardKey.gameButtonB` to the dialog's `KeyboardListener` as a "defensive measure." However, gamepad B events flow through `GamepadService.actions` → `_onGamepadAction()` → `_handleCancel()`, **not** through raw `KeyEvent`s that a `KeyboardListener` would see (unless `GamepadService` also synthesizes keyboard events, which is not indicated). This section should be clarified: either state that the `KeyboardListener` addition is for *keyboard* B-key mappings only, or remove it to avoid implying there are two code paths for the same gamepad action.

### 3. Missing: Focus restoration after dialog dismissal
When `Navigator.of(context).pop()` dismisses the dialog, Flutter automatically restores focus to the previously focused widget (the element that had focus before `showDialog` was called). The contract should verify this works correctly — specifically, that focus returns to the `PickerButton` or other widget that opened the file browser, and does not land on a non-interactive scope node.

### 4. Missing: Verify dialog footer buttons still work
The contract focuses on file/directory item activation but should also explicitly verify that the **Select** and **Cancel** footer buttons (`FocusableButton`s) continue to work correctly after the `Actions`/`Focus` swap. `FocusableButton` handles A/Enter in its own `onKeyEvent` (not via `Actions`), but `activateCurrentNode()` is called from `FocusTraversalService` on these buttons too. Ensure no new exceptions are introduced for footer button activation.

### 5. `ActivateIntent` handling consistency
After the swap, the `Actions` widget's `onInvoke` callback returns `true` (line 585 in current code). The contract should ensure this return value is preserved after reordering, as `Actions.invoke` returns this value and `activateCurrentNode()` checks `!= null` to determine success.

## Recommendations

1. **Clarify or remove the `KeyboardListener` defensive measure** in the Technical Approach section. If kept, explicitly state it targets keyboard-emulated B-button events, not `GamepadAction.cancel`.

2. **Add an explicit verification step** for focus restoration: after B-key dismissal, confirm via widget test or manual testing that focus returns to the triggering `PickerButton` (or other opener).

3. **Add a brief note** confirming footer button activation (`Select`, `Cancel`) is regression-tested, since they are also inside the dialog scope and interact with `FocusTraversalService`.

4. **Add a debug assertion or log check** during implementation to confirm `_isFocusInsideDialog()` returns `true` when focus is inside `GamepadFileBrowser`.

## Test Plan Preview

During evaluation, I will:
- Launch the app on Linux desktop and open the file browser from the Add Game dialog.
- Use keyboard/gamepad to focus a file item and press Enter/A — verify the file is selected and the dialog closes.
- Focus a directory item and press Enter/A — verify the directory opens.
- Press B while focus is on a file item, the Select button, and the Cancel button — verify the dialog closes in all three cases.
- Monitor debug logs for any `ActivateIntent not handled` or similar exceptions.
- Verify Up/Down/Left arrow navigation still works inside the file list.
- Run `flutter test` and confirm zero failures.
- Check that focus returns to a sensible widget after the dialog is dismissed.

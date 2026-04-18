# Sprint Contract: Settings Button & File Browser Polish

## Scope

Ensure the Settings button in `GamepadNavBar` and `GamepadFileBrowser` work correctly with the cleaned-up FocusScope architecture from Sprint 1. Specifically:

1. **BottomNav FocusScope**: The Settings button currently lives outside any registered `FocusScope`, so cross-scope navigation (Content ↔ BottomNav) does not work. We will wrap `GamepadNavBar` in a `FocusScope`, register it with `FocusTraversalService`, and implement wrapping logic.

2. **GamepadFileBrowser focus polish**: After removal of legacy dialog mode in Sprint 1, verify and fix any focus edge cases in the file browser so keyboard/gamepad navigation remains fully functional.

3. **Stale documentation cleanup**: Fix doc comments in `FocusTraversalService` and `GamepadHintProvider` that still reference the removed "dialog mode" concept (flagged in Sprint 1 evaluation).

## Implementation Plan

### 1. BottomNav FocusScope (`router.dart`)

- Add `_bottomNavScopeNode = FocusScopeNode(debugLabel: 'BottomNavScope')` to `_ShellWithFocusScopeState`.
- Register it in `initState()`: `FocusTraversalService.instance.setBottomNavContainer(_bottomNavScopeNode)`.
- Wrap `GamepadNavBar` in `FocusScope(node: _bottomNavScopeNode)` inside the `Column`.
- Dispose `_bottomNavScopeNode` in `dispose()`.

### 2. FocusTraversalService Cross-Scope Wrapping (`focus_traversal.dart`)

- Add `FocusScopeNode? _bottomNavFocusNode` field.
- Add `void setBottomNavContainer(FocusScopeNode node)` setter.
- Update `_isFocusInsideDialog()` to also exclude `_bottomNavFocusNode` from dialog detection.
- Add `wrapToBottomNav()` method that focuses the first focusable descendant of `_bottomNavFocusNode` (the Settings button).
- Update `moveFocus()` with two new wrapping rules:
  - `direction == down` from Content scope → `wrapToBottomNav()`
  - `direction == up` from BottomNav scope → `wrapToContent()`
- Update `_recoverFocusFromScope()` to try BottomNav scope as a final fallback.
- Remove stale "Dialog mode tracking" reference from the class-level doc comment.

### 3. GamepadFileBrowser Focus Polish (`gamepad_file_browser.dart`)

- Set `canRequestFocus: false` on `_keyboardFocusNode` to prevent the `KeyboardListener` from stealing autofocus when the dialog opens. The node will still receive bubbled key events because it is an ancestor in the focus tree of the dialog content.
- Verify the explicit `FocusScope` inside the `AlertDialog.content` correctly traps focus.
- Confirm that `_loadDirectory()`'s post-frame callback focusing `_itemFocusNodes[0]` still works as the primary mechanism for setting initial focus.

### 4. Stale Documentation (`gamepad_hint_provider.dart`)

- Update class doc (line 13) from "Listens to ... FocusTraversalService dialog mode" to "Listens to ... FocusTraversalService dialog detection via `isDialogOpen`".

## Success Criteria

1. **Settings button is inside a registered FocusScope**: `FocusTraversalService` has a `_bottomNavFocusNode` that is set by `_ShellWithFocusScope`, and `GamepadNavBar` is wrapped in a `FocusScope` with that node. Verified by reading `router.dart` and `focus_traversal.dart`.

2. **Cross-scope navigation Content → BottomNav**: When focus is inside the Content scope and `focusInDirection(down)` fails (e.g., at the bottom of a page), `moveFocus()` calls `wrapToBottomNav()` and the Settings button receives focus. Verified by code review of `moveFocus()` wrapping logic.

3. **Cross-scope navigation BottomNav → Content**: When focus is on the Settings button (inside BottomNav scope) and the user presses Up, `moveFocus()` calls `wrapToContent()` and focus returns to the Content scope. Verified by code review of `moveFocus()` wrapping logic.

4. **GamepadFileBrowser keyboard navigation works without dialog mode**: 
   - Left arrow from a file list item navigates to parent directory.
   - Escape closes the dialog.
   - Up/Down arrows move between list items.
   - Enter/Select/GameButtonA opens or selects the focused item.
   - Focus starts on the first item when the dialog opens.
   - Dialog focus is trapped — focus cannot leak to the underlying app while the dialog is open.
   Verified by code review and manual testing.

5. **Stale documentation cleaned up**: `FocusTraversalService` class doc no longer mentions "Dialog mode tracking". `GamepadHintProvider` class doc no longer mentions "dialog mode". Verified by code review.

6. **All 370 tests pass, no new analyzer warnings**: `flutter test` reports all tests passed. `flutter analyze` introduces no new issues in modified files. Verified by running both commands.

## Out of Scope for This Sprint

- Adding new UI features or changing visual design.
- Rewriting row/grid navigation logic (already works correctly).
- Adding new test files (this is a refactoring/polish sprint).
- Changing `wrapToContent()` to search focus history (current first-descendant behavior is retained).
- Handling Left-arrow on file browser buttons (Select/Cancel) — current behavior where `KeyboardListener` handles Left globally is retained.
- Modifying `FocusableButton`, `FocusableListTile`, or other focusable widget primitives.

## Files to Modify

| File | Changes |
|------|---------|
| `lib/presentation/navigation/focus_traversal.dart` | Add `_bottomNavFocusNode`, `setBottomNavContainer()`, `wrapToBottomNav()`, update `moveFocus()` wrapping logic, update `_isFocusInsideDialog()`, update `_recoverFocusFromScope()`, fix stale doc comment |
| `lib/app/router.dart` | Add `_bottomNavScopeNode` to `_ShellWithFocusScopeState`, register with service, wrap `GamepadNavBar` in `FocusScope`, dispose node |
| `lib/presentation/widgets/gamepad_file_browser.dart` | Set `canRequestFocus: false` on `_keyboardFocusNode` |
| `lib/presentation/navigation/gamepad_hint_provider.dart` | Fix stale class doc comment |

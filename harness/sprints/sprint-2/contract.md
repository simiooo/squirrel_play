# Sprint Contract: Fix Focus Traversal for PickerButton Widgets

## Scope
Fix directional focus traversal (D-pad Up/Down / keyboard arrow keys) to `PickerButton` widgets in the Add Game dialog's "Manual Add" and "Scan Directory" tabs. The root cause is that both `PickerButton` and `FocusableButton` have an outer `Focus` widget (added to intercept gamepad A-key events) that creates an unintended focusable node, interfering with `FocusScope`'s default traversal algorithm.

## Implementation Plan

### 1. Fix `PickerButton` Focus Architecture
- **File**: `lib/presentation/widgets/picker_button.dart`
- **Change**: Add `canRequestFocus: false` to the outer `Focus` widget (line 125)
- **Rationale**: The outer `Focus` widget must intercept `KeyEvent`s (gamepad A / Enter) but must NOT be a focusable node itself. The inner `TextButton` already owns the user-provided `focusNode` (`widget.focusNode`) and is the actual focus target. Without `canRequestFocus: false`, `FocusScope.traversalDescendants` sees two nodes where there should be one, breaking directional traversal.

### 2. Fix `FocusableButton` Focus Architecture
- **File**: `lib/presentation/widgets/focusable_button.dart`
- **Change**: Add `canRequestFocus: false` to the outer `Focus` widget (line 135)
- **Rationale**: Same pattern as `PickerButton`. The outer `Focus` is for key-event interception only; the inner `TextButton` owns the real focus node.

### 3. Verify Manual Add Tab Traversal
- **File**: `lib/presentation/widgets/manual_add_tab.dart`
- **Verify**: Within the `ContentScope` FocusScope, the traversal order is:
  1. `FocusableTextField` (Name input, `_nameInputFocusNode`)
  2. `PickerButton` (Browse..., `_filePickerFocusNode`)
  3. `FocusableButton` (Add Game, `_confirmFocusNode`)
- **Check**: D-pad Down from Name input → Browse button → Add Game button. D-pad Up reverses the order. No manual `registerContentNode` calls needed — `FocusScope` handles this automatically once the extra focus nodes are eliminated.

### 4. Verify Scan Directory Tab Traversal
- **File**: `lib/presentation/widgets/scan_directory_tab.dart`
- **Verify**: In the `_buildScanForm` state, the traversal order is:
  1. `PickerButton` (Add Directory, `_addDirectoryFocusNode`)
  2. `ManageDirectoriesSection` list items (if directories exist)
  3. `FocusableButton` (Start Scan, `_startScanFocusNode`)
- **Check**: D-pad Down from top of tab → Add Directory button → directory list → Start Scan button. D-pad Up reverses.

### 5. Regression Testing
- Run `flutter analyze` — must pass with zero issues.
- Run `flutter test` — all 370 existing tests must pass.
- No new tests required (contract scope is bug fix + verification), but existing widget tests using `FocusableButton` (e.g., `edit_game_dialog_test.dart`) must continue to pass.

## Success Criteria
1. **PickerButton outer Focus is non-focusable**: `PickerButton`'s outer `Focus` widget has `canRequestFocus: false` set. Verified by code review.
2. **FocusableButton outer Focus is non-focusable**: `FocusableButton`'s outer `Focus` widget has `canRequestFocus: false` set. Verified by code review.
3. **Manual Add tab traversal works**: In the Add Game dialog's Manual Add tab, D-pad Down from the Name `FocusableTextField` moves focus to the Browse `PickerButton`, and D-pad Down from the Browse button moves focus to the Add Game `FocusableButton`. D-pad Up reverses the order. Verified by interactive testing.
4. **Scan Directory tab traversal works**: In the Scan Directory tab, D-pad Down from the top moves focus to the Add Directory `PickerButton`, then into the directory list (if any), then to the Start Scan `FocusableButton`. D-pad Up reverses. Verified by interactive testing.
5. **PickerButton activation still works**: Pressing A/Enter on a focused `PickerButton` still opens the file/directory browser dialog. The outer `Focus` widget must continue to intercept the key event and trigger `onPressed`. Verified by interactive testing.
6. **FocusableButton activation still works**: Pressing A/Enter on a focused `FocusableButton` still triggers `onPressed`. Verified by interactive testing.
7. **Focus visual feedback preserved**: Both `PickerButton` and `FocusableButton` continue to show the correct focus border/background colors when focused. Verified by interactive testing.
8. **All existing tests pass**: `flutter test` reports 0 failures. Verified by CI/test run.
9. **Static analysis passes**: `flutter analyze` reports zero issues. Verified by CI/analysis run.

## Out of Scope for This Sprint
- Refactoring the broader focus architecture beyond adding `canRequestFocus: false` to the two buttons.
- Adding new widget tests for `PickerButton` or `FocusableButton` (no existing tests; new tests are optional and out of scope).
- Changing `FocusTraversalService` API or behavior.
- Fixing any i18n / hardcoded string issues (deferred to Sprint 3).
- Any changes to `GamepadFileBrowser` (already fixed in Sprint 1).
- Changes to `FocusableTextField`, `ManageDirectoriesSection`, or other widgets.

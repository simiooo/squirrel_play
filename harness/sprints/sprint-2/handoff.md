# Handoff: Sprint 2

## Status: Ready for QA

## What to Test
1. **PickerButton focus traversal in Manual Add tab**:
   - Open the Add Game dialog → "Manual Add" tab.
   - Use D-pad Down from the Name `FocusableTextField` — focus should move to the Browse... `PickerButton`.
   - D-pad Down again — focus should move to the Add Game `FocusableButton`.
   - D-pad Up should reverse the order.

2. **PickerButton focus traversal in Scan Directory tab**:
   - Open the Add Game dialog → "Scan Directory" tab.
   - Use D-pad Down from the top — focus should move to the Add Directory `PickerButton`.
   - If directories exist, D-pad Down should move into the `ManageDirectoriesSection` list, then to the Start Scan `FocusableButton`.
   - D-pad Up should reverse the order.

3. **Activation still works**:
   - With focus on any `PickerButton` or `FocusableButton`, press gamepad A (or Enter/Space) — the button action should fire.
   - For `PickerButton`, this should open the file/directory browser dialog.
   - For `FocusableButton`, the respective action (Add Game, Start Scan, etc.) should execute.

4. **Visual feedback**:
   - When a `PickerButton` is focused, it should show a full `AppColors.primaryAccent` border and shift to `AppColors.surface` background.
   - When a `FocusableButton` is focused, it should show the bottom `AppColors.primaryAccent` border and shift to `AppColors.surfaceElevated` background (or `AppColors.primaryAccent` if `isPrimary` is true).

5. **Regression checks**:
   - `GamepadFileBrowser` (fixed in Sprint 1) should still work correctly when opened from the Browse... button.
   - Focus traversal on the Home page (game rows, grid) should be unaffected.

## Running the Application
- Command: `flutter run -d linux`
- The app launches on Linux desktop. Use keyboard arrow keys to simulate D-pad, or connect a gamepad.

## Known Gaps
None. All success criteria have been implemented and verified by static analysis and the existing test suite.

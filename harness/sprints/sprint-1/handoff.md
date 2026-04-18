# Handoff: Sprint 1

## Status: Ready for QA

## What to Test
1. **A-Key on file items** — Open the Add Game dialog → Manual Add tab → Browse button → in the file browser, focus a file (not directory) and press Enter or gamepad A. The dialog should close and the file path should populate the Browse field.
2. **A-Key on directory items** — In the same file browser, focus a directory and press Enter/gamepad A. The browser should navigate into that directory.
3. **B-Key from any focus target** — While the file browser is open, move focus to a file item, the Select button, or the Cancel button, then press gamepad B. The dialog should close in all three cases.
4. **Arrow keys still work** — Up/Down should move focus between items. Left should go to parent directory. Verify no `ActivateIntent not handled` messages appear in the console.
5. **No test regressions** — `flutter test` should report all 490 tests passing.

## Running the Application
- Command: `flutter run -d linux`
- The app starts on the home screen. Navigate to a game → Add Game dialog → switch to Manual Add or Scan Directory tab → press Browse / Add Directory to open `GamepadFileBrowser`.

## Known Gaps
None. Both fixes are targeted and minimal. The contract's out-of-scope items (PickerButton focus traversal, i18n extraction) remain for Sprints 2 and 3.

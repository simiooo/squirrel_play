# Handoff: Sprint 1

## Status: Ready for QA

## What to Test

1. **Verify no legacy dialog mode calls remain**
   ```bash
   grep -rn "enterDialogMode\|exitDialogMode" lib/
   ```
   Expected: zero matches.

2. **Run static analysis**
   ```bash
   flutter analyze
   ```
   Expected: no new warnings or errors introduced by Sprint 1 changes.

3. **Run the test suite**
   ```bash
   flutter test
   ```
   Expected: all 370 tests pass.

4. **Manual UI verification** (if evaluator has UI access)
   - Open each dialog:
     - `AddGameDialog` — press the "+" or "Add Game" button
     - `DeleteGameDialog` — press delete on a game card
     - `ApiKeyDialog` — triggered on first launch or via settings
     - `MetadataSearchDialog` — triggered during metadata scan when match is ambiguous
     - `GamepadFileBrowser` — triggered when browsing for an executable in Manual Add tab
   - Confirm arrow-key navigation stays within the dialog (focus does not leak to the page behind)
   - Confirm pressing Escape (or gamepad B/cancel) closes the dialog
   - Confirm focus returns to the element that opened the dialog after close

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

No dev server is currently running.

## Known Gaps

None. All success criteria are met.

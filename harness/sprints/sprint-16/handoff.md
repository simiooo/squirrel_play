# Handoff: Sprint 16

## Status: Ready for QA

## Fix Applied (Post-Evaluation)
- **Fixed**: Settings / Gamepad Test pages now correctly show `Start Home` instead of `Start Menu` for the Start button hint.
- Added `gamepadNavHome` localization key to both English ("Home") and Chinese ("主页") ARB files.
- Regenerated localizations via `flutter gen-l10n`.
- Updated `gamepad_hint_provider.dart` to use `l10n.gamepadNavHome` on Settings and Gamepad Test routes.
- All 370 tests pass.

## What to Test

1. **Persistent Bottom Bar Visibility**
   - Launch the app and verify a 48px bottom bar is visible on every page (Home, Library, Settings, Gamepad Test).

2. **Contextual Hints**
   - **Home / Library**: Verify hints show A Select · B Back · X Details · Y Favorite · Start Menu.
   - **Settings / Gamepad Test**: Verify hints show A Toggle · B Back · Start Home.

3. **Dialog Mode Override**
   - Open the Add Game dialog (via the "Add Game" top bar button).
   - Verify the bottom bar switches to A Confirm · B Cancel while the dialog is open.
   - Close the dialog and verify hints revert to the page-specific set.

4. **Dynamic Route Updates**
   - Navigate from Home to Settings and back.
   - Confirm the bottom bar hints update immediately without requiring an app restart.

5. **Button Icon Colors**
   - Verify A button badge is teal, B is red, X is orange, Y is amber, Start/Back are muted gray.

6. **Responsive Behavior**
   - Resize the window to <640px width: only colored button icons should remain (text hidden).
   - Resize to ≥1024px width: full text labels should appear next to each icon.

7. **Non-Focusable**
   - Use keyboard arrow keys or a connected gamepad to navigate focus around the screen.
   - Confirm the bottom bar never receives focus highlight or traps navigation.

8. **Localization**
   - Switch the app language to Chinese in Settings.
   - Verify bottom bar labels display in Chinese (e.g., A 选择, B 返回, Start 主页 on Settings).

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

The app starts at the home route (`/`).

## Known Gaps

None. All success criteria from the sprint contract have been implemented and verified.

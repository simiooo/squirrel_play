# Handoff: Sprint 2

## Status: Ready for QA

## What to Test

### 1. BottomNav FocusScope registration
- Read `lib/app/router.dart` lines 262-308: `_ShellWithFocusScopeState` creates `_bottomNavScopeNode`, registers it, wraps `GamepadNavBar` in `FocusScope`, and disposes it.
- Read `lib/presentation/navigation/focus_traversal.dart` line 48: `_bottomNavFocusNode` field exists. Line 193-195: `setBottomNavContainer()` method exists.

### 2. Cross-scope navigation Content → BottomNav
- Read `lib/presentation/navigation/focus_traversal.dart` lines 596-599: in `moveFocus()`, when `direction == down` and current node is descendant of `_contentFocusNode`, it calls `wrapToBottomNav()`.
- `wrapToBottomNav()` is defined at lines 728-758.

### 3. Cross-scope navigation BottomNav → Content
- Read `lib/presentation/navigation/focus_traversal.dart` lines 601-604: in `moveFocus()`, when `direction == up` and current node is descendant of `_bottomNavFocusNode`, it calls `wrapToContent()`.

### 4. GamepadFileBrowser focus polish
- Read `lib/presentation/widgets/gamepad_file_browser.dart` lines 102-105: `_keyboardFocusNode` has `canRequestFocus: false`.
- The dialog content is wrapped in `FocusScope` at line 326, trapping focus.
- First item focus on open is handled at lines 207-210.
- Arrow keys, Enter, Escape are all handled by the `Focus` widgets on list items and the `KeyboardListener`.

### 5. Stale documentation cleanup
- Read `lib/presentation/navigation/focus_traversal.dart` line 14: class doc says "Cross-Scope wrapping (TopBar ↔ Content ↔ BottomNav)" — no mention of "Dialog mode tracking".
- Read `lib/presentation/navigation/gamepad_hint_provider.dart` lines 13-14: class doc says "FocusTraversalService dialog detection via `isDialogOpen`" — no mention of "dialog mode".

## Running the Application

- Command: `flutter run -d linux`
- No special setup needed beyond the existing Sprint 1 state.

## Known Gaps

None. All success criteria from the contract are implemented and verified.

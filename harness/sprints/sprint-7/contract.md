# Sprint Contract: Add Home Button to Top Navigation Bar

## Summary

Add a "Home" button to the TopBar that allows users to return to the home page (/) from any other page. The button will be positioned as the first navigation button (before "Add Game"), participate in the existing focus traversal system, play sound effects on focus/selection, support keyboard shortcut (H key), and include localized labels for English and Chinese.

## Scope

### In Scope
- Add "Home" button to TopBar in the navigation button row
- Position Home button as the first button (before "Add Game")
- Implement navigation to `/` route using GoRouter when button is pressed
- Add Home button focus node registration with FocusTraversalService
- Integrate with existing sound effects (focus move, page transition)
- Add keyboard shortcut (H key) for home navigation in FocusTraversalService
- Add localized strings for "Home" button label and accessibility hint:
  - English: `topBarHome`, `focusHomeHint`
  - Chinese: `topBarHome`, `focusHomeHint`
- Update button focus node array to include Home button as index 0
- Ensure Home button follows existing focus animation patterns via FocusableButton

### Out of Scope
- Visual icon changes (uses text label like other buttons)
- Gamepad Y button mapping (Y is mapped to Toggle Favorite per spec line 972)
- ShellRoute refactoring (covered in Sprint 10)
- Changes to other top bar buttons or functionality
- Changes to page transition animations
- Changes to focus traversal logic beyond adding H key and GamepadAction.home handlers

## Technical Design

### Files to Modify/Create

| File | Action | Description |
|------|--------|-------------|
| `lib/presentation/widgets/top_bar.dart` | Modify | Add Home button as first button in navigation row, update focus node array |
| `lib/presentation/navigation/focus_traversal.dart` | Modify | Add H key handler AND `GamepadAction.home` handler for gamepad Back button navigation |
| `lib/l10n/app_en.arb` | Modify | Add `topBarHome` and `focusHomeHint` localization keys |
| `lib/l10n/app_zh.arb` | Modify | Add `topBarHome` and `focusHomeHint` Chinese translations |

### Implementation Details

#### 1. TopBar Changes (`top_bar.dart`)

**Focus Node Array Update:**
- Current: `[AddGameButton, GameLibraryButton, RescanButton, SettingsButton]` (4 nodes)
- New: `[HomeButton, AddGameButton, GameLibraryButton, RescanButton, SettingsButton]` (5 nodes)
- Home button gets index 0, becoming the first button in the navigation row

**Home Button Widget:**
```dart
FocusableButton(
  focusNode: _buttonFocusNodes[0],  // Home is now index 0
  label: l10n?.topBarHome ?? 'Home',
  hint: l10n?.focusHomeHint ?? 'Return to home page',
  onPressed: () => _handleHome(context),
),
```

**Home Handler Method:**
```dart
void _handleHome(BuildContext context) {
  // Play page transition sound first
  SoundService.instance.playPageTransition();
  // Navigate to home page
  context.go('/');
}
```

**Button Order in Row:**
1. Home (new)
2. Add Game (moved from index 0 to index 1)
3. Game Library (moved from index 1 to index 2)
4. Rescan (moved from index 2 to index 3)
5. Settings (moved from index 3 to index 4)

#### 2. Focus Traversal Changes (`focus_traversal.dart`)

**Add H Key Handler in `_handleKeyEvent`:**
```dart
case LogicalKeyboardKey.keyH:
  // H key / Home shortcut
  _handleHomeShortcut();
  return true;
```

**Add Home Shortcut Handler Method:**
```dart
void _handleHomeShortcut() {
  debugPrint('[FocusTraversalService] H key pressed - navigating home');
  // Navigate to home route
  final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
  if (context != null && context.mounted) {
    SoundService.instance.playPageTransition();
    GoRouter.of(context).go('/');
  }
}
```

**Add GamepadAction.home Handler in `_onGamepadAction`:**
```dart
switch (action) {
  case GamepadAction.navigateUp:
    moveFocus(TraversalDirection.up);
  case GamepadAction.navigateDown:
    moveFocus(TraversalDirection.down);
  case GamepadAction.navigateLeft:
    moveFocus(TraversalDirection.left);
  case GamepadAction.navigateRight:
    moveFocus(TraversalDirection.right);
  case GamepadAction.confirm:
    activateCurrentNode();
  case GamepadAction.cancel:
    _handleCancel();
  case GamepadAction.home:
    // Handle gamepad Back/Select button for home navigation
    _handleHomeShortcut();
    return;
  default:
    // Other actions not handled
    break;
}
```

**Note**: The `GamepadService` already emits `GamepadAction.home` for the Back button (button names: 'back', 'select', 'button 8'), but `FocusTraversalService` was not handling this action. This fix ensures the Back button on gamepad navigates to the home page.

#### 3. Localization Changes

**English (`app_en.arb`):**
```json
"topBarHome": "Home",
"@topBarHome": {
  "description": "Button label for navigating to home page"
},
"focusHomeHint": "Return to home page",
"@focusHomeHint": {
  "description": "Accessibility hint for Home button"
}
```

**Chinese (`app_zh.arb`):**
```json
"topBarHome": "主页",
"@topBarHome": {
  "description": "导航到主页的按钮标签"
},
"focusHomeHint": "返回主页",
"@focusHomeHint": {
  "description": "主页按钮的无障碍提示"
}
```

#### 4. Sound Effects Integration

The Home button will use existing sound effects:
- **Focus move**: `SoundService.instance.playFocusMove()` (handled by FocusTraversalService)
- **Page transition**: `SoundService.instance.playPageTransition()` (called in `_handleHome`)

No new sound files are required for this sprint.

#### 5. Focus Animation

The Home button uses `FocusableButton` which already implements:
- Focus indicator (glow/border) on focus
- Scale animation on focus (per design spec: 150ms, easeOut curve)
- Background color shift to elevated surface

No additional animation work is required.

## Success Criteria

- [ ] **Home Button Visible**: Given any page in the app, when the user views the TopBar, then a "Home" button is visible as the first navigation button (before "Add Game")
- [ ] **Home Button Navigates**: Given the Home button is focused, when the user presses A (or Enter), then navigation returns to the home page (`/`)
- [ ] **Focus Indicator Works**: Given the Home button is unfocused, when the user navigates to it via D-pad, then it shows a clear focus indicator (glow/border animation)
- [ ] **URL Changes**: Given the app is on a non-home page (e.g., `/library`), when the Home button is pressed, then the URL changes to `/` and the home page displays
- [ ] **Keyboard Shortcut Works**: Given the user presses H key, when not in a text input, then navigation returns to home page
- [ ] **Gamepad Back Button Works**: Given the user presses Back button on gamepad (emits `GamepadAction.home`), when not in a dialog, then navigation returns to home page
- [ ] **Localization Works**: Given any locale (EN or ZH), when viewing the TopBar, the Home button label is displayed in the selected language
- [ ] **Sound Effects Play**: Given sound files are present, when focusing the Home button and pressing it, appropriate sound effects play (focus move, page transition)
- [ ] **No Regressions**: Given the existing top bar buttons, they continue to work correctly with their new focus node indices

## Testing Plan

### Manual Testing Steps

1. **Visual Verification**
   - Launch the app
   - Verify "Home" button appears as first button in top bar navigation
   - Verify button label displays "Home" (or "主页" in Chinese locale)

2. **Navigation Test**
   - Navigate to Library page (via Game Library button)
   - Click Home button (or press Enter when focused)
   - Verify app returns to home page
   - Verify URL changes to `/`

3. **Focus Navigation Test**
   - Use D-pad/arrow keys to navigate to Home button
   - Verify focus indicator appears (glow/border)
   - Verify sound effect plays on focus
   - Press A/Enter to activate
   - Verify page transition sound plays

4. **Keyboard Shortcut Test**
   - Navigate to any non-home page
   - Press H key
   - Verify app returns to home page
   - Verify sound effect plays

5. **Gamepad Back Button Test**
   - Connect a gamepad controller
   - Navigate to any non-home page (e.g., Library or Settings)
   - Press Back/Select button on gamepad (typically labeled "Back", "Select", or button 8)
   - Verify app returns to home page
   - Verify page transition sound plays
   - Verify URL changes to `/`

6. **Localization Test**
   - Switch to Chinese locale in Settings
   - Verify Home button displays "主页"
   - Switch back to English
   - Verify Home button displays "Home"

7. **Regression Test**
   - Test all other top bar buttons still work:
     - Add Game (opens dialog)
     - Game Library (navigates to /library)
     - Rescan (opens dialog on scan tab)
     - Settings (navigates to /settings)

### Automated Testing

- Run existing widget tests: `flutter test`
- Verify no test failures related to TopBar or focus management
- Verify no analysis errors: `flutter analyze`

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Focus node index changes break existing tests | Medium | Medium | Update any hardcoded focus node indices in tests; run full test suite |
| H key conflicts with existing shortcuts | Low | Low | H key is designated for Home in gamepad mapping spec (line 974) |
| Localization strings not generated properly | Low | Medium | Run `flutter gen-l10n` after ARB file changes; verify generated files |
| Sound service not initialized causes crash | Low | High | SoundService already handles missing files gracefully; no changes needed |
| Focus traversal order feels unnatural | Low | Low | Home as first button follows standard UX patterns (Home | Add | Library | Rescan | Settings) |

## Dependencies

- **Sprint 6**: Complete top bar implementation (provides existing button structure, focus system, sound integration)
- **No new dependencies**: Uses existing `go_router`, `flutter_bloc`, `gamepads` infrastructure

## Notes

- The Home button follows the existing button pattern using `FocusableButton` widget
- Focus node registration order determines D-pad navigation order within the top bar
- The H key shortcut is documented in the gamepad button mapping spec (line 974 of spec.md)
- This sprint is a prerequisite for Sprint 10 (ShellRoute refactoring) as it establishes the complete navigation structure

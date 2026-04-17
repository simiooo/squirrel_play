# Contract Review: Sprint 7

## Assessment: NEEDS_REVISION

## Alignment with Specification

The contract largely aligns with Sprint 7 specification goals, but has a **critical gap** around gamepad Back button handling. The spec states:
- Line 508: "Y button on gamepad could also map to 'go home' as a shortcut"
- Line 974: "Back | Home page | H" (gamepad mapping)

The contract correctly identifies the H keyboard shortcut requirement and excludes Y button from scope (Y is mapped to Toggle Favorite in line 972), but **critically misses that the Back button (`GamepadAction.home`) is NOT currently handled** in `FocusTraversalService._onGamepadAction`.

### Current Implementation Gap

`GamepadService` already emits `GamepadAction.home` for the Back button (line 229-232):
```dart
case 'back':
case 'select':
case 'button 8':
  return GamepadAction.home;
```

But `FocusTraversalService._onGamepadAction` has no case for `GamepadAction.home` — it falls through to `default` and does nothing. **Pressing Back on gamepad currently has no effect.**

The contract assumes "covered by existing Back button mapping" but this mapping doesn't work because FocusTraversalService doesn't handle the `home` action.

## Completeness Checklist

- [x] Home button visible in TopBar as first navigation button
- [x] Home button navigation to `/` route using GoRouter
- [x] Focus node registration with FocusTraversalService
- [x] Sound effects integration (focus move, page transition)
- [x] Keyboard shortcut (H key) for home navigation
- [x] Localization for EN and ZH
- [ ] **MISSING**: Gamepad Back button handling for home navigation
- [x] Focus animation pattern via FocusableButton
- [x] Success criteria are measurable and testable

## Technical Concerns

### 1. Critical: Missing `GamepadAction.home` Handler (BLOCKER)

**Location**: `lib/presentation/navigation/focus_traversal.dart`

**Problem**: The `_onGamepadAction` method handles navigateUp, navigateDown, navigateLeft, navigateRight, confirm, cancel, but NOT `home`. The Back button on gamepad emits `GamepadAction.home`, which is unhandled.

**Evidence**:
```dart
// Current code in FocusTraversalService._onGamepadAction:
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
  default:
    // Other actions not handled
    break;
}
```

**Required Fix**: Add handling for `GamepadAction.home`:
```dart
case GamepadAction.home:
  _handleHomeShortcut();
  return;
```

**Impact**: Without this fix, gamepad Back button won't navigate home. Users pressing Back on a gamepad will see no response, breaking acceptance criteria for gamepad-based home navigation.

### 2. Minor: Icon vs Text Label Discrepancy

**Spec line 504**: "Use a home icon (e.g., `Icons.home` or similar gamepad-friendly icon)"
**Contract line 23**: "Visual icon changes (uses text label like other buttons)" — marked as Out of Scope

**Observation**: The existing TopBar uses text labels (`FocusableButton` with `label` parameter), not icons. The contract correctly aligns with existing implementation. The spec's "home icon" is aspirational; the codebase uses text labels. This is acceptable but worth noting.

### 3. Minor: Inconsistency in Localization Key Naming

Current pattern uses `topBarAddGame`, `topBarGameLibrary`, etc. The contract proposes `topBarHome` which is consistent with the existing naming convention. ✓

## Suggestions for Improvement

1. **Add `GamepadAction.home` handler** to the Files to Modify table:
   | File | Action | Description |
   |------|--------|-------------|
   | `lib/presentation/navigation/focus_traversal.dart` | Modify | Add H key handler AND `GamepadAction.home` handler for gamepad Back button |

2. **Add success criterion** for gamepad Back button:
   - [ ] **Gamepad Back Button Works**: Given the user presses Back button on gamepad, when not in a dialog, then navigation returns to home page

3. **Add manual testing step** for gamepad Back button:
   - Connect a gamepad
   - Navigate to any non-home page
   - Press Back/Select button on gamepad
   - Verify app returns to home page

4. **Clarify test plan**: The testing plan should include both keyboard (H key) and gamepad (Back button) testing for the home navigation functionality.

## Verdict

**NEEDS_REVISION** — The contract is incomplete because it claims gamepad Back button is "covered by existing mapping" when in fact `FocusTraversalService` does not handle `GamepadAction.home`. This is a blocker that would result in failing acceptance criteria for gamepad-based home navigation.

**Required Changes**:
1. Add `GamepadAction.home` case to `FocusTraversalService._onGamepadAction`
2. Add corresponding success criterion for gamepad Back button
3. Add gamepad testing step to manual testing plan

Once these revisions are made, the contract can be approved. The rest of the technical design is sound and well-documented.
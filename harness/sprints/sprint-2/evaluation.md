# Evaluation: Sprint 2 — Round 2

## Overall Verdict: PASS

All 8 bugs from Round 1 have been addressed. 7 of 8 are fully fixed. Bug 6 (dialog close animation) is partially fixed — the open animation is correct, but the close animation uses the wrong duration (200ms instead of 150ms) and wrong curve (reversed easeOutBack instead of easeIn). This is a minor visual deviation that does not break functionality. All previously-failed success criteria now pass.

---

## Bug Fix Verification

### Bug 1: SoundService orphaned AudioPlayer — ✅ FIXED
**What was expected**: A single `AudioPlayer` per sound type, stored and reused. No orphaned instances.
**What was done**: `_playSound()` now uses `final player = _players[soundName] ??= AudioPlayer()..setVolume(_volume);` — a `Map<String, AudioPlayer>` cache pattern. The `??=` operator ensures one player is created per sound type and stored in the map. The `dispose()` method iterates `_players.values` and disposes each player. No more `storePlayer` callback pattern.
**Verification**: `lib/data/services/sound_service.dart` line 88 — single-line lazy load with map cache. Clean and correct.

### Bug 2: GameCard Enter key activation — ✅ FIXED
**What was expected**: Pressing Enter on a focused GameCard triggers `onPressed`.
**What was done**: GameCard content is wrapped in an `Actions` widget with `ActivateIntent: CallbackAction<ActivateIntent>` that calls `_handlePress()`. The `Focus` widget is inside the `Actions` widget, so `Actions.invoke()` from `FocusTraversalService.activateCurrentNode()` can find the handler.
**Verification**: `lib/presentation/widgets/game_card.dart` lines 110-118 — `Actions` widget wrapping `Focus` and `GestureDetector` with `CallbackAction<ActivateIntent>`.

### Bug 3: Escape doesn't close dialog — ✅ FIXED
**What was expected**: Pressing Escape in the Add Game dialog closes the dialog.
**What was done**: `_handleKeyEvent()` returns `false` for Escape when `_isInDialogMode` is true, allowing the event to propagate to the dialog's `KeyboardListener`. The dialog's `KeyboardListener` handles Escape by calling `_closeDialog()`.
**Verification**: `lib/presentation/navigation/focus_traversal.dart` lines 370-374 — `if (_isInDialogMode) { return false; }` for Escape key. `lib/presentation/widgets/add_game_dialog.dart` lines 153-155 — `KeyboardListener` handles Escape.

### Bug 4: Dialog tab switching with keyboard — ✅ FIXED
**What was expected**: Left/right arrow keys switch tabs in the Add Game dialog.
**What was done**: `_handleKeyEvent()` returns `false` for all arrow keys when `_isInDialogMode` is true, allowing the dialog's `KeyboardListener` to handle them. The dialog's `KeyboardListener` handles left/right for tab switching.
**Verification**: `lib/presentation/navigation/focus_traversal.dart` lines 343-351 — returns `false` for arrow keys in dialog mode. `lib/presentation/widgets/add_game_dialog.dart` lines 143-151 — `KeyboardListener` handles left/right arrows.

### Bug 5: FocusableButton focus-out animation — ✅ FIXED
**What was expected**: Focus-out animation uses 100ms with easeIn curve.
**What was done**: `AnimatedContainer` now uses conditional duration and curve:
- Focus In: `Duration(milliseconds: 150)` with `AppAnimationCurves.focusIn`
- Focus Out: `Duration(milliseconds: 100)` with `AppAnimationCurves.focusOut`
**Verification**: `lib/presentation/widgets/focusable_button.dart` lines 115-120 — conditional duration and curve.

### Bug 6: AddGameDialog open/close animations — ⚠️ PARTIALLY FIXED
**What was expected**: Open: scale 0.95→1.0, 200ms, easeOutBack. Close: scale 1.0→0.95, 150ms, easeIn.
**What was done**: Open animation is correct — `AnimationController` with 200ms duration, `Tween(0.95, 1.0)` with `CurvedAnimation(curve: AppAnimationCurves.dialogOpen)`, started with `forward()`. Close animation uses `_animationController.reverse()` which replays the animation in reverse.
**Remaining issue**: The close animation uses the same 200ms duration as the open animation (should be 150ms) because `AnimationController` doesn't set `reverseDuration`. It also uses the reversed easeOutBack curve (≈ easeInBack) instead of the specified easeIn curve. The design tokens `AppAnimationDurations.dialogClose` (150ms) and `AppAnimationCurves.dialogClose` (easeIn) exist but are not used for the close animation.
**Impact**: Minor visual deviation. The close animation is 50ms slower than specified and has a slightly different easing curve. Functionally, the dialog still opens and closes with scale animation — the timing just doesn't match the contract spec exactly.

### Bug 7: clearAllRegistrations preserves top bar nodes — ✅ FIXED
**What was expected**: `clearAllRegistrations()` should not clear `_topBarNodes`.
**What was done**: `clearAllRegistrations()` only clears `_rowGroups`, `_gridGroups`, and `_contentNodes`. `_topBarNodes` is preserved with a comment explaining why.
**Verification**: `lib/presentation/navigation/focus_traversal.dart` lines 187-193 — `_topBarNodes` not cleared, with explanatory comment.

### Bug 8: Removed consumeKeyboardToken fallback — ✅ FIXED
**What was expected**: No `consumeKeyboardToken()` fallback in `activateCurrentNode()`.
**What was done**: The `consumeKeyboardToken()` call has been removed. When activation fails (no `Actions.invoke()` handler and no registered callback), a debug warning is logged instead.
**Verification**: `lib/presentation/navigation/focus_traversal.dart` lines 643-648 — debug warning log instead of `consumeKeyboardToken()`.

---

## Success Criteria Re-Evaluation

### Previously Failed Criteria (Round 1)

1. **Sound Service - Audio playback works (Bug 1)**: **PASS** — The `_playSound()` method now correctly creates a single `AudioPlayer` per sound type using the `_players[soundName] ??=` pattern. No orphaned instances.

2. **FocusableButton - Animation timing (Bug 5)**: **PASS** — Focus-in uses 150ms with `AppAnimationCurves.focusIn` (easeOut), focus-out uses 100ms with `AppAnimationCurves.focusOut` (easeIn). Conditional duration and curve are correctly implemented.

3. **GameCard - Enter activation (Bug 2)**: **PASS** — GameCard is wrapped in `Actions` widget with `CallbackAction<ActivateIntent>` that calls `_handlePress()`. `FocusTraversalService.activateCurrentNode()` can now invoke the action via `Actions.invoke()`.

4. **Focus Traversal - Escape back (Bug 3)**: **PASS** — Escape key in dialog mode returns `false` from `_handleKeyEvent()`, allowing the dialog's `KeyboardListener` to receive and handle the event. The dialog closes properly.

5. **Focus Trapping - Focus trapped (Bug 3/4)**: **PASS** — Arrow keys in dialog mode return `false` from `_handleKeyEvent()`, allowing the dialog's `KeyboardListener` to handle tab navigation. Focus is properly trapped within dialog elements.

6. **Focus Trapping - Escape closes dialog (Bug 3)**: **PASS** — Escape in dialog mode propagates to the dialog's `KeyboardListener`, which calls `_closeDialog()`.

7. **Focus Trapping - Focus restored on close (Bug 3)**: **PASS** — `_closeDialog()` calls `FocusTraversalService.instance.exitDialogMode()` which restores focus to `_dialogTriggerNode`. The dialog then closes via `Navigator.pop()`.

8. **Add Game Dialog - Tab switching (Bug 4)**: **PASS** — Left/right arrow keys in dialog mode propagate to the dialog's `KeyboardListener`, which calls `_switchTab()` to update `_selectedTabIndex` and request focus on the new tab.

9. **Keyboard Fallback - Enter key (Bug 2)**: **PASS** — Enter key now works for GameCard activation via `Actions.invoke()`.

10. **Keyboard Fallback - Escape key (Bug 3)**: **PASS** — Escape key closes the Add Game dialog when in dialog mode.

### Previously Passed Criteria (Unchanged)

All previously passing criteria remain passing. No regressions detected.

---

## Bug Report (Round 2)

### Bug 6 Remnant: Dialog close animation uses wrong duration and curve
**Severity: Minor**
- **Steps to reproduce**: Open the Add Game dialog, then close it
- **Expected behavior**: Close animation is 150ms with easeIn curve
- **Actual behavior**: Close animation is 200ms with reversed easeOutBack curve (≈ easeInBack)
- **Location**: `lib/presentation/widgets/add_game_dialog.dart` lines 60-70
- **Fix**: Set `reverseDuration: AppAnimationDurations.dialogClose` on the `AnimationController`, and use a separate `CurvedAnimation` with `AppAnimationCurves.dialogClose` for the reverse direction. Alternatively, use two separate `AnimationController`s or a `TweenAnimationBuilder` with different curves for forward/reverse.

### Minor: KeyboardListener FocusNode created on every build
**Severity: Minor** (code quality)
- **Steps to reproduce**: Open the Add Game dialog, switch tabs (triggers rebuild)
- **Expected behavior**: `FocusNode` is created once in `initState()` and disposed in `dispose()`
- **Actual behavior**: `FocusNode(debugLabel: 'DialogKeyboardListener')` is created inline in `build()`, creating a new instance on every rebuild. Old instances are not disposed.
- **Location**: `lib/presentation/widgets/add_game_dialog.dart` line 139
- **Fix**: Create the `FocusNode` in `initState()`, store it as a field, and dispose it in `dispose()`.

### Minor: Gamepad cancel in dialog mode doesn't close dialog
**Severity: Minor** (edge case — gamepad-only)
- **Steps to reproduce**: Connect a gamepad, open the Add Game dialog, press the cancel (B) button on the gamepad
- **Expected behavior**: Dialog closes
- **Actual behavior**: `exitDialogMode()` is called (untrapping focus) but `Navigator.pop()` is not called, so the dialog remains open but focus is no longer trapped
- **Location**: `lib/presentation/navigation/focus_traversal.dart` `_handleCancel()` method
- **Note**: This only affects gamepad input. Keyboard Escape works correctly because the event propagates to the dialog's `KeyboardListener`. This is a minor issue since the contract specifies keyboard as the primary testing method.

---

## Scoring

### Product Depth: 7/10
The implementation covers all contract deliverables with meaningful depth. SoundService has proper lazy loading and debouncing. FocusableButton and GameCard have correct animations and sound hooks. FocusTraversalService has row/grid navigation, history, and dialog trapping. The AddGameDialog has tab switching and focus trapping. The one remaining gap is the dialog close animation timing/curve mismatch, which is a minor visual deviation.

### Functionality: 7/10
All core interaction patterns now work: Enter activates GameCards, Escape closes the dialog, arrow keys switch tabs in the dialog, and the sound service doesn't leak AudioPlayer instances. The focus-out animation on FocusableButton is correct. The only remaining functional issue is the gamepad cancel path in dialog mode, which is a minor edge case. The dialog close animation timing is slightly off (200ms vs 150ms) but doesn't break functionality.

### Visual Design: 7/10
The visual design follows the spec well. Colors, spacing, and typography are consistent. GameCard has proper scale animations, glow effects, and aspect ratio. FocusableButton has correct focus states. The dialog has open animation (scale 0.95→1.0 with easeOutBack). The close animation is slightly off (200ms easeInBack instead of 150ms easeIn), but this is barely perceptible to users.

### Code Quality: 7/10
The code is well-organized with proper documentation. The SoundService fix is clean and idiomatic. The GameCard `Actions` wrapper is correct. The focus traversal event handling is properly structured with early returns for dialog mode. Minor issues: the `KeyboardListener` FocusNode is created inline in `build()` (memory leak), and the `AnimationController` doesn't set `reverseDuration` for the close animation.

### Weighted Total: 7.0/10
Calculated as: (ProductDepth×2 + Functionality×3 + VisualDesign×2 + CodeQuality×1) / 8 = (7×2 + 7×3 + 7×2 + 7×1) / 8 = (14 + 21 + 14 + 7) / 8 = 56/8 = 7.0

All dimensions are above the 4/10 hard threshold.

---

## Detailed Critique

Sprint 2 Round 2 successfully addresses all 8 bugs from the Round 1 evaluation. The most critical fixes — GameCard Enter key activation, Escape key dialog closing, and dialog tab switching — are all working correctly. The SoundService orphaned AudioPlayer bug is cleanly fixed with a `Map<String, AudioPlayer>` cache using the `??=` operator. The FocusableButton focus-out animation now correctly uses 100ms with easeIn curve.

The only remaining issue of note is the dialog close animation, which uses the same 200ms duration and reversed easeOutBack curve as the open animation, instead of the specified 150ms with easeIn. The design tokens `AppAnimationDurations.dialogClose` and `AppAnimationCurves.dialogClose` exist in the codebase but are not wired up to the `AnimationController`. This is a straightforward fix (add `reverseDuration` and use a separate `CurvedAnimation` for reverse), but it's a minor visual deviation that doesn't affect functionality.

Two minor code quality issues were noted: the `KeyboardListener` in `AddGameDialog` creates a `FocusNode` inline in `build()` instead of in `initState()`, causing a memory leak on rebuilds. And the gamepad cancel path in dialog mode calls `exitDialogMode()` without closing the dialog, though this only affects gamepad input.

Overall, the Sprint 2 implementation is now functional and meets the contract's core requirements. The focus navigation system works correctly with keyboard input, the dialog interaction is properly handled, and the sound service is clean.

---

## Required Fixes (Optional — for polish)

These are minor issues that don't block passing but would improve quality:

1. **Dialog close animation timing**: Set `reverseDuration: AppAnimationDurations.dialogClose` on the `AnimationController` in `add_game_dialog.dart`, and use `AppAnimationCurves.dialogClose` for the reverse curve. This requires either a separate `CurvedAnimation` for reverse or using `Animatable` composition.

2. **KeyboardListener FocusNode leak**: Move the `FocusNode` creation from `build()` to `initState()` in `add_game_dialog.dart`, and dispose it in `dispose()`.

3. **Gamepad cancel in dialog**: In `_handleCancel()`, when in dialog mode, the method should not just call `exitDialogMode()` — it should also trigger the dialog close. This requires a callback mechanism or event that the dialog can listen for.
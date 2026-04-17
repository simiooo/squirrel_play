# Sprint 13 Contract Review

## Overall Assessment: NEEDS_REVISION

The contract is well-structured and closely aligned with the spec's Sprint 13 definition. The technical approach is sound, the widget designs follow the existing `FocusableButton` pattern, and all referenced design tokens and services exist in the codebase. However, there are several issues that need to be addressed before implementation begins — primarily around animation timing inconsistencies, a critical gamepad navigation conflict for sliders, and missing focus node coverage for existing controls.

---

## Completeness Check

- [x] All success criteria are testable and objective — mostly yes, but see Issue #1
- [x] Technical approach covers all deliverables — yes, three widgets + settings refactor
- [ ] Files to create and modify are correctly identified — missing registration of existing focus nodes (see Issue #5)
- [x] Dependencies are identified — SoundService, design tokens, FocusTraversalService all checked
- [x] Risk areas are identified — 7 risks identified, including the slider gamepad conflict

## Issues Found

### Issue 1: Animation Timing Contradiction Between FocusableButton and Design Tokens

The contract's `FocusableListTile` section specifies:
- "150ms ease-out on focus in, 100ms ease-in on focus out"

But the design tokens in `design_tokens.dart` define:
- `AppAnimationDurations.focusIn` = 200ms
- `AppAnimationDurations.focusOut` = 150ms

The existing `FocusableButton` uses **hardcoded** durations (150ms/100ms) rather than the design token values. The contract's Design Token References section (lines 88-96) correctly cites the design tokens (200ms/150ms), but the FocusableListTile widget description contradicts this.

**Resolution**: All three new widgets should consistently use `AppAnimationDurations.focusIn` (200ms) and `AppAnimationDurations.focusOut` (150ms). The FocusableListTile description should be corrected from "150ms ease-out on focus in, 100ms ease-in on focus out" to match the design tokens. Alternatively, if the intent is to use faster timings for list items (the FocusableButton already deviates), this should be explicitly documented as a deliberate deviation with rationale.

### Issue 2: Critical — Slider D-pad Conflict Has No Resolution Strategy

The contract identifies this in Risk Area #2 but doesn't specify a solution. The problem: if `FocusableSlider` consumes D-pad left/right events for value adjustment, the user cannot navigate **away** from the slider using left/right D-pad. The `FocusTraversalService` routes all arrow keys through its handler, and the slider must intercept left/right only when focused.

**Required resolution**: The contract must specify that:
- D-pad **up/down** moves focus away from the slider (standard vertical navigation)
- D-pad **left/right** adjusts the slider value when the slider is focused
- The `FocusableSlider` should use `onKeyEvent` to consume left/right `KeyEvent`s when focused, returning `KeyEventResult.handled`, which prevents `FocusTraversalService` from also processing them
- This matches standard 10-foot UI slider behavior (Steam Big Picture, PlayStation Settings)

The current `FocusTraversalService._handleKeyEvent` catches all arrow keys globally. The slider's `onKeyEvent` runs first (Flutter's key event propagation: focused widget → parents → services). The contract mentions using `Focus` widget with `onKeyEvent` but should explicitly state that the handler must return `KeyEventResult.handled` for left/right when the slider is focused, preventing the event from reaching `FocusTraversalService`.

### Issue 3: Existing Focus Nodes Not Registered with FocusTraversalService

The contract specifies adding 4 new `FocusNode` fields (`_englishLanguageFocusNode`, `_chineseLanguageFocusNode`, `_muteSwitchFocusNode`, `_volumeSliderFocusNode`) and registering them with `FocusTraversalService`. However, the existing Settings page already has 6 FocusNodes that are **not** registered with `FocusTraversalService`:
- `_backButtonFocusNode`
- `_apiKeyFocusNode`
- `_saveKeyFocusNode`
- `_clearKeyFocusNode`
- `_testSoundFocusNode`
- `_testGamepadFocusNode`

Without registering these, D-pad navigation won't work correctly for the Save/Clear/Test buttons or the API key input. The contract should specify that **all** interactive focus nodes on the Settings page be registered with `FocusTraversalService`, not just the 4 new ones.

### Issue 4: TextField (API Key Input) Lacks Focusable Styling

The API key `TextField` (`_apiKeyFocusNode`) uses Flutter's default focus indicator, which is likely a subtle underline that's invisible at 10-foot viewing distance on a dark theme. The contract's scope says "only adding focus indicators to existing designs" and "Visual redesign of controls — only adding focus indicators," but the `TextField` is an interactive control that also needs visible gamepad focus. The contract should either:
1. Explicitly scope out the TextField (with rationale), or
2. Specify that the `TextField` gets a visible focus border using the same design token system

### Issue 5: FocusableSwitch Border vs. FocusableButton/ListTile Border Style Inconsistency

- `FocusableButton` uses a **2px bottom-only border** in `primaryAccent`
- `FocusableListTile` uses a **2px bottom border** in `primaryAccent`
- `FocusableSwitch` uses a **2px full border** (all 4 sides) in `primaryAccent`

The Switch uses a full border while other controls use bottom-only. This is a deliberate design choice (switches are compact elements that benefit from a complete focus ring, while buttons/list tiles are wide horizontal elements where a bottom underline looks better) — but this rationale should be documented in the contract to ensure consistency.

### Issue 6: Missing i18n Key Enumeration

The contract mentions needing accessibility hint strings but only gives examples (`settings.sound.volumeHint`, `settings.sound.muteHint`). A complete list of required i18n keys should be specified:
- `settings.sound.volumeHint` — Volume slider accessibility label
- `settings.sound.muteHint` — Mute switch accessibility label
- `settings.language.englishLabel` — English language option accessibility label
- `settings.language.chineseLabel` — Chinese language option accessibility label

### Issue 7: Success Criterion 5 — Division Step Ambiguity

Criterion 5 says "the slider value adjusts by one division step (0.1 for volume slider)". The existing slider has `divisions: 10, max: 1.0`, so 0.1 per step is correct. However, the `FocusableSlider` widget should accept a `step` parameter rather than assuming divisions imply the step. If someone uses `FocusableSlider` with `divisions: 10, max: 100`, the step should be 10, not 0.1. The contract should specify that the step is derived from `(max - min) / divisions` or explicitly passed.

---

## Success Criteria Review

1. **FocusableListTile Focus Indicator**: Testable ✓ — specific visual outcome (2px bottom border, surfaceElevated background) within 200ms.
2. **FocusableSwitch Focus Indicator**: Testable ✓ — specific visual outcome within 200ms.
3. **FocusableSwitch Toggle**: Testable ✓ — switch toggles + sound plays on A/Enter.
4. **FocusableSlider Focus Indicator**: Testable ✓ — but "visible focus indicator (border/highlight)" is vague. Should specify: 2px primaryAccent border around perimeter (to match FocusableSwitch).
5. **FocusableSlider Gamepad Adjustment**: Testable ✓ — but see Issue #7 and #2. The gamepad left/right must work AND the user must be able to leave the slider.
6. **Focus Move Sound**: Testable ✓ — `playFocusMove()` called on focus gain.
7. **Focus Select Sound**: Testable ✓ — `playFocusSelect()` called on activation.
8. **D-pad Navigation Order**: Partially testable ⚠️ — lists controls but doesn't specify the expected order. Should state: Back → English → Chinese → API Key Input → Save → Clear → Volume Slider → Mute Switch → Test Sound → Test Gamepad (top-to-bottom). Note that this also requires registering existing focus nodes (see Issue #3).
9. **Focus Out Animation**: Testable ✓ — focus indicator fades out within 150ms.
10. **No Regressions**: Testable ✓ — all existing functionality continues working.

---

## Recommendations

1. **Standardize animation durations** to use design tokens (`AppAnimationDurations.focusIn`/`focusOut`) consistently across all three new widgets. Do NOT hardcode milliseconds. Optionally add a note about whether the existing `FocusableButton` should be updated to match.

2. **Specify the D-pad navigation resolution for sliders** explicitly: up/down to move focus away, left/right consumed by slider for value adjustment. Document that `FocusableSlider.onKeyEvent` must return `KeyEventResult.handled` for horizontal keys when focused.

3. **Register ALL Settings page focus nodes** with `FocusTraversalService`, not just the 4 new ones. The 6 existing nodes (`_backButtonFocusNode`, `_apiKeyFocusNode`, `_saveKeyFocusNode`, `_clearKeyFocusNode`, `_testSoundFocusNode`, `_testGamepadFocusNode`) must also be registered for correct D-pad navigation.

4. **Make a deliberate decision on the API key TextField**: Either scope it out with explicit documentation, or specify a `FocusableTextField` wrapper (or at minimum, style the existing `TextField`'s focus state with design tokens for the border color).

5. **Document the border style rationale**: Explain why `FocusableSwitch` uses a full 4-sided border while `FocusableListTile`/`FocusableButton` use bottom-only.

6. **Add a `step` parameter to FocusableSlider**: Allow explicit step override or derive from `(max - min) / divisions`.

7. **Enumerate all i18n keys** needed, including accessibility labels for language options.

8. **Specify the expected D-pad tab order** explicitly in criterion 8 to make it objectively testable.

---

## Test Plan Preview

During evaluation, I will test:

1. **Visual focus indicators**: Launch the app, navigate to Settings with keyboard/gamepad, verify each control type shows the correct focus animation (border, background, scale for switch) with correct timing.
2. **D-pad navigation flow**: Tab through all Settings controls in order. Verify no controls are skipped and the order is top-to-bottom.
3. **Slider gamepad interaction**: Focus the volume slider, press left/right to adjust value, press up/down to move focus away. Verify no D-pad "trapping."
4. **Sound feedback**: Verify `playFocusMove()` plays when any control gains focus, `playFocusSelect()` on activation. Test with sound muted.
5. **Focus exit animation**: Move focus away from each control, verify the focus indicator fades out smoothly.
6. **Regression testing**: Verify language switching, API key save/clear, volume adjustment, mute toggle, sound test, and gamepad test buttons all still function.
7. **Memory management**: Navigate away from Settings and back, verify no FocusNode leaks.
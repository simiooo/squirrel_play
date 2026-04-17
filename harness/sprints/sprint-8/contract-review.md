# Contract Review: Sprint 8

## Assessment: APPROVED (with minor suggestions)

## Alignment with Specification

The contract is well-aligned with the spec's Sprint 8 section (spec lines 524-562). The spec calls for:
- Fixing picker button visibility in both ManualAddTab and ScanDirectoryTab ✅
- Ensuring buttons are gamepad-navigable with focus indicators ✅
- Adding icons + text labels for clarity ✅
- Minimum 48x48 touch target ✅
- Consistent `PickerButton` widget for both tabs ✅
- Semantic labels for accessibility ✅

The contract's investigation findings are **accurate and verifiable** against the actual code:

- **ManualAddTab line 162**: `FocusableButton` is used **without** `isPrimary` (defaults to `false`). In `FocusableButton`, when `isPrimary: false` and unfocused: `backgroundColor = Colors.transparent` and `textColor = AppColors.textSecondary` (#B0B0B8). This is genuinely nearly invisible against the dark dialog background (`AppColors.surface` = #1A1A1E). ✅ Correct diagnosis.

- **ScanDirectoryTab line 278**: `FocusableButton` is used **with** `isPrimary: true`. When unfocused: `backgroundColor = Colors.transparent` and `textColor = AppColors.textPrimary` (white). This is *more* visible but still lacks visual boundaries/border. The contract slightly understates this issue — even `isPrimary: true` buttons have a transparent background, so they have no container shape when unfocused. The contract notes "Could be more prominent" which is fair but mild.

- **Root cause analysis**: The contract correctly identifies that `FocusableButton`'s default styling (transparent background for unfocused non-primary buttons) is the root cause. ✅

## Completeness Checklist

- [x] Correctly identifies ManualAddTab visibility issue (transparent background + secondary text color)
- [x] Correctly identifies ScanDirectoryTab issue (no icon, could be more prominent)
- [x] Pinpoints root cause in FocusableButton's `isPrimary: false` styling
- [x] Proposes creating a new `PickerButton` widget
- [x] Specifies icons for both pickers
- [x] Specifies minimum 48x48px touch target
- [x] Requires focus indicators
- [x] Requires semantic labels for accessibility
- [x] Defines measurable acceptance criteria with verification methods
- [x] Lists files to modify and reference files
- [x] Defines clear out-of-scope boundaries
- [x] Maintains gamepad focus nodes from existing code

## Technical Concerns

### 1. PickerButton vs. Fixing FocusableButton (Minor)

The contract proposes a **new** `PickerButton` widget rather than fixing the existing `FocusableButton`. This is a valid approach, but it's worth noting that `FocusableButton` already has an `icon` parameter (line 36) and already has a 48x48 minimum size (line 136). The core problem is only the **unfocused background color** for non-primary buttons. 

Two approaches would work:
- **(A) Create PickerButton**: As proposed — always visible, own styling. Clean separation of concerns.
- **(B) Fix FocusableButton**: Add an `isVisible` or `alwaysVisible` flag that overrides the transparent background.

Approach (A) is reasonable since picker buttons have different UX semantics than action buttons — they should always be visible, not rely on focus state. The contract's approach avoids modifying a widely-used widget and risking regressions. This is the safer choice.

**Verdict**: The proposed approach is sound. No change needed.

### 2. Missing Concern: No Border on FocusableButton's Focused State (Minor)

The current `FocusableButton` adds only a `bottom` border on focus (line 123-130), not a full border. If `PickerButton` is intended to have a "glow/border" focus indicator, the contract should clarify whether it means a full border glow or just a bottom accent like the existing pattern. The success criteria say "glow/border appears" which is vague.

### 3. ScanDirectoryTab is Less Problematic Than Described

The ScanDirectoryTab button uses `isPrimary: true` so it renders white text on transparent background. It's **visible**, just not well-contained. The contract treats both buttons as equally problematic ("Could be more prominent"), which is slightly misleading. The ManualAddTab button is genuinely invisible when unfocused; the ScanDirectoryTab button is visible but unstyled. This distinction matters for prioritization but doesn't block approval.

### 4. No Test Coverage Mentioned

The contract doesn't mention writing widget tests for `PickerButton`. This is an out-of-scope concern for a UI fix sprint, and the existing codebase has no widget tests for `FocusableButton` either. Not blocking, but worth noting.

## Suggestions for Improvement

1. **Clarify focus indicator style**: The success criteria should specify whether the focus indicator should be a full border glow (matching the Steam Big Picture style) or just a bottom accent bar (like existing `FocusableButton`). Given the spec's mention of "focus highlight animation" and "glow/border", I'd recommend a full border for the picker buttons since they need to stand out more than action buttons.

2. **Consider adding a test for PickerButton visibility**: Even a basic widget test that verifies the button renders with a non-transparent background would prevent regressions. This could be added as a stretch goal.

3. **Specify the unfocused background more precisely**: The contract says `AppColors.surface` background when unfocused. On a dialog that already uses `AppColors.surface` as its card/panel color, this could blend in. Consider whether `AppColors.surfaceElevated` (slightly lighter, #2A2A30) might be better for the unfocused state, with `AppColors.surface` for the focused state. This would provide better contrast hierarchy.

4. **The file path display area in ManualAddTab already uses AppColors.surface**: The container showing the selected file path (lines 137-159) uses `color: AppColors.surface`. If the picker button also uses `AppColors.surface`, they'll blend together. The contract's proposed `AppColors.surface` background with `AppColors.surfaceElevated` border should address this, but verify the visual result during implementation.

## Verdict

**APPROVED.** The contract correctly identifies the visibility problem, proposes a sound solution, and defines measurable acceptance criteria. The investigation findings match the actual codebase behavior. The concerns are minor and don't block implementation — they're refinement suggestions for the implementation phase.

The core fix — giving picker buttons a persistent visible background rather than relying on focus-state transparency — directly addresses the user-facing problem and aligns with the spec's requirements.
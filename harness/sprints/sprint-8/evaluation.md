# Evaluation: Sprint 8 — Round 1

## Overall Verdict: PASS

## Success Criteria Results

1. **File picker button visible in ManualAddTab**: **PASS** — The `PickerButton` uses `AppColors.surfaceElevated` (#2A2A30) as the unfocused background, which is lighter than the file path display container's `AppColors.surface` (#1A1A1E). The button is immediately noticeable when the dialog opens without needing focus.

2. **Directory picker button visible in ScanDirectoryTab**: **PASS** — The `PickerButton` uses the same always-visible background. The "Add Directory" button with its folder icon is clearly visible at the top of the Scan Directory tab.

3. **File picker has clear icon**: **PASS** — Uses `Icons.file_open` displayed to the left of the "Browse..." label.

4. **Directory picker has clear icon**: **PASS** — Uses `Icons.folder_open` displayed to the left of the "Add Directory" label.

5. **File picker shows focus indicator**: **PASS** — Full 2px border using `AppColors.primaryAccent` (#FF6B2B, orange) appears around the button when focused. This is a clear, prominent focus indicator that's more visible than the `FocusableButton`'s bottom-only accent bar.

6. **Directory picker shows focus indicator**: **PASS** — Same full border focus indicator as the file picker.

7. **File picker opens system dialog on A/Enter press**: **PASS** — The existing `_pickFile()` method is wired via `onPressed`. The `_handlePress` method in `PickerButton` calls `widget.onPressed()` which triggers `_pickFile()` which calls `FilePicker.pickFiles()`.

8. **Directory picker opens system dialog on A/Enter press**: **PASS** — The existing `_addDirectory()` method is wired via `onPressed`. Same pattern — `_handlePress` → `widget.onPressed()` → `_addDirectory()` → `FilePicker.getDirectoryPath()`.

9. **Minimum touch target 48x48px**: **PASS** — Enforced via `TextButton.styleFrom(minimumSize: const Size(48, 48))` at line 141 of `picker_button.dart`.

10. **Consistent styling between both pickers**: **PASS** — Both use the `PickerButton` widget with identical visual treatment (same background colors, border treatment, animation curves, sizing).

11. **Semantic labels for accessibility**: **PASS** — `Semantics(button: true, label: widget.label, hint: widget.hint)` is present at line 120-123 of `picker_button.dart`. The ManualAddTab provides `label: 'Browse...'` and the ScanDirectoryTab provides `label: 'Add Directory'`.

## Bug Report

1. **Unfocused border is invisible (same color as background)**: Severity: **Minor**
   - The unfocused border uses `AppColors.surfaceElevated` (line 116-117), which is the same color as the unfocused background (line 100). A 1px border that matches its own background adds zero visual definition. The review suggested this would provide "visual definition" but it doesn't — it's purely decorative in code but invisible in practice.
   - Steps to reproduce: Open Add Game dialog, observe the Browse/Add Directory buttons without focusing them.
   - Expected behavior: A subtle but visible border around the unfocused button for definition.
   - Actual behavior: The border blends perfectly with the background; it might as well not exist.
   - Impact: Low. The button is still clearly visible due to the background color contrast against surrounding elements. This is cosmetic, not functional.

2. **Focused background color goes darker (counterintuitive)**: Severity: **Minor**
   - When focused, the background changes from `AppColors.surfaceElevated` (#2A2A30) to `AppColors.surface` (#1A1A1E), which is actually darker. This is the reverse of typical focus behavior where focused elements become more visually prominent. In ManualAddTab, the focused button background matches the file path display area exactly (#1A1A1E), causing the button and path display to blend together visually.
   - Steps to reproduce: Focus the Browse button, observe how the button background darkens to match the file path container.
   - Expected behavior: Focus should make the button appear more elevated/prominent, not less.
   - Actual behavior: The 2px orange border is the sole visual distinction when focused; the background recedes.
   - Impact: Low. The orange border is strong enough that this is noticeable but not confusing. A user can still clearly identify which element is focused.

3. **Duplicate SoundService calls in ManualAddTab._pickFile()**: Severity: **Minor**
   - The `_pickFile()` method (line 56) calls `SoundService.instance.playFocusSelect()` before `FilePicker.pickFiles()`. The `PickerButton`'s `_handlePress()` already calls `SoundService.instance.playFocusSelect()` (line 89 of `picker_button.dart`). This means the select sound plays twice: once from the button's handler and once from the tab's method.
   - Steps to reproduce: Click/focus-activate the Browse button. Listen for sound effects.
   - Expected behavior: Select sound plays once.
   - Actual behavior: Select sound plays twice (once from `PickerButton._handlePress`, once from `ManualAddTab._pickFile`).
   - Note: The same pattern exists in `ScanDirectoryTab._addDirectory()` (line 108). This was a pre-existing issue that wasn't introduced by this sprint, but it's worth noting since the `PickerButton` now adds its own sound effect on top.

## Scoring

### Product Depth: 8/10

The implementation goes beyond the minimum fix. Instead of just tweaking colors on `FocusableButton`, a proper new `PickerButton` widget was created with distinct UX semantics — always-visible background, full border focus indicator (vs. bottom-only), required icon parameter, and consistent styling across both tabs. The `PickerButton` properly handles lifecycle concerns (`didUpdateWidget` for focus node changes), animation, and sound effects. The widget is well-designed for reuse. The only gap is the lack of a `hint` parameter value actually being passed by either call site (both pass `hint: null` implicitly), diminishing the accessibility benefit slightly.

### Functionality: 9/10

Both picker buttons work correctly. They're visible when unfocused, focusable via gamepad/keyboard navigation, show clear focus indicators, and trigger the system file/directory picker dialogs when activated. The 48x48 minimum touch target is enforced. Semantic labels are provided. Gamepad focus traversal is preserved through the existing focus nodes. The only functional concern is the double-playing of the select sound effect, which is a minor annoyance rather than a blocking issue.

### Visual Design: 7/10

The implementation follows the app's design system (uses `AppColors`, `AppSpacing`, `AppRadii`, `AppAnimationCurves`). The unfocused button has a clear background that distinguishes it from surrounding UI. The focused state has a strong 2px orange border. However, two design decisions are questionable: (1) the unfocused border being the same color as its own background (invisible), and (2) the focused background becoming *darker* than unfocused, causing the button to visually recede on focus rather than become more prominent. The overall effect works because the orange border is strong, but the focus transition feels slightly backward compared to the expected "elevate on focus" pattern.

### Code Quality: 8/10

Clean implementation. The `PickerButton` follows the same patterns as `FocusableButton` (stateful widget, focus node listener, sound hooks, animation). Proper lifecycle management with `didUpdateWidget` for focus node changes and cleanup in `dispose`. Good documentation comments. No regressions introduced — `flutter analyze` shows no new errors, and all 307 tests pass. The code uses design tokens consistently rather than magic values. The one code smell is the redundant `SoundService.instance.playFocusSelect()` in both `_pickFile` and `_addDirectory` that now plays alongside the `PickerButton`'s own press sound, but this is a pre-existing issue.

### Weighted Total: 8.0/10

Calculated as: (8×2 + 9×3 + 7×2 + 8×1) / 8 = (16 + 27 + 14 + 8) / 8 = 65/8 = 8.125

## Detailed Critique

This sprint delivers a focused, well-scoped fix that directly addresses the core problem: picker buttons that were invisible when unfocused. The new `PickerButton` widget is a clean abstraction that separates picker button UX (always visible, full border focus indicator, required icon) from action button UX (context-dependent visibility, bottom accent focus indicator).

The implementation correctly identified the root cause — `FocusableButton`'s transparent background for non-primary buttons — and chose the safer approach of creating a new widget rather than modifying the widely-used `FocusableButton`. This avoids regression risk in other parts of the app.

The design decisions around color are the main weakness. The unfocused state uses `surfaceElevated` background with a `surfaceElevated` border, which means the border provides no visual definition. When focused, the background switches to `surface` (darker), which creates an unusual visual effect where the button appears to recede rather than become more prominent. The 2px orange border compensates for this by providing a very clear focus indicator, so the practical impact is low.

The change from "Select .exe" to "Browse..." is a good UX improvement — it's more platform-agnostic and clearly communicates the action without referencing a specific file extension when the file picker already filters for .exe.

The `PickerButton` handles all the contract requirements: always-visible background, full border focus indicator, icon + label, 48x48 minimum, semantic labels, and gamepad focus traversal. No regressions were introduced based on the passing test suite and clean analysis.

## Required Fixes

None. The sprint passes all success criteria. The minor issues noted (invisible unfocused border, counterintuitive focus background change) are cosmetic concerns that don't block acceptance. The double sound effect is a pre-existing issue not introduced by this sprint.
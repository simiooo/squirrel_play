# Contract Review: Sprint 2

## Assessment: APPROVED

## Scope Coverage

The contract is tightly aligned with Sprint 2's scope in the spec: fix directional focus traversal to `PickerButton` widgets in the Manual Add and Scan Directory tabs. It correctly identifies the root cause (duplicate focusable nodes from the outer `Focus` widget) and proposes a minimal, surgical fix.

The contract also includes `FocusableButton` in the fix, which is a justified defensive extension. The spec's acceptance criteria require full traversal through the Add Game button (a `FocusableButton`) in the Manual Add tab. If `FocusableButton` shares the same outer-`Focus` architecture — which it does — leaving it unfixed would risk breaking traversal at that node. This is a reasonable scope adjustment that serves the sprint's goals.

## Strengths

1. **Correct root cause diagnosis**: The duplicate focusable node explanation is accurate. Both `PickerButton` and `FocusableButton` wrap an inner `TextButton` (with the real `focusNode`) inside an outer `Focus` widget (for key-event interception). Without `canRequestFocus: false`, `FocusScope.traversalDescendants` sees two nodes per button, confusing directional traversal.
2. **Minimal blast radius**: Only two properties added (`canRequestFocus: false` on two widgets). Low regression risk.
3. **Comprehensive verification criteria**: The contract includes 9 specific success criteria covering code review, interactive testing of both tabs, activation behavior, visual feedback, tests, and analysis.
4. **Clear boundaries**: Explicitly excludes broader refactoring, i18n, `FocusTraversalService` changes, and other widgets.

## Gaps, Risks, and Edge Cases

### 1. `canRequestFocus: false` — Sufficient, but watch semantics
Adding `canRequestFocus: false` to the outer `Focus` widget is the correct and sufficient fix for traversal. The outer `Focus` will still intercept key events via `onKeyEvent` (because `descendantsAreFocusable` defaults to `true`), and the inner `TextButton`'s `focusNode` remains the sole traversal target. No additional changes are needed.

**Edge case — semantics**: The outer `Semantics(widget: button: true)` wrapper already provides the correct semantic role. The inner `Focus` widget's `includeSemantics` defaults to `true`, but since `Semantics` is the ancestor, it should dominate. Verify during interactive testing that screen readers still announce the buttons correctly.

### 2. Focus return after dialog close (implicit but untested)
When `GamepadFileBrowser` closes, focus should return to the `PickerButton` that triggered it. Because the inner `TextButton` owns the real `focusNode`, Flutter's default focus restoration should return to the correct node. The contract does not explicitly test this. **Recommendation**: Verify during interactive testing that after dismissing the file browser (via B/Escape or file selection), focus returns to the Browse/Add Directory button with correct visual feedback.

### 3. Empty-state traversal in Scan Directory tab
The contract mentions the directory list "(if directories exist)" but does not explicitly define the traversal path when the list is empty. **Recommendation**: Confirm during verification that when no directories exist, D-pad Down from the Add Directory button skips directly to the Start Scan button without getting lost.

### 4. No automated test coverage for the fixed widgets
The contract correctly notes that no existing tests cover `PickerButton`, and new tests are out of scope. This is acceptable per the spec, but it means the fix relies entirely on interactive testing. The contract mitigates this with thorough manual verification criteria.

### 5. Other focusable widgets
The contract limits scope to `PickerButton` and `FocusableButton`. Other widgets in the family (`FocusableListTile`, `FocusableSwitch`, `FocusableSlider`, `FocusableTextField`) may share the same pattern but are out of scope. This is appropriate — only fix what's broken — but be aware that if `FocusableTextField` has the same double-node issue, traversal in the Manual Add tab could still misbehave. The spec does not flag `FocusableTextField` as problematic, so this is a minor risk.

## Suggested Changes

None required. The contract is ready to proceed as written.

Minor additions the Generator may optionally include in handoff notes:
- Document the focus-return-after-dialog-close verification result.
- Document the empty-directory-list traversal path in Scan Directory tab.

## Test Plan Preview

During evaluation, I will verify:
1. **Code review**: Confirm `canRequestFocus: false` is present on the outer `Focus` in both `picker_button.dart` and `focusable_button.dart`.
2. **Manual Add tab**: D-pad Down from Name field → Browse button → Add Game button. D-pad Up reverses. Focus borders visible at each step.
3. **Scan Directory tab**: D-pad Down from top → Add Directory button → directory list (if populated) → Start Scan button. D-pad Up reverses.
4. **Activation**: A/Enter on Browse opens file browser; A/Enter on Add Game triggers submit.
5. **Focus return**: After closing the file browser, focus returns to the originating `PickerButton`.
6. **Regression**: `flutter analyze` and `flutter test` pass with zero issues.

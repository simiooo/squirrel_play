# Contract Review: Sprint 2

## Assessment: CHANGES_REQUESTED

The contract is comprehensive and well-structured, covering all Sprint 2 deliverables from the spec. However, there are several gaps and ambiguities that need to be addressed before implementation begins. The most critical issues are: (1) insufficient detail on how the focus activation fix will work, (2) missing specification for focus management during page transitions and dialogs, and (3) a potential conflict in the GameCard's `isFocused` parameter design.

---

## Scope Coverage

### Alignment with Spec Sprint 2 Deliverables

| Spec Deliverable | Contract Coverage | Assessment |
|---|---|---|
| Full gamepad focus navigation system | §2.5 Focus Traversal Service | ✅ Covered |
| Focus traversal across rows, grids, top bar/content | §2.5 registerRow/registerGrid | ✅ Covered |
| Animated focus effects on all interactive elements | §2.3 FocusableButton, §2.4 GameCard | ✅ Covered |
| Sound effect hooks integrated | §2.2 Sound Service | ✅ Covered |
| Top bar fully functional | §2.6 Top Bar Refactor | ✅ Covered |
| All top bar buttons gamepad-navigable | §2.6 with FocusableButton | ✅ Covered |
| Reusable GameCard widget | §2.4 GameCard | ✅ Covered |
| Reusable FocusableButton widget | §2.3 FocusableButton | ✅ Covered |
| Page navigation between Home and Library | §2.8 Page Navigation | ✅ Covered |
| Keyboard fallback for all gamepad actions | §2.9 Keyboard Fallback | ✅ Covered |

**Verdict**: All spec deliverables are covered. No missing deliverables.

### Sprint 1 Fixes (§2.1)

All 5 Sprint 1 issues are correctly identified with specific fixes:

1. **Dead code: Unused `AppRouter` class** — ✅ Correctly identified. Remove unused class.
2. **Dead code: `AppShellWithNavigation` widget** — ✅ Correctly identified. Remove lines 80-107.
3. **Code generators in wrong section** — ✅ Correctly identified. Move to dev_dependencies.
4. **Missing 120-char line length rule** — ✅ Correctly identified. Add to analysis_options.yaml.
5. **`GamepadCubit` registered as factory** — ⚠️ **Issue**: The current `di.dart` already shows `registerSingleton<GamepadCubit>` on line 23. This fix may have already been applied. The contract should verify the current state before claiming this as a fix, or clarify that this is a verification criterion rather than a code change.

---

## Success Criteria Review

### §3.1 Sprint 1 Fixes — Adequate

All 5 criteria are specific and testable. The grep/cat commands for verification are good.

- **Concern**: Criterion 5 ("Clean analyze: `flutter analyze` passes with no issues") may be too strict if the audioplayers package introduces new warnings. Should specify "no errors or warnings introduced by Sprint 2 changes."

### §3.2 Sound Service — Mostly Adequate

- **Criterion "Audio playback works"**: "SoundService plays actual audio files (test with sample WAV)" — This requires sample WAV files to exist. The contract's handoff notes say sound files are optional. How is this criterion tested without sound files? Should specify: "When sound files are present, audio plays; when absent, app logs gracefully without errors."
- **Criterion "Volume control"**: "Changing volume affects playback loudness" — This is hard to test without actual audio output. Should specify a code-level verification (e.g., volume setter propagates to AudioPlayer instances).

### §3.3 FocusableButton Widget — Adequate

All 5 criteria are specific and testable. The animation timing criterion correctly suggests code inspection as the primary verification method.

### §3.4 GameCard Widget — Adequate with one concern

- **Criterion "Aspect ratio"**: "Card maintains 2:3 ratio at all breakpoints" — Good, but should specify how to verify (Flutter Inspector or code inspection of `AspectRatio` widget).
- **Criterion "Glow/border effect"**: "Focused card shows accent color glow or border" — The word "or" is ambiguous. The design spec says "accent border glow appears" — it should be both glow AND border, not either/or.

### §3.5 Focus Traversal — Adequate with concerns

- **Criterion "Enter activation"**: "Pressing Enter triggers button/card action (not just logs)" — This is the most critical criterion. The Sprint 1 evaluation specifically flagged that `_activateCurrentNode()` uses `consumeKeyboardToken()` which may not properly trigger button callbacks. The contract says this will be fixed but doesn't specify HOW. This needs a concrete technical approach.
- **Criterion "Escape back"**: "Pressing Escape navigates back or closes dialog" — "or" is ambiguous. Should specify: Escape closes the topmost dialog if one is open, otherwise navigates to the previous page.

### §3.6 Top Bar Functionality — Adequate with one concern

- **Criterion "Rescan button"**: "Shows placeholder snackbar or dialog" — "or" is ambiguous. Pick one. A snackbar is simpler and more appropriate for a placeholder action.

### §3.7 Page Navigation — Adequate

- **Criterion "Home page demo"**: "Shows row of 3-5 focusable game cards" — Should specify what data these cards display. Are they hardcoded mock data? What titles do they show?
- **Criterion "Library page demo"**: "Shows 2×3 grid of focusable game cards" — Same concern about mock data.

### §3.8 Keyboard Fallback — Adequate

All 3 criteria are clear and testable.

---

## Gaps and Concerns

### Critical Issues

#### 1. Focus Activation Mechanism Not Specified (Critical)

The Sprint 1 evaluation explicitly flagged that `_activateCurrentNode()` uses `consumeKeyboardToken()` which may not properly trigger button `onPressed` callbacks. The contract says "fix Sprint 1 concern" and "properly trigger button onPressed callbacks" but provides no technical detail on HOW this will be fixed.

**Suggested fix**: Specify the technical approach. Options include:
- Using `Actions.invoke()` on the focused node's context to trigger the `ActivateAction`
- Having each `FocusableButton` and `GameCard` register an `ActivateAction` via `Actions()` widget
- Using `FocusNode.onKeyEvent` to intercept Enter and call the widget's callback directly
- Having the focus traversal service maintain a callback map (`Map<FocusNode, VoidCallback>`) that widgets register with

The contract should specify which approach will be used so the evaluator can verify it works.

#### 2. Focus Management During Page Transitions Not Specified (Critical)

When the user navigates from Home to Library (or vice versa), what happens to focus? The contract doesn't specify:
- Does focus reset to the first focusable element on the new page?
- Does focus return to the previously focused element when navigating back?
- How does the `FocusTraversalService` handle route changes?

**Suggested fix**: Add a specification for focus behavior during navigation:
- On page enter: Focus the first focusable element on the new page
- On page exit: Save current focus state (for potential back navigation)
- The `FocusTraversalService` should be notified of route changes to update its node registry

#### 3. Focus Trapping in Dialogs Not Specified (Critical)

When the Add Game dialog is open, focus should be trapped within the dialog — the user shouldn't be able to navigate focus to elements behind the dialog. This is essential for gamepad usability. The contract doesn't address this.

**Suggested fix**: Add a specification for dialog focus management:
- When a dialog opens, focus moves to the first focusable element inside the dialog
- Focus traversal within the dialog is limited to dialog elements only
- When the dialog closes, focus returns to the element that opened it
- Escape key closes the dialog (not navigates back)

#### 4. GameCard `isFocused` Parameter Conflict (Major)

The contract specifies `isFocused` as an optional parameter for "external control" of the GameCard's focus state. However, the card also has a `focusNode` parameter. This creates a potential conflict: if focus state comes from the `FocusNode`, what does `isFocused` do? If `isFocused` overrides the `FocusNode`, this breaks the focus traversal system. If `isFocused` is ignored when a `FocusNode` is provided, it's confusing API design.

**Suggested fix**: Remove the `isFocused` parameter. Focus state should come exclusively from the `FocusNode`. If there's a need for a card to appear focused without actual keyboard focus (e.g., for a "selected" state), that should be a separate `isSelected` parameter with different visual treatment.

### Moderate Issues

#### 5. Demo Data Not Specified (Moderate)

The contract says "3-5 cards" on home page and "2×3 grid" on library page but doesn't specify:
- What titles the mock cards display
- Whether they use placeholder images or gradient backgrounds
- Whether they're hardcoded in the widget or come from a mock data source
- Whether the home page row and library page grid show the same games or different ones

**Suggested fix**: Specify that mock game data should be defined in a simple data class or constant list (e.g., `MockGames.games`) with 5-6 entries containing title, placeholder color, and optional cover image URL. Both pages should use the same mock data source.

#### 6. Sound Debouncing Not Addressed (Moderate)

When the user holds down an arrow key, focus moves rapidly between elements. Should `playFocusMove()` play for every focus change, or should it be debounced/throttled? Playing a sound 10 times per second would be unpleasant.

**Suggested fix**: Add a specification for sound debouncing:
- `playFocusMove()` should have a minimum interval of 80ms between plays (debounce)
- `playFocusSelect()` should play immediately (no debounce)
- `playFocusBack()` should play immediately (no debounce)

#### 7. `FocusableButton.isPrimary` Not Fully Specified (Moderate)

The contract mentions `isPrimary` as an optional parameter for "accent styling" but doesn't specify what visual difference it makes. Does it change the background color? The text color? The underline color? The size?

**Suggested fix**: Specify that `isPrimary`:
- Uses `AppColors.primaryAccent` as the background color when focused (instead of `surfaceElevated`)
- Uses `AppColors.textPrimary` as the text color when unfocused (instead of `textSecondary`)
- Maintains the same 2px accent underline when focused
- Maintains the same 48×48px minimum size

#### 8. Focus History Stack Depth Not Specified (Moderate)

The contract mentions a "focus history stack for back navigation" but doesn't specify:
- Maximum stack depth (to prevent memory leaks)
- When the stack is cleared (e.g., on page navigation)
- Whether the stack persists across page transitions

**Suggested fix**: Specify that:
- The focus history stack has a maximum depth of 10 entries
- The stack is cleared on page navigation (not within-page back navigation)
- `goBack()` pops the most recent entry and requests focus on that node

#### 9. Add Game Dialog Placeholder Content Not Specified (Minor)

The contract says "Two tabs: 'Manual Add' and 'Scan Directory' (placeholder content)" but doesn't specify what the placeholder content looks like. Should it be:
- Empty containers with just the tab headers?
- Text saying "Coming in Sprint 3"?
- A mock form with disabled fields?

**Suggested fix**: Specify that each tab should contain:
- A centered text message explaining the feature is coming soon
- The text should use a localized string (add to ARB files)
- The tab switching should work (gamepad left/right) even though the content is placeholder

#### 10. Rescan Button Behavior Not Specified (Minor)

The contract says "triggers rescan action (placeholder for now)" but doesn't specify what the placeholder behavior is. A debug print? A snackbar? A dialog?

**Suggested fix**: Specify that the Rescan button shows a `SnackBar` with text "Rescan feature coming soon" (localized). This is consistent with the placeholder pattern and provides visible feedback.

### Minor Issues

#### 11. `audioplayers` Package Version

The contract specifies `audioplayers: ^6.0.0`. This should be verified as the latest compatible version. The `audioplayers` package has had significant API changes between major versions. The contract should specify which API to use (e.g., `AudioPlayer.play()` vs the older `audioplayers` API).

#### 12. Sound Service Initialization Timing

The contract says "Preload sound files on initialization (async, non-blocking)" but doesn't specify when in the app lifecycle this happens. Should it be in `main()` before `runApp()`? In `configureDependencies()`? On first sound play?

**Suggested fix**: Specify that `SoundService.initialize()` is called in `configureDependencies()` (alongside other service initialization), and individual sounds are loaded lazily on first play (not preloaded all at once, which could cause startup delays).

#### 13. Missing Localization Keys

The contract adds 6 new localization keys but doesn't include keys for:
- Rescan placeholder message ("Rescan feature coming soon")
- Add Game dialog placeholder text ("This feature will be available in a future update")
- Empty state "Add Game" CTA button text

**Suggested fix**: Add these keys to §2.10.

#### 14. No Specification for Focus Sound on Page Transition

The contract specifies `playPageTransition()` for navigation between pages, but doesn't specify where this call is made. Is it in the `FocusTraversalService`? In the GoRouter navigation callback? In the button's `onPressed` handler?

**Suggested fix**: Specify that `playPageTransition()` is called in the navigation callback (e.g., when "Game Library" button is pressed, before `context.go('/library')`).

---

## Test Plan Preview

When evaluating Sprint 2, I plan to test:

1. **Sprint 1 Fixes**: Run `flutter analyze`, check `di.dart` for singleton registration, verify dead code removal, check `analysis_options.yaml` for 120-char rule.

2. **Sound Service**: Launch the app with and without sound files. Verify no errors in either case. Check debug logs for sound events.

3. **FocusableButton**: Navigate to top bar buttons with arrow keys. Verify focus highlight (accent underline + elevated background). Verify focus animation timing in code. Press Enter to activate.

4. **GameCard**: Navigate between cards with arrow keys. Verify scale animation (1.0 → 1.08). Verify glow/border effect. Verify 2:3 aspect ratio.

5. **Focus Traversal**: Test all 4 directions with arrow keys. Test top bar → content transition (Down arrow). Test content → top bar transition (Up arrow). Test row navigation (left/right within a card row). Test grid navigation (all 4 directions in library grid). Test Enter activation on buttons and cards. Test Escape for back/close.

6. **Top Bar**: Press "Add Game" → verify dialog opens. Press "Game Library" → verify navigation to /library. Press "Rescan" → verify placeholder feedback. Verify time display updates.

7. **Add Game Dialog**: Open dialog. Verify two tabs. Switch tabs with left/right arrows. Close with Escape. Verify dialog focus trapping.

8. **Page Navigation**: Navigate between Home and Library. Verify focus resets to first element on new page. Verify page transition sound.

9. **Keyboard Fallback**: Test all arrow keys, Enter, Escape. Verify they work identically to gamepad actions.

10. **Edge Cases**: Rapid arrow key presses (focus debouncing). Navigate with no focusable elements. Open dialog and try to navigate outside it. Navigate to empty state page.

---

## Suggested Changes

### Must-Fix Before Implementation

1. **Specify the focus activation fix approach**: Add a technical specification for how `_activateCurrentNode()` will properly trigger widget callbacks. Recommend using `Actions.invoke()` or a callback registration pattern.

2. **Add focus management specification for page transitions**: Specify that focus resets to the first focusable element on the new page when navigating, and that the `FocusTraversalService` is notified of route changes.

3. **Add focus trapping specification for dialogs**: Specify that when a dialog is open, focus is trapped within the dialog and Escape closes it.

4. **Remove or clarify `isFocused` parameter on GameCard**: Either remove it (recommended) or clearly specify that it's independent of `FocusNode`-based focus and used only for a "selected" visual state.

### Should-Fix Before Implementation

5. **Specify mock data structure**: Add a `MockGames` constant or data class with 5-6 entries for demo cards.

6. **Add sound debouncing specification**: Specify minimum intervals for `playFocusMove()`.

7. **Specify `isPrimary` visual behavior**: Detail what visual changes `isPrimary` triggers on `FocusableButton`.

8. **Specify focus history stack constraints**: Maximum depth, clearing behavior.

### Nice-to-Have Improvements

9. **Specify Add Game dialog placeholder content**: What text/content appears in each tab.

10. **Specify Rescan button placeholder behavior**: SnackBar with localized message.

11. **Add missing localization keys**: Rescan placeholder, dialog placeholder text, empty state CTA.

12. **Clarify sound initialization timing**: Lazy loading vs. preloading.

13. **Specify where `playPageTransition()` is called**: In navigation callbacks.

---

## Summary

The Sprint 2 contract is well-organized and covers all deliverables from the spec. The Sprint 1 fixes are correctly identified. The success criteria are mostly testable. However, there are 4 critical gaps that must be addressed before implementation:

1. **Focus activation mechanism** — The most important fix from Sprint 1 lacks a technical specification
2. **Focus management during page transitions** — Essential for gamepad usability, completely missing
3. **Focus trapping in dialogs** — Critical for gamepad UX, completely missing
4. **GameCard `isFocused` parameter conflict** — API design issue that could cause bugs

These are not minor polish items — they are fundamental interaction patterns that affect the entire gamepad navigation experience. Without clear specifications for these, the implementation is likely to produce a focus system that doesn't work correctly in real usage scenarios.

I recommend the Generator revise the contract to address the 4 must-fix items and as many should-fix items as practical, then resubmit for re-review.
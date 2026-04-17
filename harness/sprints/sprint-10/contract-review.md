# Contract Review: Sprint 10

## Assessment: APPROVED (with minor observations)

## Scope Coverage

The contract correctly identifies the core problem and proposes a well-scoped fix. The scope aligns precisely with the spec's Sprint 10 definition — refactor to `ShellRoute` so `TopBar` persists across navigation, eliminating timer resets and state loss on page changes.

The contract correctly bounds the scope by explicitly calling out what is out-of-scope (Sprint 11 timer logic changes, visual changes, new routes, dialog behavior changes). This is appropriate and prevents scope creep.

## Correctness of Architecture Analysis

**The contract correctly identifies the current architecture issue.** Verified against the actual codebase:

1. **Each route independently wraps content in `AppShell`** — Confirmed. Lines 51, 92, 123 of `router.dart` each create a new `AppShell(body: ...)` in their `pageBuilder`.
2. **`AppShell` is a `StatefulWidget` containing `TopBar`** — Confirmed. `AppShell` (line 14 of `app_shell.dart`) is `StatefulWidget`, and its `build` method (line 44) renders `const TopBar()` as the first child in a `Column`.
3. **Every navigation disposes old `AppShell`/`TopBar` and creates new instances** — Confirmed. Since each route creates its own `AppShell`, navigation between routes causes disposal of the old `AppShell` (and its `TopBar`) and creation of a new one.
4. **`TopBar`'s `Timer` gets cancelled on dispose and recreated on `initState`** — Confirmed. Lines 53-56 of `top_bar.dart` create `Timer.periodic` in `initState`, and line 61 cancels it in `dispose`.

The analysis is accurate and complete.

## ShellRoute Solution Design

The proposed `ShellRoute` structure is well-designed:

```dart
ShellRoute(
  builder: (context, state, child) {
    return Scaffold(
      body: Column(
        children: [
          const TopBar(),  // Persistent across navigation
          Expanded(child: child),  // Page content changes here
        ],
      ),
    );
  },
  routes: [...]
)
```

**Observations:**

1. **Focus management integration needs careful handling.** Currently, `AppShell`'s `_AppShellState` calls `FocusTraversalService.instance.setContentContainer(_contentFocusNode)` in `initState`. After the refactor, `AppShell` will be simplified, but the content area Focus node still needs to be set. The contract's step 5 acknowledges this, but doesn't specify exactly where `setContentContainer` will be called. The ShellRoute builder runs persistently, so there must be a widget inside the `Expanded(child: child)` subtree that registers the content container. This could be handled by keeping a minimal `AppShell` that wraps just the content area with `Focus` + gradient — which is what the contract proposes. This is fine as long as it's clear that `AppShell` must still register `_contentFocusNode` with the service.

2. **`_FocusManagementNavigatorObserver` placement.** Currently, this observer is on the root `GoRouter`. With `ShellRoute`, the shell creates a new nested `Navigator`. The observer needs to apply to the correct navigator — the shell's nested navigator (for page transitions within the shell), not just the root. If it remains only on the root `GoRouter`, it won't detect navigation within the `ShellRoute`. This is a **potential issue** that should be explicitly addressed in implementation. GoRouter 14.x's `ShellRoute` accepts an `observers` parameter that should be used to maintain focus management for in-shell navigation.

3. **`rootNavigatorKey` consideration.** The contract doesn't mention this, but the existing `AppRouter` defines `rootNavigatorKey`. With `ShellRoute`, the shell's nested navigator gets its own key. This is fine for the current routes, but dialogs (`showDialog`) should use the root navigator. The `AddGameDialog` already uses `showDialog()` which by default uses the root navigator overlay, so this should work correctly. The contract correctly identifies this is not a concern.

4. **TopBar's `_buttonFocusNodes` registration.** Currently, `TopBar` registers its focus nodes via `FocusTraversalService.instance.registerTopBarNode()` in `initState` and unregisters in `dispose`. With the ShellRoute refactor, these nodes survive navigation, which is exactly what we want. However, note that `clearAllRegistrations()` on line 188 of `focus_traversal.dart` already has a comment: `_topBarNodes is NOT cleared as the top bar persists across navigation`. This is a happy coincidence — the current code already anticipates the refactored behavior. No change needed, but worth noting.

## Page Transitions Preservation

The contract specifies keeping `CustomTransitionPage` with fade + slide animations on individual routes, with specific durations (300ms enter, 200ms exit) and direction-specific slides. Looking at the current implementation:

- Home (`/`): slides from bottom (`Offset(0.0, 0.05)`) + fade
- Library (`/library`): slides from right (`Offset(0.05, 0.0)`) + fade
- Settings (`/settings`): slides from bottom (`Offset(0.0, 0.05)`) + fade

The contract correctly preserves these per-route transition differences. With `ShellRoute`, the child routes' `pageBuilder` will continue to work as expected — the shell wrapper stays in place while child transitions animate within it.

**One concern:** With `ShellRoute`, the page transitions animate the `child` content area only, not the entire page including the `TopBar`. This is actually the _correct_ behavior for the persistent TopBar pattern (you don't want the TopBar animating). But it's a subtle visual change — previously the whole page (including TopBar) would fade+slide. The contract should acknowledge this as an intentional change. Currently it says "Preserve Page Transitions" which could be misinterpreted as "make it look exactly the same." The TopBar will now be static while only the content area transitions. This is arguably better UX, but it is a behavioral change worth documenting.

## Acceptance Criteria Review

| Criterion | Assessment |
|-----------|------------|
| 1. TopBar persists across navigation | **Adequate** — Clear and testable. Could add: "verify via debug print in initState/dispose showing TopBar is not disposed on navigation" for objectivity. |
| 2. Timer continues running during navigation | **Adequate** — "Timer should update every minute consistently regardless of page changes" is testable. |
| 3. Page transitions work correctly | **Adequate** — But note the subtle change: TopBar is now static during transitions (content-only animation). |
| 4. Back navigation works | **Adequate** — Clear and testable. |
| 5. Deep links work | **Adequate** — Testing `/library` and `/settings` directly is specific. |
| 6. Add Game dialog works | **Adequate** — Clear and testable. |
| 7. Focus management preserved | **Adequate** — Gamepad/keyboard focus should reset on page change, TopBar buttons remain focusable. |
| 8. All existing routes functional | **Adequate** — Simple pass/fail. |

**Missing criterion:** No criterion for **existing tests passing**. The Definition of Done includes this, but it should be in the success criteria as well to ensure automated verification.

**Missing criterion:** No criterion for **`FocusTraversalService.setContentContainer()` still working** after AppShell is modified. Focus management is called out in criterion 7, but the specific mechanism (content focus node registration) is a critical wiring detail that could break silently.

## Suggested Changes

1. **Add explicit note about transition behavior change:** Acknowledge that page transitions will now animate content only (not TopBar). This is the intended outcome of ShellRoute but should be documented so it's not treated as a regression.

2. **Add `NavigatorObserver` to `ShellRoute`:** The `_FocusManagementNavigatorObserver` currently lives on the root `GoRouter`. Navigation within the `ShellRoute` uses a nested `Navigator`, and the root observer won't fire for these transitions. Either move the observer to `ShellRoute`'s `observers` parameter, or add it there as well. This is critical — without it, focus will NOT be reset when navigating between pages within the shell, which would violate criterion 7.

3. **Add a success criterion for existing tests passing.** The DoD mentions it, but it should be a formal criterion.

4. **Clarify `setContentContainer` placement.** Since `AppShell` is being simplified, specify where the content Focus wrapper lives. The simplest approach: keep the `Focus` + `gradient Container` wrapper in `AppShell` (now just the content area wrapper), and it continues to register `_contentFocusNode`.

5. **Consider `BlocProvider` placement.** Currently the home route wraps its page in a `BlocProvider<HomeBloc>` inside `AppShell`. With ShellRoute, this stays inside the child route's `pageBuilder`, which is correct. Just confirm no BlocProviders accidentally move into the shell builder.

## Test Plan Preview

1. **Timer persistence test:** Start app, note the clock time, navigate to `/library`, wait 1+ minutes, verify clock updated (no "jump" or reset back to initial time on navigation).
2. **TopBar instance persistence:** Add temporary `debugPrint` in `TopBar`'s `initState`/`dispose`. Navigate between all pages. Verify `initState` fires only once and `dispose` never fires.
3. **Page transitions:** Navigate between all three pages. Verify fade+slide animations on content area. Verify TopBar stays fixed.
4. **Back navigation:** From `/library` → press Escape → verify returns to `/`. From `/settings` → press Escape → verify returns to `/`.
5. **Deep links:** Navigate directly to `/library` and `/settings`. Verify TopBar is visible and content displays correctly.
6. **Add Game dialog:** Click "Add Game" button. Verify dialog appears as overlay. Close dialog. Verify TopBar still present and content unchanged.
7. **Focus management:** Tab/gamepad navigate through TopBar buttons. Navigate down to content. Navigate back up to TopBar. Verify focus moves correctly.
8. **Existing tests:** `flutter test` — all should pass.
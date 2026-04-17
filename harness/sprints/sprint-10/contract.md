# Sprint Contract: Refactor to ShellRoute for Persistent TopBar

## Scope
Refactor the GoRouter configuration to use `ShellRoute` so that the TopBar remains a single persistent instance during navigation. This fixes the issue where the TopBar is recreated on every page change, causing its internal Timer to be cancelled and restarted, which disrupts the clock display and wastes resources.

### Current Architecture Issue
- Each route (`/`, `/library`, `/settings`) independently wraps content in `AppShell`
- `AppShell` is a `StatefulWidget` containing `TopBar`
- Every navigation disposes the old `AppShell`/`TopBar` and creates new instances
- `TopBar`'s `Timer` (updates time every minute) gets cancelled on dispose and recreated on initState
- This causes: timer reset on navigation, unnecessary widget rebuilds, loss of focus state in TopBar

### Target Architecture
- Use `ShellRoute` as a wrapper around all page routes
- `TopBar` lives in the ShellRoute's builder function, outside the page content
- Page content (the `child` parameter) changes during navigation, but `TopBar` persists
- `TopBar`'s `StatefulWidget` state (including Timer) survives navigation

## Implementation Plan

### 1. Refactor `router.dart` to use ShellRoute
- Wrap existing routes in a `ShellRoute` 
- Move `TopBar` into the ShellRoute's `builder` function
- Keep `AppShell` for the scaffold structure but remove `TopBar` from it
- Ensure page transitions (fade + slide) still work via `pageBuilder` on child routes

### 2. Update `AppShell` widget
- Remove `TopBar` from `AppShell` - it will now only contain the body content area
- Keep the scaffold background, gradient, and focus management wiring
- `AppShell` becomes a simpler wrapper for page content only

### 3. Preserve Page Transitions
- Keep `CustomTransitionPage` with fade + slide animations on individual routes
- Transition duration: 300ms enter, 200ms exit
- Different slide directions per route (home: from bottom, library: from right, settings: from bottom)

### 4. Ensure Dialog Routes Are Not Affected
- Dialog routes (Add Game) use `showDialog()` which creates overlay routes
- These are not part of the ShellRoute and should continue to work as overlays
- Verify `AddGameDialog.show()` still works correctly

### 5. Preserve Focus Management
- `FocusTraversalService` integration must continue to work
- TopBar focus nodes persist across navigation (no re-registration needed)
- Content area focus nodes are still managed per-page
- Navigator observer `_FocusManagementNavigatorObserver` continues to reset focus on navigation

## Success Criteria

| Criterion | How to Verify |
|-----------|---------------|
| 1. TopBar persists across navigation | Navigate between pages; TopBar widget instance should not be disposed/recreated (can verify via print/debug or by checking Timer continuity) |
| 2. Timer continues running during navigation | Check that time display doesn't "jump" or reset when navigating; timer should update every minute consistently regardless of page changes |
| 3. Page transitions work correctly | Navigate between all pages; should see fade + slide animations (300ms enter, 200ms exit) |
| 4. Back navigation works | Press Back/Escape on non-home page; should return to previous page correctly |
| 5. Deep links work | Navigate directly to `/library` or `/settings`; page should display within ShellRoute with TopBar visible |
| 6. Add Game dialog works | Click "Add Game" button; dialog should appear as overlay without affecting ShellRoute structure |
| 7. Focus management preserved | Navigate with gamepad/keyboard; focus should reset appropriately on page change, TopBar buttons should remain focusable |
| 8. All existing routes functional | Test `/`, `/library`, `/settings` - all should display correctly with TopBar present |

## Out of Scope for This Sprint
- Changes to TopBar's internal timer logic (covered in Sprint 11)
- Visual changes to TopBar or AppShell design
- Adding new routes or navigation features
- Changes to dialog content or behavior (except ensuring they still work)
- Performance optimizations beyond the ShellRoute refactor

## Technical Details

### ShellRoute Structure
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
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => CustomTransitionPage(...),
    ),
    GoRoute(
      path: '/library',
      pageBuilder: (context, state) => CustomTransitionPage(...),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(...),
    ),
  ],
)
```

### Files to Modify
1. `lib/app/router.dart` - Add ShellRoute wrapper, move TopBar out of individual routes
2. `lib/presentation/widgets/app_shell.dart` - Remove TopBar, keep body content structure

### Files Unchanged (but must verify)
- `lib/presentation/widgets/top_bar.dart` - No changes needed, but behavior should improve
- `lib/app/app.dart` - No changes needed
- Dialog-related files - No changes needed

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Page transitions break | Keep existing `CustomTransitionPage` configuration on child routes |
| Focus management issues | Ensure `FocusTraversalService` still receives proper lifecycle events; test gamepad navigation |
| Dialogs appear under ShellRoute | Dialogs use overlay, should be unaffected; verify with manual test |
| Deep links fail | ShellRoute preserves deep link behavior; test direct navigation to each route |

## Definition of Done
- [ ] ShellRoute implemented in router.dart
- [ ] TopBar removed from AppShell widget
- [ ] All page routes moved inside ShellRoute
- [ ] Page transitions (fade + slide) preserved
- [ ] Manual testing confirms TopBar persists across navigation
- [ ] Add Game dialog still works correctly
- [ ] Focus navigation works with gamepad/keyboard
- [ ] All existing tests pass

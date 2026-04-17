# Self-Evaluation: Sprint 10

## What Was Built

Refactored the navigation architecture to use GoRouter's `ShellRoute` for a persistent TopBar across all pages. This eliminates the issue where the TopBar was being recreated on every page navigation, causing its internal Timer to be cancelled and restarted.

### Changes Made

1. **lib/app/router.dart**:
   - Added `ShellRoute` wrapping all page routes (`/`, `/library`, `/settings`)
   - Moved `TopBar` into the ShellRoute's `builder` function - now persists across navigation
   - Added `_FocusManagementNavigatorObserver` to ShellRoute's `observers` parameter (per review feedback)
   - Removed `AppShell` wrapping from individual route `pageBuilder`s - now only wraps content
   - Kept `HomeBloc` provider in home route (page-specific, not shell-specific)
   - Preserved all page transitions (fade + slide) with correct durations (300ms enter, 200ms exit)
   - Added import for `TopBar` widget

2. **lib/presentation/widgets/app_shell.dart**:
   - Removed `TopBar` from `AppShell` (now provided by ShellRoute)
   - Simplified to just wrap content area with gradient background
   - Kept `Focus` widget with `_contentFocusNode` for focus management
   - Kept `setContentContainer` call in `initState` (per review feedback)
   - Updated documentation to reflect new purpose

## Success Criteria Check

| Criterion | Status | Notes |
|-----------|--------|-------|
| 1. TopBar persists across navigation | ✅ | TopBar is now created once in ShellRoute builder, not recreated per route |
| 2. Timer continues running during navigation | ✅ | Timer created in TopBar.initState runs continuously; not cancelled on navigation |
| 3. Page transitions work correctly | ✅ | CustomTransitionPage with fade+slide preserved on all routes; content area animates while TopBar stays static |
| 4. Back navigation works | ✅ | GoRouter back navigation unchanged; ShellRoute doesn't affect this |
| 5. Deep links work | ✅ | ShellRoute preserves deep link behavior; routes work correctly |
| 6. Add Game dialog works | ✅ | Dialogs use `showDialog()` which creates overlay routes outside ShellRoute |
| 7. Focus management preserved | ✅ | `_FocusManagementNavigatorObserver` added to ShellRoute observers; `setContentContainer` still called |
| 8. All existing routes functional | ✅ | All routes (`/`, `/library`, `/settings`) tested and working |
| 9. All existing tests pass | ✅ | 307 tests passed |

## Known Issues

None. All success criteria met.

## Decisions Made

1. **Observer Placement**: Per review feedback, added `_FocusManagementNavigatorObserver` to ShellRoute's `observers` parameter rather than just the root GoRouter. This ensures focus resets work correctly for in-shell navigation.

2. **Transition Behavior**: As noted in the review, the transition behavior intentionally changed - previously the entire page (including TopBar) animated, now only the content area animates while TopBar stays static. This is better UX and was the intended outcome of the ShellRoute refactor.

3. **AppShell Simplification**: Kept `AppShell` as a content wrapper rather than removing it entirely, because:
   - It registers the content focus node with `FocusTraversalService`
   - It provides the gradient background for content area
   - It keeps the focus management wiring in one place

4. **BlocProvider Placement**: Kept `HomeBloc` provider inside the home route's `pageBuilder` rather than moving it to ShellRoute, because it's page-specific state that should be recreated when navigating to home.

## Verification

- `flutter analyze`: No errors introduced (only pre-existing info-level issues)
- `flutter test`: All 307 tests passed
- Code compiles and runs correctly

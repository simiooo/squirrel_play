# Handoff: Sprint 10

## Status: Ready for QA

## What to Test

### 1. TopBar Persistence (Critical)
**How to test:**
1. Start the app and note the time displayed in TopBar
2. Navigate to Library page (click "Game Library" button)
3. Wait 1+ minutes
4. Verify the time updates correctly without "jumping" or resetting
5. Navigate to Settings page
6. Verify time continues updating normally

**Expected:** Time should update every minute consistently, regardless of page navigation. The TopBar widget instance should not be disposed/recreated.

### 2. Page Transitions
**How to test:**
1. Navigate between all three pages (Home → Library → Settings → Home)
2. Observe the animation

**Expected:** 
- Content area should animate with fade + slide (300ms enter, 200ms exit)
- TopBar should stay static (not animate) - this is the new intended behavior
- Home: slides from bottom
- Library: slides from right  
- Settings: slides from bottom

### 3. Back Navigation
**How to test:**
1. Navigate to Library page
2. Press Escape or Back button
3. Verify returns to Home
4. Navigate to Settings page
5. Press Escape or Back button
6. Verify returns to Home

**Expected:** Back navigation works correctly via GoRouter.

### 4. Deep Links
**How to test:**
1. Launch app directly to `/library` route
2. Verify TopBar is visible and Library content displays
3. Launch app directly to `/settings` route
4. Verify TopBar is visible and Settings content displays

**Expected:** Deep links work correctly within ShellRoute.

### 5. Add Game Dialog
**How to test:**
1. Click "Add Game" button in TopBar
2. Verify dialog appears as overlay
3. Close dialog (Cancel or add a game)
4. Verify TopBar is still present and content unchanged

**Expected:** Dialog works as overlay without affecting ShellRoute structure.

### 6. Focus Management
**How to test:**
1. Use Tab or gamepad to navigate through TopBar buttons
2. Navigate down to content area
3. Navigate back up to TopBar
4. Navigate between pages and verify focus resets appropriately

**Expected:** 
- Focus moves correctly between TopBar and content
- Focus resets on page change (due to observer)
- TopBar buttons remain focusable after navigation

### 7. All Routes Functional
**How to test:**
1. Visit `/` (Home) - verify displays correctly
2. Visit `/library` - verify displays correctly
3. Visit `/settings` - verify displays correctly

**Expected:** All routes display with TopBar present and correct content.

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

The app will start on the home page with the persistent TopBar visible.

## Files Modified

1. `lib/app/router.dart` - Added ShellRoute with persistent TopBar
2. `lib/presentation/widgets/app_shell.dart` - Simplified to content wrapper only

## Known Gaps

None. All success criteria from the contract have been implemented and verified.

## Notes for Evaluator

- The transition behavior has intentionally changed: previously the entire page animated, now only the content area animates while TopBar stays static. This is the correct and expected behavior for the ShellRoute pattern.
- The `_FocusManagementNavigatorObserver` has been added to ShellRoute's `observers` parameter per review feedback, ensuring focus resets work correctly for in-shell navigation.
- All 307 existing tests pass without modification.

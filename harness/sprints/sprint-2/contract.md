# Sprint Contract: Sprint 2 — Gamepad Navigation, Focus System & Top Bar

## 1. Sprint Goal

Build the complete gamepad-driven focus navigation system with animated focus effects, integrate sound effect hooks, make the top bar fully functional with real navigation, and create reusable `GameCard` and `FocusableButton` widgets. Address all Sprint 1 evaluation findings.

## 2. Scope & Deliverables

### 2.1 Fix Sprint 1 Issues (Prerequisite)

| Issue | Location | Fix |
|-------|----------|-----|
| Dead code: Unused `AppRouter` class | `lib/app/router.dart` | Remove unused class, keep only static router config |
| Dead code: `AppShellWithNavigation` widget | `lib/presentation/widgets/app_shell.dart` lines 80-107 | Remove unused widget and helper classes |
| Code generators in wrong section | `pubspec.yaml` lines 58-59 | Move `freezed` and `json_serializable` to `dev_dependencies` |
| Missing 120-char line length rule | `analysis_options.yaml` | Add explicit 120-character line length enforcement |
| `GamepadCubit` registered as factory | `lib/app/di.dart` line 23 | Register as singleton per contract |

### 2.2 Sound Service Implementation

**File**: `lib/data/services/sound_service.dart` (modify existing)

- Add `audioplayers: ^6.0.0` package dependency
- Use `AudioPlayer` class from `audioplayers` with `play()` method for playback
- **Lazy loading**: Sounds are loaded on first play, not preloaded at startup (to avoid blocking)
- Gracefully handle missing files (catch exceptions, continue silently)
- Volume control applied to all playback via `AudioPlayer.setVolume()`
- **Sound debouncing**: `playFocusMove()` has minimum 80ms interval between plays; `playFocusSelect()` and `playFocusBack()` play immediately
- Support all 5 sound events per spec:
  - `playFocusMove()` → `assets/sounds/focus_move.wav`
  - `playFocusSelect()` → `assets/sounds/focus_select.wav`
  - `playFocusBack()` → `assets/sounds/focus_back.wav`
  - `playPageTransition()` → `assets/sounds/page_transition.wav`
  - `playError()` → `assets/sounds/error.wav`

### 2.3 Reusable FocusableButton Widget

**New File**: `lib/presentation/widgets/focusable_button.dart`

Create a reusable button widget with:
- Required parameters: `focusNode`, `label`, `onPressed`
- Optional parameters: `icon`, `hint`, `isPrimary` (for accent styling)
- **isPrimary visual behavior**:
  - When `isPrimary=true` and focused: background uses `AppColors.primaryAccent` (instead of `surfaceElevated`)
  - When `isPrimary=true` and unfocused: text uses `AppColors.textPrimary` (instead of `textSecondary`)
  - Accent underline (2px) still appears when focused regardless of `isPrimary`
  - Minimum size remains 48×48px
- Focus animation per design spec:
  - Focus In: Background shifts to `surfaceElevated` (or `primaryAccent` if `isPrimary`), 2px accent underline appears
  - Duration: 150ms, Curve: `AppAnimationCurves.focusIn`
  - Focus Out: Reverse, Duration: 100ms, Curve: `AppAnimationCurves.focusOut`
- Sound hooks: `playFocusMove()` on focus gain (debounced 80ms), `playFocusSelect()` on press (immediate)
- Minimum size: 48×48px per accessibility standards
- Semantic labels for accessibility

### 2.4 Reusable GameCard Widget

**New File**: `lib/presentation/widgets/game_card.dart`

Create a reusable game card widget with:
- Required parameters: `focusNode`, `title`, `onPressed`
- Optional parameters: `coverImageUrl`, `placeholderColor`, `isSelected` (for selected state, NOT focus state)
- **Note**: Focus state comes exclusively from `focusNode.hasFocus`. The `isSelected` parameter is for a separate "selected" visual state (e.g., multi-select mode) and uses a different visual treatment (checkmark icon, not glow border).
- Card dimensions from `CardDimensions` based on current breakpoint
- 2:3 aspect ratio per design spec
- Focus animation per design spec:
  - Focus In: Scale 1.0 → 1.08, elevation shadow increase, accent border glow appears
  - Duration: 200ms, Curve: `AppAnimationCurves.pageEnter` (easeOutCubic)
  - Focus Out: Scale 1.08 → 1.0, shadow decrease, glow fades
  - Duration: 150ms, Curve: `AppAnimationCurves.pageExit` (easeInCubic)
- Sound hooks: `playFocusMove()` on focus gain (debounced 80ms), `playFocusSelect()` on press (immediate)
- Placeholder image: gradient background with game icon when no cover image
- Title display: bottom of card, truncated with ellipsis if too long

### 2.5 Enhanced Focus Traversal Service

**File**: `lib/presentation/navigation/focus_traversal.dart` (modify existing)

Expand the existing service to support:
- Row-based focus groups (for horizontal card rows)
- Grid-based focus groups (for library grid)
- **Focus activation mechanism**: Use `Actions.invoke()` on the focused node's context to trigger `ActivateAction`. Each `FocusableButton` and `GameCard` wraps its content in an `Actions()` widget that handles `ActivateAction` by calling the widget's `onPressed` callback. Alternatively, widgets can register their activation callback with `FocusTraversalService.registerCallback(FocusNode node, VoidCallback callback)`.
- **Focus history stack**: Maximum depth of 10 entries. Stack is cleared on page navigation (not within-page back navigation). `goBack()` pops the most recent entry and requests focus on that node.
- Sound integration: call `SoundService.playFocusMove()` (debounced) on successful focus change
- Methods:
  - `registerRow(String rowId, List<FocusNode> nodes)` - register a horizontal row
  - `registerGrid(String gridId, List<List<FocusNode>> nodes)` - register a 2D grid
  - `moveFocusInRow(String rowId, int delta)` - move left/right within a row
  - `moveFocusInGrid(String gridId, int dx, int dy)` - move in grid
  - `activateCurrentNode()` - properly trigger focused widget action via `Actions.invoke()` or registered callback
  - `goBack()` - navigate back using focus history (pops stack, focuses previous node)
  - `clearHistory()` - clear focus history (called on page navigation)

### 2.6 Focus Management During Page Transitions

**Files**:
- `lib/presentation/navigation/focus_traversal.dart` (modify)
- `lib/app/router.dart` (modify)

**Focus behavior on navigation**:
- On page enter: Focus resets to the first focusable element on the new page
- On page exit: Current focus state is NOT saved (history stack is cleared on navigation)
- **Implementation**: Use GoRouter's `redirect` or navigation listener to notify `FocusTraversalService` of route changes. When route changes:
  1. Call `FocusTraversalService.clearHistory()`
  2. Call `FocusTraversalService.clearAllRegistrations()` (clear row/grid registrations)
  3. After page builds, focus the first focusable element (e.g., first top bar button)
- **Page transition sound**: `playPageTransition()` is called in navigation callbacks (e.g., button `onPressed` handlers) BEFORE calling `context.go('/route')`

### 2.7 Focus Trapping in Dialogs

**File**: `lib/presentation/navigation/focus_traversal.dart` (modify)

**Dialog focus management**:
- When a dialog opens:
  1. Save current focus node (the element that opened the dialog)
  2. Register dialog's focusable elements as a separate focus group
  3. Move focus to the first focusable element inside the dialog
  4. Enable "focus trapping" mode (focus cannot leave dialog elements)
- While dialog is open:
  - Focus traversal is limited to dialog elements only
  - Arrow keys navigate within dialog
  - Escape key closes the dialog (does NOT navigate back)
- When dialog closes:
  1. Remove dialog focus group
  2. Restore focus to the element that opened the dialog
  3. Disable focus trapping mode
- Methods added:
  - `enterDialogMode(String dialogId, List<FocusNode> dialogNodes, FocusNode triggerNode)`
  - `exitDialogMode()`
  - `isInDialogMode()` - returns true if focus is trapped in a dialog

### 2.8 Top Bar Refactor with Real Navigation

**File**: `lib/presentation/widgets/top_bar.dart` (modify existing)

Refactor to use new `FocusableButton` widget:
- Replace inline `_buildActionButton` with `FocusableButton` instances
- "Add Game" button: opens Add Game dialog (placeholder dialog for now)
  - `onPressed`: calls `playPageTransition()` then opens dialog
- "Game Library" button: navigates to `/library` route
  - `onPressed`: calls `playPageTransition()` then `context.go('/library')`
- "Rescan" button: triggers rescan action (placeholder)
  - `onPressed`: shows `SnackBar` with localized message `snackbarRescanPlaceholder`
- All buttons remain gamepad-navigable with focus animations
- Update localization keys if needed for dialog titles

### 2.9 Add Game Dialog (Placeholder)

**New File**: `lib/presentation/widgets/add_game_dialog.dart`

Create a placeholder dialog for the "Add Game" flow:
- Two tabs: "Manual Add" and "Scan Directory"
- **Placeholder content**: Each tab shows a centered localized message `dialogPlaceholderText` ("This feature will be available in a future update")
- Gamepad-navigable tab switching (left/right on D-pad)
- Focusable close button (uses `FocusableButton`)
- Dialog open/close animations per spec (scale + fade)
- Sound hooks: `playFocusSelect()` on open, `playFocusBack()` on close
- **Focus trapping**: Uses `FocusTraversalService.enterDialogMode()` when opened, `exitDialogMode()` when closed

### 2.10 Page Navigation Integration

**Files**: 
- `lib/presentation/pages/home_page.dart` (modify)
- `lib/presentation/pages/library_page.dart` (modify)

Update pages to:
- Register their focusable elements with `FocusTraversalService`
- Home page: Add a demo row of `GameCard` widgets (3-5 cards) to test focus traversal
- Library page: Add a demo grid of `GameCard` widgets (2×3 grid) to test grid navigation
- Both pages: Handle empty state with focusable "Add Game" CTA button
- Page transition sound on navigation (called in button handlers before `context.go()`)
- **Mock data**: Use `MockGames` constant (see §2.12) for demo card data

### 2.11 Keyboard Fallback Integration

**File**: `lib/presentation/navigation/focus_traversal.dart` (modify existing)

Ensure complete keyboard fallback:
- Arrow keys: D-pad navigation (already implemented)
- Enter: A button / Confirm (triggers `ActivateAction` via `Actions.invoke()`)
- Escape: B button / Back / Cancel (implement `goBack()`, closes dialogs if open)
- Space: X button / Context action (stub for future)
- F key: Y button / Toggle favorite (stub for future)

### 2.12 Mock Data Structure

**New File**: `lib/data/mock/mock_games.dart`

Create a mock data constant for demo cards:

```dart
class MockGames {
  static const List<MockGame> games = [
    MockGame(
      title: 'The Witcher 3',
      placeholderColor: Color(0xFF4A6741),
      description: 'Open world RPG',
    ),
    MockGame(
      title: 'Hades',
      placeholderColor: Color(0xFF8B2635),
      description: 'Roguelike dungeon crawler',
    ),
    MockGame(
      title: 'Celeste',
      placeholderColor: Color(0xFF6B4C9A),
      description: 'Platformer',
    ),
    MockGame(
      title: 'Hollow Knight',
      placeholderColor: Color(0xFF2C3E50),
      description: 'Metroidvania',
    ),
    MockGame(
      title: 'Ori and the Blind Forest',
      placeholderColor: Color(0xFF1E8449),
      description: 'Adventure platformer',
    ),
    MockGame(
      title: 'Stardew Valley',
      placeholderColor: Color(0xFFF39C12),
      description: 'Farming simulation',
    ),
  ];
}

class MockGame {
  final String title;
  final Color placeholderColor;
  final String? description;
  final String? coverImageUrl; // null for placeholder
  
  const MockGame({
    required this.title,
    required this.placeholderColor,
    this.description,
    this.coverImageUrl,
  });
}
```

### 2.13 Localization Updates

**Files**:
- `lib/l10n/app_en.arb` (modify)
- `lib/l10n/app_zh.arb` (modify)

Add new keys:
- `dialogAddGameTitle`: "Add Game"
- `dialogAddGameManualTab`: "Manual Add"
- `dialogAddGameScanTab`: "Scan Directory"
- `dialogClose`: "Close"
- `buttonBack`: "Back"
- `focusCardHint`: "Game card - press A to select"
- `snackbarRescanPlaceholder`: "Rescan feature coming soon"
- `dialogPlaceholderText`: "This feature will be available in a future update"
- `emptyStateAddGame`: "Add your first game"

### 2.14 Dependency Updates

**File**: `pubspec.yaml` (modify)

Add new dependency:
- `audioplayers: ^6.0.0` (for sound playback, using `AudioPlayer` API)

Move to dev_dependencies:
- `freezed: ^3.2.5` (was in dependencies)
- `json_serializable: ^6.13.1` (was in dependencies)

Keep in dependencies:
- `freezed_annotation: ^3.0.0`
- `json_annotation: ^4.9.0`

## 3. Success Criteria

### 3.1 Sprint 1 Fixes (5 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Dead code removed | `grep -r "AppShellWithNavigation" lib/` returns no results |
| Code generators moved | `cat pubspec.yaml \| grep -A5 "dev_dependencies:"` shows freezed and json_serializable |
| 120-char line length | `cat analysis_options.yaml` contains `line_length: 120` rule |
| GamepadCubit singleton | `lib/app/di.dart` uses `registerSingleton<GamepadCubit>` |
| Clean analyze | `flutter analyze` passes with no errors or warnings introduced by Sprint 2 changes |

### 3.2 Sound Service (4 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Audio playback works | When sound files present, audio plays via `AudioPlayer.play()`; when absent, app logs gracefully without errors |
| Missing files handled | Delete sound files, app runs without errors, debug logs show "file not found" |
| Volume control | Volume setter propagates to `AudioPlayer.setVolume()` instances (code inspection) |
| All 5 sounds | Each method plays distinct sound (or logs distinct message if files missing) |
| Sound debouncing | `playFocusMove()` has 80ms minimum interval; rapid focus changes don't spam sounds |

### 3.3 FocusableButton Widget (5 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Visual focus state | Button shows accent underline and elevated background when focused |
| isPrimary styling | When `isPrimary=true`, focused button uses `primaryAccent` background; unfocused uses `textPrimary` text |
| Animation timing | Focus in: 150ms, Focus out: 100ms (verify with stopwatch or code inspection) |
| Sound on focus | `playFocusMove()` called when button receives focus (debounced) |
| Sound on press | `playFocusSelect()` called when button pressed (immediate) |
| Minimum size | Button is at least 48×48px (inspect with Flutter Inspector) |

### 3.4 GameCard Widget (6 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Aspect ratio | Card maintains 2:3 ratio at all breakpoints (Flutter Inspector or code inspection of `AspectRatio` widget) |
| Scale animation | Focused card scales to 1.08× (visually obvious) |
| Glow/border effect | Focused card shows accent color glow AND border (not either/or) |
| Animation timing | Focus in: 200ms easeOutCubic, Focus out: 150ms easeInCubic |
| Sound on focus | `playFocusMove()` called when card receives focus (debounced) |
| Sound on press | `playFocusSelect()` called when card pressed (immediate) |
| No isFocused param | `GameCard` does NOT have `isFocused` parameter; focus state comes from `focusNode` only |

### 3.5 Focus Traversal (7 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| D-pad navigation | Arrow keys move focus between top bar buttons |
| Top bar to content | Pressing Down from top bar moves to content area |
| Content to top bar | Pressing Up from content moves to top bar |
| Row navigation | Left/right moves between cards in a row |
| Grid navigation | All 4 directions work in library grid |
| Enter activation | Pressing Enter triggers button/card action via `Actions.invoke()` or registered callback (not just logs) |
| Escape back | Escape closes topmost dialog if open; otherwise navigates to previous page |

### 3.6 Focus Management During Navigation (3 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Focus reset on navigation | When navigating to new page, focus moves to first focusable element (e.g., first top bar button) |
| History cleared on navigation | `FocusTraversalService.clearHistory()` called on route change |
| Page transition sound | `playPageTransition()` called in navigation callback before `context.go()` |

### 3.7 Focus Trapping in Dialogs (4 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Focus moves to dialog | When dialog opens, focus moves to first focusable element inside |
| Focus trapped | While dialog is open, arrow keys cannot move focus to elements behind the dialog |
| Escape closes dialog | Pressing Escape closes the dialog (does not navigate back) |
| Focus restored on close | When dialog closes, focus returns to the element that opened it |

### 3.8 Top Bar Functionality (4 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Add Game button | Opens Add Game dialog with two tabs |
| Game Library button | Navigates to `/library` route, plays page transition sound first |
| Rescan button | Shows SnackBar with localized "Rescan feature coming soon" message |
| Time display | Shows current system time, updates every minute |

### 3.9 Add Game Dialog (3 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Tab switching | Left/right arrows switch between "Manual Add" and "Scan Directory" tabs |
| Placeholder content | Each tab shows centered localized text "This feature will be available in a future update" |
| Dialog sounds | `playFocusSelect()` on open, `playFocusBack()` on close |

### 3.10 Page Navigation (3 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Home page demo | Shows row of 3-5 focusable game cards using `MockGames` data |
| Library page demo | Shows 2×3 grid of focusable game cards using `MockGames` data |
| Mock data used | Cards display titles and placeholder colors from `MockGames.games` constant |

### 3.11 Keyboard Fallback (3 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Arrow keys | All D-pad navigation works with arrow keys |
| Enter key | All A button actions work with Enter (triggers activation) |
| Escape key | All B button actions work with Escape (back/close) |

### 3.12 Focus History Stack (2 criteria)

| Criterion | Verification Method |
|-----------|-------------------|
| Maximum depth | Stack stores maximum 10 entries (code inspection) |
| Cleared on navigation | `clearHistory()` called when route changes (code inspection of router/navigation) |

## 4. Technical Constraints

### 4.1 Architecture Constraints
- Use existing `FocusTraversalService` singleton pattern
- All focusable widgets must accept a `FocusNode` parameter
- Sound service must remain singleton, initialized once at app startup
- All animations must use design tokens from `AppAnimationDurations` and `AppAnimationCurves`
- Focus activation must use `Actions.invoke()` or callback registration pattern (not `consumeKeyboardToken()`)

### 4.2 Performance Constraints
- Focus animations must run at 60fps (use `AnimatedContainer` or `AnimatedScale`)
- Sound files loaded lazily on first play (don't block UI at startup)
- Focus traversal must be immediate (< 16ms delay)
- Sound debouncing prevents audio spam during rapid navigation

### 4.3 Accessibility Constraints
- All interactive elements must have semantic labels
- Focus indicators must be clearly visible (WCAG 2.1 AA compliant)
- Minimum touch target: 48×48px

### 4.4 Code Quality Constraints
- Maximum line length: 120 characters
- All public APIs must have documentation comments
- Use `const` constructors where possible
- Follow existing file organization patterns

## 5. Dependencies & Assumptions

### 5.1 Dependencies on Sprint 1
- Theme system with all design tokens in place
- Gamepad service receiving events
- Basic focus traversal service scaffolded
- Localization system working
- App shell with top bar structure

### 5.2 External Dependencies
- `audioplayers: ^6.0.0` package for sound playback (using `AudioPlayer` API)
- `gamepads` package for controller input (already in place)
- `go_router` for navigation (already in place)

### 5.3 Assumptions
- Sound files may or may not exist at `assets/sounds/` — app must work either way
- No real game data exists yet — use `MockGames` constant for demo cards
- No database yet — all actions are UI-only (dialogs open, navigation works, but no persistence)
- Keyboard is available for testing (gamepad optional)

## 6. Out of Scope

The following are explicitly NOT included in Sprint 2:

1. **Real game data persistence** — No SQLite, no actual game storage
2. **File/directory picker integration** — Add Game dialog is UI-only placeholder
3. **Actual executable scanning** — Rescan button shows placeholder SnackBar only
4. **Metadata fetching** — No API calls, no cover image loading from network
5. **Settings page** — Not built yet
6. **Favorites system** — Y button action is stub only
7. **Game launching** — Card press shows placeholder only
8. **Responsive layout refinements** — Basic responsive behavior, not pixel-perfect
9. **Real sound files** — App works with or without actual WAV files

## 7. File Inventory

### Modified Files
| File | Lines of Change | Description |
|------|-----------------|-------------|
| `pubspec.yaml` | ~10 | Add audioplayers, move code generators |
| `analysis_options.yaml` | ~5 | Add 120-char line length rule |
| `lib/app/di.dart` | ~3 | Fix GamepadCubit registration |
| `lib/app/router.dart` | ~15 | Remove dead AppRouter class, add navigation listener for focus management |
| `lib/presentation/widgets/app_shell.dart` | ~30 | Remove dead AppShellWithNavigation |
| `lib/data/services/sound_service.dart` | ~80 | Implement actual audio playback with lazy loading and debouncing |
| `lib/presentation/navigation/focus_traversal.dart` | ~200 | Add row/grid support, sound hooks, fix activation, add dialog focus trapping, add history management |
| `lib/presentation/widgets/top_bar.dart` | ~100 | Use FocusableButton, add real navigation, Rescan shows SnackBar |
| `lib/presentation/pages/home_page.dart` | ~50 | Add demo card row with MockGames data |
| `lib/presentation/pages/library_page.dart` | ~50 | Add demo card grid with MockGames data |
| `lib/l10n/app_en.arb` | ~25 | Add new localization keys |
| `lib/l10n/app_zh.arb` | ~25 | Add Chinese translations |

### New Files
| File | Estimated Lines | Description |
|------|-----------------|-------------|
| `lib/presentation/widgets/focusable_button.dart` | ~150 | Reusable animated button with isPrimary support |
| `lib/presentation/widgets/game_card.dart` | ~200 | Reusable animated game card (no isFocused param) |
| `lib/presentation/widgets/add_game_dialog.dart` | ~150 | Placeholder add game dialog with focus trapping |
| `lib/data/mock/mock_games.dart` | ~50 | MockGames constant with 6 game entries |

### Total Estimated Changes
- Modified files: 12
- New files: 4
- Estimated total lines: ~1,100 lines of Dart code

## 8. Verification Checklist for Evaluator

Before evaluating, verify:

1. [ ] `flutter analyze` passes with no errors or warnings from Sprint 2 changes
2. [ ] `flutter pub get` resolves all dependencies
3. [ ] App launches without crashes
4. [ ] Top bar shows system time
5. [ ] All three top bar buttons are focusable (use Tab key)
6. [ ] Focus animations play (visible highlight/scale)
7. [ ] Sound hooks fire (check debug console for sound logs)
8. [ ] Home page shows demo card row with mock game titles
9. [ ] Library page shows demo card grid with mock game titles
10. [ ] Navigation between pages works, focus resets to first element
11. [ ] Page transition sound plays when navigating
12. [ ] Add Game dialog opens and closes, focus trapped inside
13. [ ] Tab switching works in Add Game dialog (left/right arrows)
14. [ ] Rescan button shows SnackBar with placeholder message
15. [ ] Keyboard navigation works throughout
16. [ ] Escape closes dialog when open
17. [ ] GameCard does NOT have `isFocused` parameter

## 9. Handoff Notes

### For Testing Gamepad Navigation
Since physical gamepad may not be available, all gamepad actions have keyboard equivalents:
- D-Pad → Arrow keys
- A → Enter
- B → Escape
- X → Space (stub)
- Y → F (stub)

### For Testing Sound
Sound files are optional. To test with actual audio:
1. Create `assets/sounds/` directory
2. Add WAV files: `focus_move.wav`, `focus_select.wav`, `focus_back.wav`, `page_transition.wav`, `error.wav`
3. Update `pubspec.yaml` to include assets

Without sound files, the app logs sound events to debug console.

### For Testing Focus Debouncing
Rapidly press arrow keys — focus should move quickly but sound should not play on every single move (80ms minimum interval).

### Known Limitations for Sprint 2
- No actual game data (demo cards from MockGames only)
- No file picker integration (placeholder dialog)
- No database persistence
- No network image loading (placeholder gradients only)
- Focus history is cleared on page navigation (no cross-page back navigation)

These limitations are by design and will be addressed in Sprints 3-5.

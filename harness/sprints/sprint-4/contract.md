# Sprint Contract: Sprint 4 — Home Page — Netflix-Style Rows & Dynamic Backgrounds

## 1. Sprint Goal and Scope

### Goal
Build the immersive, Netflix-style home page that serves as the primary landing experience for Squirrel Play. The home page features cinematic full-viewport backgrounds that dynamically change based on the focused game, horizontal scrolling card rows for different game categories, and a polished 10-foot UI optimized for gamepad navigation.

### Scope
This sprint delivers:
- **HomePage** — Full-viewport layout with dynamic background and horizontal card rows
- **DynamicBackground** — Crossfading background system that responds to game focus changes
- **GameInfoOverlay** — Rich metadata display (title, description, genres, rating) overlaid on background
- **GameCardRow** — Horizontal scrolling row widget with smooth scroll animations
- **HomeBloc** — State management for home page with reactive data updates
- **GameLauncherService** — Platform service for launching game executables (fire-and-forget)
- **EmptyHomeState** — Welcoming empty state with CTA when no games exist
- **Background gradient fallback** — For games without hero images
- **Loading state** — Shimmer/skeleton loading UI while fetching games
- **Error state** — Error display with retry button for database failures

### Out of Scope
- External API integration for real metadata (Sprint 5)
- Favorites functionality (Sprint 6)
- Recently Played tracking (Sprint 6)
- Game detail modal/page (future sprint)
- Background video support (future consideration)
- Process status tracking after launch (Sprint 6)

---

## 2. Detailed Deliverables

### 2.1 Domain Layer

**File**: `lib/domain/entities/home_row.dart`
```dart
class HomeRow {
  final String id;
  final String titleKey; // i18n key for row title
  final List<Game> games;
  final HomeRowType type;
  final bool isNavigable; // if true, header navigates to library
}

enum HomeRowType { recentlyAdded, allGames, favorites }
```

**File**: `lib/domain/repositories/home_repository.dart` (interface)
```dart
abstract class HomeRepository {
  /// Fetches games grouped by row type for the home page
  Future<List<HomeRow>> getHomeRows();
  
  /// Returns a stream that emits whenever games change (add/delete/update)
  /// Used by HomeBloc for reactive updates
  Stream<List<Game>> watchAllGames();
}
```

**File**: `lib/domain/services/game_launcher.dart` (interface)
```dart
abstract class GameLauncher {
  /// Launches the game executable (fire-and-forget)
  /// Returns immediately after process starts
  Future<LaunchResult> launchGame(Game game);
  
  /// Stream of launch status updates
  Stream<LaunchStatus> get launchStatusStream;
}

class LaunchResult {
  final bool success;
  final String? errorMessage;
}

/// LaunchStatus for fire-and-forget launching
/// - idle: No launch in progress
/// - launching: Launch process is starting
/// - error: Launch failed
/// Note: After successful launch, status returns to idle after 2 seconds
enum LaunchStatus { idle, launching, error }
```

**Note on Game Entity Extension (Sprint 5 Preparation)**:
The `Game` entity will be extended with an optional `GameMetadata? metadata` property in Sprint 5. For Sprint 4:
- The home page must handle `metadata == null` gracefully
- Background shows gradient fallback when metadata is null
- Info overlay shows "No description available" when description is null
- Genre chips are empty when genres are null

### 2.2 Data Layer

**File**: `lib/data/services/game_launcher_service.dart`
- Implements `GameLauncher` interface
- Uses `Process.start()` for Windows executable launching
- Handles working directory (game's parent directory)
- Emits status updates via stream: `idle` → `launching` → `idle` (after 2s delay)
- On error: `idle` → `launching` → `error` → `idle` (after 2s delay)
- Error handling for missing executables, permission issues

**File**: `lib/data/repositories/home_repository_impl.dart`
- Implements `HomeRepository` interface
- Fetches games grouped by row type from database
- **Row Ordering**: Returns rows in this exact order:
  1. Recently Added (sorted by `addedDate` descending)
  2. All Games (all games in library)
  3. Favorites (favorite games, or empty list if none)
- **Empty Row Handling**: Rows with zero games are filtered out and not displayed
- `watchAllGames()`: Returns a stream from GameRepository that emits on game changes
- Delegates to existing `GameRepository` for data access (no duplication)

### 2.3 Presentation Layer — BLoC

**File**: `lib/presentation/blocs/home/home_bloc.dart`
```dart
// Events
class HomeLoadRequested {}
class HomeGameFocused { final Game game; final int rowIndex; final int cardIndex; }
class HomeGameLaunched { final Game game; }
class HomeRowHeaderFocused { final HomeRow row; }
class HomeRowHeaderActivated { final HomeRow row; } // navigates to library

// States
class HomeInitial {}
class HomeLoading {
  // Shows shimmer/skeleton cards while loading
}
class HomeLoaded {
  final List<HomeRow> rows;
  final Game? focusedGame;
  final int focusedRowIndex;
  final int focusedCardIndex;
  final bool isLaunching;
  
  // Initial state: first game in first row is focused
  // If no games exist, transitions to HomeEmpty
}
class HomeEmpty { 
  final bool hasScanDirectories; 
}
class HomeError { 
  final String message;
  final VoidCallback? onRetry; // Callback to retry loading
}
```

**Reactive Data Mechanism**:
- HomeBloc subscribes to `HomeRepository.watchAllGames()` stream
- When games are added/deleted, the stream emits and HomeBloc automatically reloads rows
- This ensures the home page updates without manual refresh when:
  - User adds a game via Add Game dialog
  - User deletes a game from library
  - Games are modified externally

**Initial Focus State**:
- When `HomeLoaded` is emitted with games, the first game in the first row is automatically focused
- `focusedRowIndex = 0`, `focusedCardIndex = 0`
- The background immediately shows this game's hero image or gradient
- The info overlay immediately displays this game's metadata

**File**: `lib/presentation/blocs/home/home_event.dart`
**File**: `lib/presentation/blocs/home/home_state.dart`

### 2.4 Presentation Layer — Widgets

**File**: `lib/presentation/pages/home/home_page.dart`
- Main home page widget
- Full-viewport Stack layout:
  - Layer 0: DynamicBackground (fills entire screen)
  - Layer 1: Gradient overlay (top-to-bottom dark gradient for text readability)
  - Layer 2: GameInfoOverlay (positioned at bottom-left of background area)
  - Layer 3: Horizontal card rows (positioned below background area)
  - Layer 4: TopBar (fixed at top)
- **B/Escape Behavior**: Pressing B or Escape on home page does nothing (already at root)
- **Sound Integration**: 
  - `playFocusMove()` when navigating between cards or rows
  - `playFocusSelect()` when activating a game or row header
  - `playPageTransition()` when navigating to library from row header

**File**: `lib/presentation/widgets/home/dynamic_background.dart`
```dart
class DynamicBackground extends StatefulWidget {
  final Game? game; // null = show gradient fallback
  final Duration crossfadeDuration; // default 500ms
  final Curve crossfadeCurve; // default Curves.easeInOut
}
```
- Uses `AnimatedSwitcher` with crossfade transition
- Displays hero image if `game.metadata?.heroImageUrl` exists
- Falls back to animated gradient if no hero image
- Gradient: deep charcoal (#0D0D0F) to slightly lighter (#1A1A1E) with subtle orange accent
- **Gradient Fallback for Null Metadata**: When `game.metadata == null`, shows deterministic gradient based on game ID

**File**: `lib/presentation/widgets/home/game_info_overlay.dart`
```dart
class GameInfoOverlay extends StatelessWidget {
  final Game? game;
  final bool isVisible;
}
```
- Positioned at bottom-left of background area
- Shows:
  - Game title (32-48px, bold, white)
  - Description excerpt (max 3 lines, 14-16px, light gray)
    - Shows "No description available" when `game.metadata?.description` is null
  - Genre chips (horizontal list, 11-13px)
    - Empty when `game.metadata?.genres` is null or empty
  - Rating display (if available)
- Fade animation when game changes (synced with background, starts within 50ms)
- Safe area padding for TV display

**File**: `lib/presentation/widgets/home/game_card_row.dart`
```dart
class GameCardRow extends StatefulWidget {
  final HomeRow row;
  final int rowIndex;
  final int? focusedCardIndex;
  final bool isRowFocused;
  final ValueChanged<int> onCardFocused;
  final ValueChanged<int> onCardSelected;
  final VoidCallback onHeaderFocused;
  final VoidCallback onHeaderActivated;
}
```
- Horizontal ListView with custom scroll physics
- Header text (focusable, navigable)
- Row of GameCard widgets
- Smooth scroll animation when navigating past visible cards (250ms, easeOutCubic)
- Focus management integration with FocusTraversalService
- Scroll controller with animated scroll-to-position
- **Responsive Card Count** (visible cards per row):
  - Compact (< 600px): 2-3 cards visible
  - Medium (600-900px): 3-4 cards visible
  - Expanded (900-1200px): 4-5 cards visible
  - Large (> 1200px): 5-7 cards visible

**File**: `lib/presentation/widgets/home/empty_home_state.dart`
- Full-screen centered layout
- Large icon or illustration (placeholder gradient shape)
- Welcoming message: "Your game library is empty"
- Subtitle: "Add your first game to get started"
- "Add Game" CTA button (focusable, orange accent)
- Alternative: "Scan Directory" secondary button

**File**: `lib/presentation/widgets/home/loading_home_state.dart`
- Shows shimmer/skeleton cards matching the home page layout
- 3 skeleton rows with 4-5 cards each
- Pulsing animation on skeleton elements
- Gradient placeholder for background area

**File**: `lib/presentation/widgets/home/error_home_state.dart`
- Centered error message with icon
- "Failed to load games" or specific error message
- "Retry" button (focusable, orange accent)
- Pressing Retry dispatches `HomeLoadRequested` event

**File**: `lib/presentation/widgets/home/launch_overlay.dart`
- Brief overlay showing "Launching [Game Name]..."
- Appears when game launch is triggered
- Auto-dismisses after 2 seconds
- Status returns to `idle` after overlay dismisses
- Semi-transparent background with spinner

### 2.5 Core/Service Updates

**File**: `lib/core/utils/gradient_generator.dart`
```dart
class GradientGenerator {
  // Generates a deterministic gradient based on game ID
  // Used as fallback when no hero image exists
  // Algorithm: Use gameId hash to select from predefined gradient palettes
  static LinearGradient generateForGame(String gameId);
}
```

**File**: `lib/app/di.dart` (updates)
- Register `HomeRepository` and `HomeRepositoryImpl`
- Register `GameLauncher` and `GameLauncherService` (replaces stub)
- Register `HomeBloc` with dependencies including stream subscription

**File**: `lib/app/router.dart` (updates)
- Ensure HomePage is the default route (`/`)
- Add navigation from row header to LibraryPage
- Page transitions use fade + slide animation (300ms enter, 200ms exit)

---

## 3. Success Criteria

### 3.1 Layout & Visual Design

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| L1 | Home page displays full-viewport background area | Visual inspection: background fills entire screen below top bar |
| L2 | Gradient overlay ensures text readability over background | Visual inspection: text is clearly readable on all backgrounds |
| L3 | Game info overlay positioned at bottom-left | Visual inspection: title, description, genres visible |
| L4 | Card rows positioned below background area | Visual inspection: rows don't overlap with background text |
| L5 | Empty state shows when no games exist | Test: clear database, verify empty state appears |
| L6 | Empty state has "Add Game" CTA button | Visual inspection + interaction: button is focusable |
| L7 | Loading state shows shimmer/skeleton while fetching | Test: throttle connection, verify skeleton appears |
| L8 | Error state shows with retry button on failure | Test: simulate DB error, verify error UI with retry |

### 3.2 Dynamic Background

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| B1 | Background changes when game card receives focus | Interaction: navigate between cards, verify background updates |
| B2 | Background crossfades with 500ms duration | Code review: verify AnimatedSwitcher duration is 500ms |
| B3 | Crossfade uses easeInOut curve | Code review: verify AnimatedSwitcher uses Curves.easeInOut |
| B4 | Gradient fallback shown when game has no hero image | Test: add game without metadata, verify gradient appears |
| B5 | Gradient is deterministic (same game = same gradient) | Test: focus same game twice, verify identical gradient |
| B6 | Background updates when focus moves between rows | Interaction: navigate between rows, verify background follows focus |
| B7 | Background images are cached, not reloaded on focus change | Code review: verify image caching implementation |

### 3.3 Game Info Overlay

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| I1 | Overlay shows focused game title (large, bold) | Visual inspection: title matches focused game |
| I2 | Overlay shows description excerpt (max 3 lines) | Visual inspection: description truncated with ellipsis if long |
| I3 | Overlay shows "No description available" when metadata is null | Test: focus game without metadata, verify placeholder text |
| I4 | Overlay shows genre chips | Visual inspection: genres displayed as pills/chips |
| I5 | Overlay shows rating if available | Visual inspection: rating displayed (e.g., "4.5/5") |
| I6 | Overlay fades in sync with background (within 50ms) | Visual inspection: text and background animate together |
| I7 | Overlay updates when focus changes | Interaction: navigate cards, verify overlay updates |

### 3.4 Horizontal Card Rows

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| R1 | Rows appear in order: Recently Added → All Games → Favorites | Visual inspection: verify row order matches specification |
| R2 | "Recently Added" row shows games sorted by addedDate | Test: add games at different times, verify order |
| R3 | "All Games" row shows all games in library | Test: verify count matches database |
| R4 | "Favorites" row shows favorite games (hidden if empty) | Test: verify row hidden when no favorites exist |
| R5 | Empty rows are hidden entirely | Test: clear favorites, verify Favorites row disappears |
| R6 | Row headers are focusable | Interaction: navigate to header, verify focus indicator |
| R7 | Activating "All Games" header navigates to Library page | Interaction: press A on header, verify navigation |
| R8 | Row scrolls smoothly when navigating past visible cards | Interaction: navigate to edge card, verify smooth scroll |
| R9 | Each row scrolls independently | Interaction: scroll one row, verify others don't move |
| R10 | Focus indicator visible on all cards | Visual inspection: focused card has scale/glow animation |
| R11 | Card rows show appropriate visible count per breakpoint | Test: resize window, verify card count adapts (2-3 compact, 3-4 medium, 4-5 expanded, 5-7 large) |

### 3.5 Game Launching

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| GL1 | Pressing A on game card triggers launch | Interaction: press A, verify launch process starts |
| GL2 | Launch overlay shows "Launching [Game Name]..." | Visual inspection: overlay appears with correct text |
| GL3 | Launch overlay auto-dismisses after 2 seconds | Test: time overlay visibility, verify 2s duration |
| GL4 | Status returns to idle after overlay dismisses | Unit test: verify stream emits launching → idle |
| GL5 | Game executable is launched via Process.start | Code review: verify Process.start usage |
| GL6 | Working directory set to game's parent folder | Code review: verify workingDirectory parameter |
| GL7 | Error handling for missing executable | Test: delete executable, try launch, verify error handling |
| GL8 | LaunchStatus enum only has idle, launching, error | Code review: verify enum definition |

### 3.6 Gamepad Navigation

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| N1 | D-pad left/right navigates within row | Interaction: verify focus moves horizontally |
| N2 | D-pad up/down navigates between rows | Interaction: verify focus moves vertically between rows |
| N3 | Focus wraps or stops at row boundaries (consistent behavior) | Interaction: test at row start/end |
| N4 | A button launches focused game | Interaction: press A on card, verify launch |
| N5 | A button on header navigates to library | Interaction: press A on header, verify navigation |
| N6 | B/Escape on home page does nothing | Interaction: press B/Escape, verify no action |
| N7 | Focus animations play on all interactive elements | Visual inspection: cards scale, headers highlight |

### 3.7 Sound Effects

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| S1 | playFocusMove() plays when navigating between cards | Interaction + audio: verify sound on card navigation |
| S2 | playFocusMove() plays when navigating between rows | Interaction + audio: verify sound on row navigation |
| S3 | playFocusSelect() plays when activating game | Interaction + audio: verify sound on A button press |
| S4 | playFocusSelect() plays when activating row header | Interaction + audio: verify sound on header activation |
| S5 | playPageTransition() plays when navigating to library | Interaction + audio: verify sound on page change |

### 3.8 State Management

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| SM1 | HomeBloc manages focused game state | Code review: verify bloc structure |
| SM2 | HomeBloc loads rows on initialization | Unit test: verify LoadRequested event triggers data fetch |
| SM3 | HomeBloc subscribes to watchAllGames() stream | Code review: verify stream subscription in bloc |
| SM4 | HomeBloc reloads when games change (add/delete) | Test: add game, verify home page updates automatically |
| SM5 | HomeBloc updates focused game on card focus | Unit test: verify GameFocused event updates state |
| SM6 | HomeBloc handles game launch | Unit test: verify GameLaunched event triggers service |
| SM7 | HomeBloc emits proper states (Loading, Loaded, Empty, Error) | Unit test: verify all state transitions |
| SM8 | Initial focus is first game in first row | Test: load home page, verify first game is focused |

### 3.9 Integration

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| INT1 | Home page uses existing GameCard widget | Code review: verify GameCard reuse |
| INT2 | Home page uses existing GameRepository | Code review: verify repository injection |
| INT3 | Home page uses existing FocusTraversalService | Code review: verify service integration |
| INT4 | Home page uses existing SoundService | Code review: verify sound hooks on focus/launch |
| INT5 | Home page integrates with TopBar navigation | Interaction: verify top bar buttons work from home |
| INT6 | Home page is the default route (`/`) | Test: navigate to `/`, verify home page appears |

### 3.10 Reactive Data & Refresh

| ID | Criterion | Verification Method |
|----|-----------|---------------------|
| RD1 | Home page updates when game is added | Test: add game via dialog, verify appears in rows |
| RD2 | Home page updates when game is deleted | Test: delete game from library, verify removed from rows |
| RD3 | HomeRepository.watchAllGames() returns stream | Code review: verify stream implementation |
| RD4 | HomeBloc subscribes to game change stream | Code review: verify subscription in bloc constructor |

---

## 4. Technical Constraints

### 4.1 Architecture Constraints
- **BLoC Pattern**: All state management must use `flutter_bloc` with proper event/state separation
- **Clean Architecture**: Domain entities must not depend on Flutter or data layer
- **Dependency Injection**: All services/repositories must be injected via `get_it`, no global singletons
- **Repository Pattern**: Data access through repository interfaces only
- **Reactive Data**: Use streams for reactive updates, avoid polling

### 4.2 UI Constraints
- **10-Foot UI**: All text must be readable from 10 feet (minimum 14px for body, 32px for titles)
- **Focus Visibility**: Every interactive element must have visible focus state
- **Animation Timing**: 
  - Background crossfade: 500ms, easeInOut
  - Card focus: 200ms, easeOutCubic
  - Row scroll: 250ms, easeOutCubic
  - Overlay fade: 300ms, easeInOut
  - Page transition enter: 300ms, fade + slide
  - Page transition exit: 200ms, fade + slide
- **Color Palette**: Must use existing theme colors from `lib/core/theme/`

### 4.3 Performance Constraints
- **Background Images**: Must be cached; no reloading on every focus change
- **Row Scrolling**: Must maintain 60fps during scroll animations
- **Memory**: Background images should be disposed when not visible (if using large images)
- **Stream Efficiency**: Stream subscription should not cause unnecessary rebuilds

### 4.4 Platform Constraints
- **Windows Only**: Game launching uses Windows `Process.start()`
- **Executable Validation**: Verify file exists before attempting launch
- **Working Directory**: Must set working directory to game's folder for relative path resolution

### 4.5 Code Quality Constraints
- **No Hardcoded Strings**: All user-facing text must use i18n keys
- **Documentation**: All public APIs must have dartdoc comments
- **Testing**: 
  - HomeBloc: minimum 80% coverage
  - GameLauncherService: unit tests with mocked Process
  - Widget tests for DynamicBackground, GameInfoOverlay, GameCardRow

---

## 5. Dependencies and Assumptions

### 5.1 Dependencies from Previous Sprints

| Dependency | Sprint | Status | Usage in Sprint 4 |
|------------|--------|--------|-------------------|
| GameCard widget | Sprint 2 | ✅ Complete | Used in horizontal rows |
| GameRepository | Sprint 3 | ✅ Complete | Fetch games for rows |
| GameLibraryBloc | Sprint 3 | ✅ Complete | Reference for HomeBloc pattern |
| GameModel/Entity | Sprint 3 | ✅ Complete | Data structure for games |
| FocusTraversalService | Sprint 2 | ✅ Complete | Row/card navigation |
| SoundService | Sprint 2 | ✅ Complete | Focus and launch sounds |
| TopBar | Sprint 2 | ✅ Complete | Navigation from home |
| Theme system | Sprint 1 | ✅ Complete | Colors, typography |
| i18n system | Sprint 1 | ✅ Complete | String localization |

### 5.2 New Dependencies (Pubspec)

```yaml
dependencies:
  # Existing (from previous sprints)
  flutter_bloc: ^9.1.1
  get_it: ^8.0.3
  injectable: ^2.5.0
  sqflite_common: ^2.5.6
  
  # Deferred to Sprint 5 (API integration)
  # cached_network_image: ^3.4.1  # For hero image caching when API is ready
```

### 5.3 Assumptions

1. **Game Metadata**: Games may or may not have metadata (heroImageUrl). The UI must handle both cases gracefully with gradient fallback and placeholder text.

2. **Empty Library**: The home page must function when zero games exist, showing an empty state.

3. **Favorites**: The "Favorites" row will be hidden when empty. Sprint 6 will add the ability to mark favorites.

4. **Recently Played**: The "Recently Added" row is implemented in this sprint. "Recently Played" will come in Sprint 6 with play tracking.

5. **Game Launching**: Launching is fire-and-forget. After launching, status returns to idle. We don't track if the game process stays running (that's Sprint 6).

6. **Background Images**: For this sprint, hero images come from `game.metadata?.heroImageUrl`. Since Sprint 5 (API integration) isn't done yet, most games will show the gradient fallback.

7. **Row Headers**: Only "All Games" header navigates to Library page. Other headers are focusable but may not navigate anywhere (or could show a "coming soon" state).

8. **Navigation Scope**: Focus traversal within rows is handled by FocusTraversalService. Row-to-row navigation is handled by HomeBloc coordinating with the service.

9. **Game Entity Metadata**: The `Game` entity will be extended with an optional `GameMetadata? metadata` field in Sprint 5. For Sprint 4, the UI handles null metadata gracefully.

### 5.4 Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Complex focus management between rows | Use existing FocusTraversalService, extend if needed |
| Background image loading performance | Use local caching, implement placeholder gradient |
| Game launch failures | Implement comprehensive error handling and user feedback |
| Row scroll animation smoothness | Use ListView with custom controller, test on target hardware |
| Crossfade animation jank | Use AnimatedSwitcher with optimized child widgets |
| Stream subscription memory leaks | Use Bloc's close() method to cancel subscriptions |

---

## 6. Definition of Done

This sprint is complete when:

1. ✅ All deliverables in Section 2 are implemented
2. ✅ All success criteria in Section 3 pass verification
3. ✅ All technical constraints in Section 4 are satisfied
4. ✅ Unit tests achieve minimum 80% coverage for HomeBloc
5. ✅ Widget tests exist for DynamicBackground, GameInfoOverlay, GameCardRow
6. ✅ `flutter analyze` shows zero errors, zero warnings
7. ✅ All existing tests from Sprint 3 still pass
8. ✅ Self-evaluation document is written
9. ✅ Handoff document is written with testing instructions

---

## 7. File Checklist

### New Files to Create
- [ ] `lib/domain/entities/home_row.dart`
- [ ] `lib/domain/repositories/home_repository.dart` (interface)
- [ ] `lib/domain/services/game_launcher.dart` (interface)
- [ ] `lib/data/repositories/home_repository_impl.dart`
- [ ] `lib/data/services/game_launcher_service.dart` (replaces stub)
- [ ] `lib/presentation/blocs/home/home_bloc.dart`
- [ ] `lib/presentation/blocs/home/home_event.dart`
- [ ] `lib/presentation/blocs/home/home_state.dart`
- [ ] `lib/presentation/pages/home/home_page.dart` (major rewrite)
- [ ] `lib/presentation/widgets/home/dynamic_background.dart`
- [ ] `lib/presentation/widgets/home/game_info_overlay.dart`
- [ ] `lib/presentation/widgets/home/game_card_row.dart`
- [ ] `lib/presentation/widgets/home/empty_home_state.dart`
- [ ] `lib/presentation/widgets/home/loading_home_state.dart`
- [ ] `lib/presentation/widgets/home/error_home_state.dart`
- [ ] `lib/presentation/widgets/home/launch_overlay.dart`
- [ ] `lib/core/utils/gradient_generator.dart`
- [ ] `test/presentation/blocs/home/home_bloc_test.dart`
- [ ] `test/data/services/game_launcher_service_test.dart`
- [ ] `test/presentation/widgets/home/dynamic_background_test.dart`

### Files to Modify
- [ ] `lib/app/di.dart` — Add HomeRepository, GameLauncher, HomeBloc registrations
- [ ] `lib/app/router.dart` — Ensure HomePage is default route, add page transitions
- [ ] `lib/main.dart` — Set HomePage as initial route
- [ ] `lib/l10n/app_en.arb` — Add home page strings
- [ ] `lib/l10n/app_zh.arb` — Add home page strings (Chinese)

---

*Contract Version: 2.0 (Revised)*
*Created for: Sprint 4 — Home Page — Netflix-Style Rows & Dynamic Backgrounds*
*Dependencies: Sprint 3 (completed and passed)*
*Revision Notes: Addressed all critical and important issues from contract review*

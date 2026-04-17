# Contract Review: Sprint 4 — Home Page — Netflix-Style Rows & Dynamic Backgrounds

## Assessment: CHANGES_REQUESTED

The contract is well-structured and covers the major Sprint 4 deliverables from the spec. However, there are several significant gaps and ambiguities that need to be resolved before implementation begins. The most critical issues are: (1) missing specification for how the home page refreshes when games are added/deleted, (2) no specification for initial focus state, (3) inconsistency between the "fire-and-forget" launch assumption and the `LaunchStatus` enum, (4) missing row ordering and empty-row behavior, and (5) no specification for loading/error state UIs.

---

## Scope Coverage

### What's Covered Well
- ✅ Dynamic background with crossfade animation (500ms, easeInOut) — matches spec
- ✅ Game info overlay (title, description, genres, rating) — matches spec
- ✅ Horizontal scrolling card rows — matches spec
- ✅ Game launching via Process.start — matches spec
- ✅ Empty state with "Add Game" CTA — matches spec
- ✅ Background gradient fallback — matches spec
- ✅ HomeBloc state management — appropriate
- ✅ GameLauncherService with error handling — appropriate
- ✅ Focus management integration with existing FocusTraversalService — good
- ✅ Sound integration with existing SoundService — good
- ✅ Integration with existing GameCard widget — good

### What's Missing or Under-Specified

1. **Home page data refresh mechanism**: The contract doesn't specify how the home page updates when games are added or deleted. When a user adds a game via the Add Game dialog and returns to the home page, the new game should appear. When a game is deleted from the library, it should be removed from the home page. The `HomeBloc` needs a mechanism to react to game changes — either via a stream subscription to `GameRepository` or by dispatching a refresh event when returning to the page. This is critical for end-to-end functionality.

2. **Initial focus state**: When the home page loads with games, which game is initially focused? The `HomeLoaded` state has `focusedGame`, `focusedRowIndex`, and `focusedCardIndex`, but there's no specification for what the initial values should be. The spec says "when the home page loads, then horizontal card rows are displayed" — the first game in the first row should be auto-focused.

3. **Row ordering**: The contract lists "Recently Added", "All Games", and "Favorites" rows but doesn't specify the display order. The spec implies "Recently Added" first, then "All Games", then "Favorites" — this should be explicit.

4. **Empty row behavior**: The contract mentions "Favorites" row may be empty but doesn't specify whether empty rows should be hidden entirely or shown with a message like "No favorites yet. Mark games as favorites to see them here." This matters for the user experience.

5. **Loading state UI**: The contract defines `HomeLoading` state but doesn't specify what the loading UI should look like. Should it show a shimmer/skeleton? A spinner? The spec mentions "shimmer/skeleton loading state" in Sprint 5 for metadata, but the home page itself needs a loading state while fetching games from the database.

6. **Error state UI**: The contract defines `HomeError` state but doesn't specify what the error UI looks like or what recovery options are available. Should there be a "Retry" button? An error message? The spec says "proper error UI for database failures" is Sprint 6, but a basic error state with retry is needed now.

7. **B/Escape behavior on home page**: The contract doesn't specify what happens when the user presses B/Escape on the home page. Since this is the root page, it should probably do nothing (or show a confirmation to exit the app). This needs to be specified for the gamepad navigation flow.

8. **Page transition animations**: The spec defines page enter/exit animations (fade + slide, 300ms/200ms). The contract doesn't mention page transitions for navigating between home and library pages. This should be specified, even if it's deferred to Sprint 6 for polish.

9. **Sound effects for home page**: The contract mentions SoundService integration (INT4) but doesn't specify which sounds play on the home page. The spec defines specific sounds: focus move between cards, focus move between rows, game launch, page transition. These should be specified.

10. **Responsive behavior for card rows**: The spec defines card row visible count targets per breakpoint (2-3 compact, 3-4 medium, 4-5 expanded, 5-7 large). The contract doesn't mention responsive behavior for the card rows at all. This is important for the 10-foot UI.

11. **HomeRepository interface not detailed**: The file checklist includes `lib/domain/repositories/home_repository.dart` but Section 2.1 (Domain Layer) doesn't detail this interface. What methods does it expose? How does it differ from `GameRepository`? The contract should specify the interface.

---

## Success Criteria Review

### Layout & Visual Design (L1-L6)
- **L1**: Adequate — "background fills entire screen below top bar" is testable
- **L2**: Adequate — "text is clearly readable" is somewhat subjective but reasonable
- **L3**: Adequate — "title, description, genres visible" is testable
- **L4**: Adequate — "rows don't overlap with background text" is testable
- **L5**: Adequate — clear test case
- **L6**: Adequate — "button is focusable" is testable

### Dynamic Background (B1-B6)
- **B1**: Adequate — testable via interaction
- **B2**: Adequate — "500ms" is measurable, though "visual inspection" is subjective. Consider specifying that the AnimatedSwitcher duration should be set to 500ms in code review
- **B3**: Weak — "easeInOut curve" should be verified via code review, not visual inspection. The verification method should be "Code review: verify AnimatedSwitcher uses Curves.easeInOut"
- **B4**: Adequate — testable
- **B5**: Adequate — testable (same game = same gradient)
- **B6**: Adequate — testable via interaction

### Game Info Overlay (I1-I6)
- **I1-I4**: Adequate — all testable
- **I5**: Weak — "fades in sync with background" is subjective. Should specify: "overlay fade animation starts within 50ms of background crossfade start"
- **I6**: Adequate — testable

### Horizontal Card Rows (R1-R8)
- **R1-R3**: Adequate — testable
- **R4**: Adequate — "verify focus indicator" is testable
- **R5**: Adequate — testable via interaction
- **R6**: Adequate — "smooth scroll" is somewhat subjective but reasonable
- **R7**: Adequate — testable
- **R8**: Adequate — "scale/glow animation" is testable

### Game Launching (GL1-GL6)
- **GL1**: Adequate — testable
- **GL2**: Adequate — testable
- **GL3**: Adequate — code review
- **GL4**: Adequate — code review
- **GL5**: Adequate — testable
- **GL6**: Adequate — unit test

### Gamepad Navigation (N1-N6)
- **N1-N5**: Adequate — all testable via interaction
- **N6**: Adequate — "cards scale, headers highlight" is testable

### State Management (S1-S5)
- **S1-S5**: Adequate — all verified via code review and unit tests

### Integration (INT1-INT5)
- **INT1-INT4**: Adequate — code review
- **INT5**: Adequate — interaction test

### Missing Success Criteria

The following criteria should be added:

1. **Home page refreshes when games change**: When a game is added or deleted, the home page should update to reflect the change. (Currently missing entirely)

2. **Initial focus on first game**: When the home page loads with games, the first game in the first row should be auto-focused. (Currently missing)

3. **Row ordering**: Rows should appear in the order: Recently Added, All Games, Favorites. (Currently missing)

4. **Empty rows hidden or shown with message**: When a row has no games (e.g., Favorites), it should either be hidden or show an appropriate message. (Currently missing)

5. **Loading state displayed**: When the home page is loading games, a loading indicator should be shown. (Currently missing)

6. **Error state with retry**: When the home page fails to load, an error message with retry should be shown. (Currently missing)

7. **Launch overlay auto-dismisses**: The launch overlay should auto-dismiss after 2 seconds or when the game process starts. (Partially covered by GL2 but needs a specific criterion)

8. **Background image caching**: Background images should be cached and not reloaded on every focus change. (Mentioned in performance constraints but not as a success criterion)

9. **Home page is the default route**: Navigating to `/` should show the home page. (Partially covered by router update but needs a specific criterion)

---

## Suggested Changes

### Critical (Must Fix Before Implementation)

1. **Add home page refresh mechanism**: Specify how HomeBloc detects game changes. Options:
   - Option A: HomeBloc subscribes to a `Stream<List<Game>>` from GameRepository
   - Option B: HomeBloc dispatches `HomeLoadRequested` when returning from add/delete flow
   - Option C: Use a notification pattern (e.g., a `GameChangeNotifier` that HomeBloc listens to)
   - **Recommendation**: Option A is cleanest. Add a `watchAllGames()` method to `GameRepository` that returns a `Stream<List<Game>>`, and have HomeBloc subscribe to it.

2. **Specify initial focus state**: Add to success criteria: "When the home page loads with games, the first game in the first row is automatically focused, and its hero image/gradient is displayed as the background."

3. **Specify row ordering**: Add explicit ordering: "Rows appear in the following order: Recently Added, All Games, Favorites."

4. **Specify empty row behavior**: Add: "When a row has zero games (e.g., Favorites before any games are marked), the row is hidden entirely. Only rows with at least one game are displayed."

5. **Resolve LaunchStatus inconsistency**: The assumption says "Launching is fire-and-forget. We don't track if the game process stays running" but the `LaunchStatus` enum includes `running` and `exited` states. Either:
   - Remove `running` and `exited` from the enum and simplify to `idle → launching → launched` (fire-and-forget)
   - Or remove the "fire-and-forget" assumption and actually track process status
   - **Recommendation**: Keep it simple for Sprint 4. Use `idle → launching → launched` and add a `LaunchResult` that indicates success/failure. Process tracking can be added in Sprint 6.

6. **Add HomeRepository interface definition**: Add to Section 2.1:
   ```dart
   abstract class HomeRepository {
     Future<List<HomeRow>> getHomeRows();
     Stream<List<Game>> watchAllGames(); // For reactive updates
   }
   ```

7. **Add loading and error state UI specifications**: 
   - Loading state: Show a centered spinner or shimmer skeleton matching the home page layout
   - Error state: Show an error message with a "Retry" button, styled consistently with the app's error design

### Important (Should Fix Before Implementation)

8. **Specify B/Escape behavior on home page**: Add: "When the user presses B/Escape on the home page, no action is taken (the home page is the root route)."

9. **Add responsive behavior for card rows**: Specify that card rows should adapt to screen width per the spec's breakpoint table. Add success criterion: "Card rows show appropriate number of visible cards per breakpoint (2-3 compact, 3-4 medium, 4-5 expanded, 5-7 large)."

10. **Specify sound effects for home page interactions**: Add success criteria:
    - "Focus move between cards within a row plays focus_move sound"
    - "Focus move between rows plays focus_move sound"
    - "Game launch plays focus_select sound"
    - "Row header activation plays focus_select sound"

11. **Clarify `cached_network_image` dependency**: Since Sprint 5 (API integration) isn't done yet, most games won't have hero images. The `cached_network_image` dependency should be listed as optional/deferred, or the contract should specify that local asset caching is used for now.

12. **Specify what happens when a game is launched and the user returns**: Add: "When the user returns to the home page after launching a game, the home page should restore its previous focus state (same focused game, same scroll positions)."

### Minor (Nice to Have)

13. **Add page transition animation specification**: Even if full polish is Sprint 6, the contract should note that page transitions between home and library should use the spec's defined animations (fade + slide).

14. **Specify the gradient fallback algorithm**: The `GradientGenerator.generateForGame(gameId)` method should have a note about how it generates deterministic gradients. A simple approach: use the gameId's hash to pick from a set of predefined gradient palettes.

15. **Add success criterion for background image memory management**: "When a game's hero image is no longer the focused or previously focused game, its image resource should be disposed to prevent memory buildup."

---

## Test Plan Preview

When evaluating Sprint 4, I plan to test:

1. **Home page loads with games**: Add games via the Add Game dialog, navigate to home page, verify rows appear
2. **Dynamic background changes**: Navigate between cards, verify background crossfades
3. **Game info overlay updates**: Navigate between cards, verify title/description/genres update
4. **Row scrolling**: Navigate past visible cards, verify smooth scroll
5. **Row-to-row navigation**: Navigate up/down between rows, verify focus moves correctly
6. **Game launching**: Press A on a card, verify launch overlay appears and game starts
7. **Empty state**: Clear all games, verify empty state with CTA appears
8. **Gradient fallback**: Add a game without metadata, verify gradient appears as background
9. **Home page refresh**: Add a game, return to home, verify new game appears in rows
10. **Game deletion refresh**: Delete a game from library, return to home, verify game is removed
11. **Error handling**: Try to launch a game with a missing executable, verify error handling
12. **Focus state persistence**: Launch a game, close it, return to home, verify focus is restored
13. **Row header navigation**: Focus on "All Games" header, press A, verify navigation to library
14. **Responsive layout**: Resize window, verify card rows adapt

---

## Build on Sprint 3 Foundation

The contract correctly identifies Sprint 3 dependencies and plans to reuse:
- ✅ GameCard widget (Sprint 2/3)
- ✅ GameRepository (Sprint 3)
- ✅ GameLibraryBloc pattern (Sprint 3)
- ✅ GameModel/Entity (Sprint 3)
- ✅ FocusTraversalService (Sprint 2)
- ✅ SoundService (Sprint 2)
- ✅ TopBar (Sprint 2)
- ✅ Theme system (Sprint 1)
- ✅ i18n system (Sprint 1)

### Concerns About Sprint 3 Foundation

1. **GameLauncherService is a stub**: The existing `GameLauncherService` in `lib/data/services/game_launcher_service.dart` is a stub that just prints and returns `true`. The contract correctly plans to replace this with a full implementation, but should explicitly note that this is a replacement, not a new file.

2. **HomePage is a demo placeholder**: The existing `HomePage` uses mock data and a simple `SingleChildScrollView` layout. The contract plans to completely replace this, which is correct, but should note this is a major rewrite of an existing file.

3. **GameRepository already has methods needed**: The existing `GameRepository` interface already has `getAllGames()`, `getGamesByDirectoryId()`, and `toggleFavorite()` — all needed for the home page. The `HomeRepository` should delegate to `GameRepository` rather than duplicating data access logic.

4. **GameMetadata entity already exists**: The `GameMetadata` entity already has `heroImageUrl`, `description`, `genres`, and `rating` fields. The contract correctly references `game.metadata?.heroImageUrl` in the DynamicBackground widget, which aligns with the existing data model. However, the contract should clarify how `Game` and `GameMetadata` are joined — does `HomeRepository` fetch both and return them together, or does the `Game` entity need a `metadata` field?

5. **Game entity doesn't have a metadata field**: Looking at the `Game` entity, there's no `metadata` property. The contract references `game.metadata?.heroImageUrl` in the DynamicBackground widget, but the current `Game` entity doesn't have this. The contract should specify whether:
   - A `metadata` field is added to the `Game` entity
   - Or `HomeRepository` returns a combined model (e.g., `GameWithMetadata`)
   - Or the UI fetches metadata separately

   **Recommendation**: Add an optional `GameMetadata? metadata` field to the `Game` entity, or create a `HomeGame` model that combines `Game` and `GameMetadata`.

---

## Summary

The contract is well-organized and covers the core Sprint 4 functionality. The main issues are:

| Priority | Issue | Impact |
|----------|-------|--------|
| Critical | No home page refresh mechanism when games change | Users won't see newly added games without restarting |
| Critical | No initial focus state specification | Home page may load without any focused game |
| Critical | LaunchStatus inconsistency with fire-and-forget assumption | Implementation confusion about process tracking |
| Critical | Game entity doesn't have metadata field | DynamicBackground can't access heroImageUrl as specified |
| Important | No row ordering specification | Rows may appear in wrong order |
| Important | No empty row behavior specification | Empty Favorites row may show as blank |
| Important | No loading/error state UI specification | Home page may show blank screen during loading |
| Important | No B/Escape behavior specification | Gamepad navigation incomplete |
| Important | No responsive behavior for card rows | Layout may break on different screen sizes |
| Minor | No sound effect specifications for home page | Inconsistent audio experience |
| Minor | cached_network_image dependency may be premature | Unnecessary dependency for Sprint 4 |

**Recommendation**: Address the 4 critical issues and at least the important issues before proceeding with implementation. The contract is about 80% complete — the remaining 20% is critical for a functional home page.
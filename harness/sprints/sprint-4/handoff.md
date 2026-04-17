# Handoff: Sprint 4

## Status: Fixed — Ready for Re-evaluation

## Fixes Applied (Post-Evaluation Round 1)

### 1. Critical Bug: Wire up reactive data updates ✅
**Problem**: `HomeRepositoryImpl.notifyGamesChanged()` was never called after adding or deleting games, so the home page never automatically updated.

**Solution**:
- Injected `HomeRepositoryImpl` into `AddGameBloc` and called `notifyGamesChanged()` after:
  - `_onConfirmManualAdd`: After successfully adding a single game
  - `_onConfirmScanSelection`: After adding multiple games from scan results
- Injected `HomeRepositoryImpl` into `GameLibraryBloc` and called `notifyGamesChanged()` after:
  - `_onDeleteGame`: After successfully deleting a game
- Updated DI registrations in `di.dart` to inject `HomeRepositoryImpl` into both blocs

**Files Modified**:
- `lib/presentation/blocs/add_game/add_game_bloc.dart`
- `lib/presentation/blocs/game_library/game_library_bloc.dart`
- `lib/app/di.dart`

### 2. Major Bug: Fix HomeBloc lifecycle management ✅
**Problem**: `HomeBloc` was registered as a factory and created manually in `HomePage.initState()`, causing potential memory leaks as `close()` was never called.

**Solution**:
- Wrapped `HomePage` with `BlocProvider` in `router.dart` that:
  - Creates the `HomeBloc` with proper dependencies
  - Dispatches `HomeLoadRequested` on creation
  - Automatically disposes the bloc when the page is destroyed
- Removed manual bloc creation from `HomePage.initState()`

**Files Modified**:
- `lib/app/router.dart`
- `lib/presentation/pages/home_page.dart`

### 3. Minor Bug: Remove the 2-row display limit ✅
**Problem**: `home_page.dart` limited display to 2 rows maximum (`i < 2`), preventing all non-empty rows from showing.

**Solution**:
- Changed the loop condition from `i < state.rows.length && i < 2` to `i < state.rows.length`
- Updated the spacer condition from `i < state.rows.length - 1 && i < 1` to `i < state.rows.length - 1`

**Files Modified**:
- `lib/presentation/pages/home_page.dart`

### 4. Minor Bug: Replace hardcoded strings with i18n keys ✅
**Problem**: `empty_home_state.dart` had hardcoded strings:
- Line 104: `'Add your first game to get started'`
- Line 133: `'Scan Directory'`

**Solution**:
- Added new i18n keys to `app_en.arb` and `app_zh.arb`:
  - `emptyStateSubtitle`: "Add your first game to get started"
  - `buttonScanDirectory`: "Scan Directory"
- Added missing implementations to `app_localizations.dart`, `app_localizations_en.dart`, and `app_localizations_zh.dart`:
  - `homeRowRecentlyAdded`, `homeRowAllGames`, `homeRowFavorites`
  - `noDescriptionAvailable`, `buttonRetry`, `errorLoadGames`
  - `launchingGame(String gameName)`
- Updated `empty_home_state.dart` to use `l10n?.emptyStateSubtitle` and `l10n?.buttonScanDirectory`

**Files Modified**:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_zh.dart`
- `lib/presentation/widgets/home/empty_home_state.dart`

### 5. Minor Bug: Add missing widget tests ✅
**Problem**: Contract specified widget tests for `DynamicBackground`, `GameInfoOverlay`, and `GameCardRow`, but only `DynamicBackground` had tests.

**Solution**:
- Created `test/presentation/widgets/home/game_info_overlay_test.dart` with 10 tests:
  - Returns `SizedBox.shrink` when game is null
  - Returns `SizedBox.shrink` when not visible
  - Displays game title when game is provided
  - Displays description placeholder
  - Uses correct styling for title (32px, bold)
  - Description has max 3 lines with ellipsis
  - Uses `AnimatedOpacity` with correct duration (300ms) and curve (easeInOut)
  - Has gradient background decoration
  - Genre chips section exists
  - Updates when game changes

- Created `test/presentation/widgets/home/game_card_row_test.dart` with 13 tests:
  - Renders row header with title
  - Renders correct number of game cards
  - Shows navigation arrow for navigable rows
  - Hides navigation arrow for non-navigable rows
  - Header has focus node
  - Calls `onHeaderFocused` when header receives focus
  - Calls `onHeaderActivated` when header is tapped
  - Uses correct row type titles (Recently Added, All Games, Favorites)
  - Favorites row shows correct title
  - Handles empty game list
  - `isRowFocused` parameter affects visual state
  - Has horizontal `ListView`
  - Applies padding to card list

**Files Created**:
- `test/presentation/widgets/home/game_info_overlay_test.dart`
- `test/presentation/widgets/home/game_card_row_test.dart`

---

## Original Handoff Content Below

## What to Test

### 1. Home Page Layout
1. Launch the application
2. Verify the home page displays with:
   - Full-viewport background area
   - Game info overlay at bottom-left
   - Card rows below the background area
   - Top bar at the top

### 2. Dynamic Background
1. Navigate between game cards using D-pad left/right
2. Verify background changes when focus moves to different games
3. Verify crossfade animation is smooth (500ms)
4. If no games have hero images (expected in Sprint 4), verify gradient fallback appears

### 3. Game Info Overlay
1. Focus on a game card
2. Verify overlay shows:
   - Game title (large, bold)
   - "No description available" placeholder (since metadata not yet implemented)
3. Verify overlay updates when focus changes

### 4. Horizontal Card Rows
1. Verify rows appear in order: Recently Added → All Games
2. Verify "Recently Added" is sorted by date (newest first)
3. Navigate within a row using D-pad left/right
4. Navigate between rows using D-pad up/down
5. Verify smooth scroll animation when navigating past visible cards
6. Focus on "All Games" row header and press A - should navigate to Library page

### 5. Game Launching
1. Focus on a game card
2. Press A button
3. Verify "Launching [Game Name]..." overlay appears
4. Verify overlay auto-dismisses after 2 seconds

### 6. Empty State
1. Clear all games from library (or test with fresh database)
2. Verify empty state appears with:
   - Large icon
   - "Your game library is empty" message
   - "Add your first game" CTA button
3. Verify "Add Game" button opens the Add Game dialog

### 7. Error State
1. Simulate a database error (can be done by temporarily breaking the database connection)
2. Verify error state appears with:
   - Error icon
   - "Failed to load games" message
   - "Retry" button
3. Verify Retry button reloads the data

### 8. Sound Effects
1. Navigate between cards - should hear focus move sound
2. Activate a game or row header - should hear focus select sound
3. Navigate to library from row header - should hear page transition sound

### 9. Gamepad Navigation
1. D-pad left/right: Navigate within row
2. D-pad up/down: Navigate between rows
3. A button: Activate focused element
4. B/Escape: Should do nothing on home page (already at root)

## Running the Application

```bash
# Navigate to project directory
cd /home/simooo/work/flutter/squirrel_play

# Ensure dependencies are installed
flutter pub get

# Run the application
flutter run -d windows
```

## Test Commands

```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/presentation/blocs/home/home_bloc_test.dart
flutter test test/data/services/game_launcher_service_test.dart
flutter test test/presentation/widgets/home/dynamic_background_test.dart

# Run analysis
flutter analyze
```

## Known Limitations

1. **No Real Hero Images**: Games will show gradient fallback instead of hero images because Sprint 5 (API integration) is not yet implemented.

2. **No Game Descriptions**: Info overlay will show "No description available" placeholder because metadata is not yet fetched.

3. **Empty Favorites Row**: The "Favorites" row will always be hidden in Sprint 4 because there's no way to mark favorites yet (coming in Sprint 6).

4. **Fire-and-Forget Launching**: After launching a game, we don't track if it stays running. Process monitoring comes in Sprint 6.

## Files Changed/Created

### New Files (21)
- `lib/domain/entities/home_row.dart`
- `lib/domain/repositories/home_repository.dart`
- `lib/domain/services/game_launcher.dart`
- `lib/data/repositories/home_repository_impl.dart`
- `lib/data/services/game_launcher_service.dart`
- `lib/presentation/blocs/home/home_bloc.dart`
- `lib/presentation/blocs/home/home_event.dart`
- `lib/presentation/blocs/home/home_state.dart`
- `lib/presentation/widgets/home/dynamic_background.dart`
- `lib/presentation/widgets/home/game_info_overlay.dart`
- `lib/presentation/widgets/home/game_card_row.dart`
- `lib/presentation/widgets/home/empty_home_state.dart`
- `lib/presentation/widgets/home/loading_home_state.dart`
- `lib/presentation/widgets/home/error_home_state.dart`
- `lib/presentation/widgets/home/launch_overlay.dart`
- `lib/core/utils/gradient_generator.dart`
- `test/presentation/blocs/home/home_bloc_test.dart`
- `test/data/services/game_launcher_service_test.dart`
- `test/presentation/widgets/home/dynamic_background_test.dart`

### Modified Files (6)
- `lib/presentation/pages/home_page.dart` (complete rewrite)
- `lib/app/di.dart` (added HomeRepository, GameLauncher, HomeBloc registrations)
- `lib/app/router.dart` (added page transitions)
- `lib/l10n/app_localizations.dart` (added new strings)
- `lib/l10n/app_localizations_en.dart` (added English translations)
- `lib/l10n/app_localizations_zh.dart` (added Chinese translations)
- `pubspec.yaml` (added bloc_test, mocktail dependencies)

## Verification Checklist

- [ ] Home page loads without errors
- [ ] Background changes when navigating between games
- [ ] Card rows scroll horizontally
- [ ] Row headers are focusable and navigable
- [ ] Game launching shows overlay
- [ ] Empty state appears when no games
- [ ] Error state appears on failure
- [ ] Sound effects play on interactions
- [ ] All tests pass
- [ ] flutter analyze shows zero errors/warnings

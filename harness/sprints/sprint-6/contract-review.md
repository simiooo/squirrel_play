# Contract Review: Sprint 6

## Assessment: CHANGES_REQUESTED

The contract is comprehensive and covers the right scope for a final sprint, but it has several significant issues that must be addressed before implementation begins. The most critical problems are: (1) proposing to "create" files that already exist, (2) missing integration details for features whose data layer already exists, and (3) a few gaps in the specification that would lead to incomplete implementation.

---

## Scope Coverage

The contract covers all remaining features from the spec: responsive design, i18n completion, language switching, animation refinement, sound effects, launch confirmation, favorites, play tracking, recently played, settings page, error states, empty states, and window management. This is the correct scope for the final sprint.

**However**, the contract overstates the amount of new work needed because several features already have partial implementations from earlier sprints. The contract should explicitly acknowledge what already exists and specify modifications rather than creation for these items.

---

## Success Criteria Review

### SC1: Responsive Design — ADEQUATE
Clear breakpoint values and card dimensions. Testable by resizing the window.

### SC2: i18n Coverage — NEEDS REVISION
The verification criterion `grep -r "Text('" lib/presentation/ --include="*.dart" | wc -l` returning 0 is **too strict and unrealistic**. Many `Text()` widgets legitimately use non-user-facing strings (numbers, symbols, formatting characters, empty strings). A better criterion would be: "No hardcoded user-facing English strings remain in widget code. All visible labels, titles, messages, button text, error messages, and accessibility hints are extracted to ARB files."

### SC3: Language Switching — ADEQUATE
Clear and testable. Language changes immediately, persists across restarts, defaults to device locale.

### SC4: Animation Timing — ADEQUATE WITH CAVEAT
The criterion says "all animations match the design spec timing." This should specify that the **code** uses the correct Duration and Curve values, since animation "feel" is subjective. The contract's table of exact durations and curves is excellent — verification should check the code values, not subjective feel.

### SC5: Sound Effects — NEEDS REVISION
The contract proposes creating `lib/core/services/sound_service.dart`, but **this file already exists** at `lib/data/services/sound_service.dart`. The existing `SoundService` already:
- Uses `audioplayers` package
- Has all 5 sound types (focus_move, focus_select, focus_back, page_transition, error)
- Handles missing files gracefully (try-catch with debug-only logging)
- Has volume control and mute support
- Has focus move debouncing (80ms)

The contract should specify **modifications** to the existing `SoundService`, not creation of a new one. Specifically, the contract should address:
- Moving the service from `data/services/` to `core/services/` (if desired for architectural reasons)
- Adding any missing functionality (e.g., preloading sounds on startup, which the current service does lazily)
- Ensuring the Settings page can control volume/mute through the existing service

### SC6: Game Launch Confirmation — NEEDS REVISION
The contract proposes creating `lib/presentation/widgets/launch_confirmation_overlay.dart`, but **`lib/presentation/widgets/home/launch_overlay.dart` already exists**. The current overlay is a simple spinner + message. The contract correctly identifies that it needs enhancement (game cover image, B-to-cancel, countdown), but should specify **modifying** the existing file, not creating a new one.

Additionally, the contract says "Auto-dismiss after 1.5 seconds" but the current `GameLauncherService` uses a 2-second reset timer. These should be consistent. The contract should specify whether the overlay countdown replaces the service's reset timer or works alongside it.

### SC7: Favorites System — NEEDS REVISION
The contract proposes modifying several files for favorites, but **the data layer already exists**:
- `Game.isFavorite` field ✅ already exists
- `GameRepository.toggleFavorite()` ✅ already exists
- `HomeRepositoryImpl` creates a Favorites row ✅ already exists
- `HomeRowType.favorites` ✅ already exists

What's actually missing is **only the UI layer**:
- Star icon on game cards
- Y button toggle handler
- Visual feedback (toast/snackbar) when toggling favorite
- The `GameInfoOverlay` favorite toggle button

The contract should clearly distinguish what's new vs. what already exists to avoid redundant work or conflicting implementations.

### SC8: Play Count Tracking — NEEDS REVISION
Same issue: **the data layer already exists**:
- `Game.playCount` field ✅ already exists
- `GameRepository.incrementPlayCount()` ✅ already exists

What's missing:
- Calling `incrementPlayCount()` when a game is launched
- Displaying "Played X times" / "Never played" in the `GameInfoOverlay`

The contract should specify **how** `incrementPlayCount` gets called. Currently, `GameLauncherService.launchGame()` doesn't have access to `GameRepository`. The contract should specify the integration point — either:
  - The `HomeBloc`/`LibraryBloc` calls `incrementPlayCount` after successful launch, OR
  - The `GameLauncherService` is given a reference to `GameRepository`, OR
  - A new use case/interactor coordinates the launch + count increment

### SC9: Recently Played — NEEDS REVISION
Same issue: **the data layer already exists**:
- `Game.lastPlayedDate` field ✅ already exists
- `GameRepository.updateLastPlayed()` ✅ already exists

What's missing:
- **`HomeRowType.recentlyPlayed`** — this enum value does NOT exist yet and must be added
- Calling `updateLastPlayed()` when a game is launched (same integration question as above)
- "Recently Played" row on the home page
- "Last played: X ago" display in `GameInfoOverlay`

The contract doesn't mention adding `recentlyPlayed` to the `HomeRowType` enum. This is a **required change** that must be explicitly listed.

### SC10: Settings Page — ADEQUATE
Clear and testable. New page with language selection, API key config, sound settings, and about section.

### SC11: Error States — NEEDS REVISION
The contract proposes creating new error widget files, but **`error_home_state.dart` and `error_state_widget.dart` already exist**. The contract should specify whether these are being replaced, extended, or supplemented. The existing error widgets should be reviewed and either enhanced or replaced with the more specific error types (database, API, missing executable, generic).

### SC12: Empty States — NEEDS REVISION
Same issue: **`empty_home_state.dart` and `empty_state_widget.dart` already exist**. The contract should specify whether these are being replaced or enhanced with SVG illustrations.

### SC13: Window Management — ADEQUATE
Clear and testable. Window title, minimum size, fullscreen toggle.

### SC14: Test Coverage — ADEQUATE
≥25 new tests, all tests pass, coverage includes key new features.

---

## Suggested Changes

### 1. **Acknowledge existing implementations** (CRITICAL)
The contract must explicitly list which files/features already exist and specify modifications rather than creation for:
- `SoundService` (already at `lib/data/services/sound_service.dart`)
- `Breakpoints`/`CardDimensions`/`VisibleCardCount` (already at `lib/core/utils/breakpoints.dart`)
- `LaunchOverlay` (already at `lib/presentation/widgets/home/launch_overlay.dart`)
- `Game.isFavorite`, `GameRepository.toggleFavorite()`, favorites row in `HomeRepositoryImpl`
- `Game.playCount`, `GameRepository.incrementPlayCount()`
- `Game.lastPlayedDate`, `GameRepository.updateLastPlayed()`
- Error state widgets (`error_home_state.dart`, `error_state_widget.dart`)
- Empty state widgets (`empty_home_state.dart`, `empty_state_widget.dart`)
- i18n infrastructure (`AppLocalizations` with ~30 existing keys)

### 2. **Add `HomeRowType.recentlyPlayed`** (CRITICAL)
The `HomeRowType` enum in `lib/domain/entities/home_row.dart` currently has `recentlyAdded`, `allGames`, `favorites`. It needs `recentlyPlayed` added. The `HomeRepositoryImpl.getHomeRows()` must be updated to create a "Recently Played" row sorted by `lastPlayedDate` descending.

### 3. **Specify the launch integration for play count and last played** (CRITICAL)
The contract must specify how `incrementPlayCount()` and `updateLastPlayed()` are called when a game is launched. Options:
- **Recommended**: The `HomeBloc` (or a coordinating use case) calls these methods after `GameLauncher.launchGame()` succeeds. The `GameLauncherService` should emit a success event that the BLoC listens to.
- The `GameLauncherService` should NOT directly depend on `GameRepository` (Clean Architecture violation — service in data layer shouldn't know about domain repository).

### 4. **Specify metadata integration in HomeBloc** (IMPORTANT)
The `HomeLoaded` state currently has `focusedGame` but no `focusedGameMetadata`. The `GameInfoOverlay` accepts a `metadata` parameter but the `HomePage` never passes metadata to it. The contract should specify:
- Adding `focusedGameMetadata` to `HomeLoaded` state
- Fetching metadata when the focused game changes
- Passing metadata to `GameInfoOverlay`

### 5. **Fix SC2 i18n verification criterion** (IMPORTANT)
Replace the grep-based criterion with: "No hardcoded user-facing English strings remain in widget code. All visible labels, titles, messages, button text, error messages, and accessibility hints are extracted to ARB files. `app_en.arb` contains ≥50 keys. `app_zh.arb` contains all keys from `app_en.arb`."

### 6. **Clarify locale management architecture** (IMPORTANT)
The contract proposes creating both `locale_provider.dart` (ChangeNotifier) and `locale_cubit.dart` (BLoC). This is redundant — pick one approach. Since the app uses BLoC/Cubit throughout, use a `LocaleCubit` that wraps `shared_preferences` for persistence and notifies `MaterialApp` of locale changes. Remove the `locale_provider.dart` proposal.

### 7. **Clarify launch overlay behavior** (MINOR)
The contract says "Auto-dismiss after 1.5 seconds" but the current `GameLauncherService` resets status to idle after 2 seconds. These should be aligned. Recommend: the overlay auto-dismisses after 1.5 seconds, and the game launch happens immediately (not after the overlay dismisses). The overlay is just a visual confirmation, not a delay mechanism.

### 8. **Specify how Settings page connects to locale changes** (MINOR)
The `SquirrelPlayApp` widget in `app.dart` currently uses `localeResolutionCallback` but doesn't have a reactive locale. The contract should specify that a `LocaleCubit` is provided at the app level and `MaterialApp.router` listens to its state for locale changes.

### 9. **Address GameInfoOverlay metadata gap** (MINOR)
The `GameInfoOverlay` currently shows game title, description, genres, rating, and screenshots from metadata, but the `HomePage` doesn't pass metadata to it. The contract should specify that the `HomeBloc` fetches and provides metadata for the focused game, and the `HomePage` passes it to `GameInfoOverlay`.

### 10. **Specify responsive_layout_builder.dart behavior** (MINOR)
The contract proposes creating `responsive_layout_builder.dart` but doesn't specify what it does beyond "create responsive layout widget." It should be a widget that uses `LayoutBuilder` + `Breakpoints` to switch between layout variants, similar to Flutter's `LayoutBuilder` pattern. The contract should specify its API (e.g., `ResponsiveLayoutBuilder(breakpoints: {...}, compact: ..., medium: ..., expanded: ..., large: ...)`).

---

## Test Plan Preview

1. **Responsive Design**: Resize window to each breakpoint boundary (639px, 640px, 1023px, 1024px, 1439px, 1440px) and verify layout adapts. Verify card sizes match spec at each breakpoint.

2. **i18n**: Switch language in settings → verify all visible strings change. Restart app → verify language persists. Verify Chinese translations are complete.

3. **Language Switching**: Change language → verify immediate UI update without restart. Verify `shared_preferences` stores the selection.

4. **Animation Timing**: Inspect code for correct Duration and Curve values. Verify card focus animation is 200ms/easeOutCubic. Verify background crossfade is 500ms/easeInOut.

5. **Sound Effects**: Verify sounds play when files exist. Verify app works silently when files don't exist. Verify volume control in settings affects playback.

6. **Launch Confirmation**: Press A on game → overlay appears with game name and cancel hint. Press B → overlay closes, game doesn't launch. Wait 1.5s → overlay dismisses, game launches.

7. **Favorites**: Press Y on game → star appears, "Added to favorites" feedback. Verify Favorites row appears on home. Press Y again → star removed. Verify persistence across restart.

8. **Play Count**: Launch game → verify play count increments in database. Verify "Played X times" shows in game info overlay. Verify "Never played" shows for unplayed games.

9. **Recently Played**: Launch game → verify it appears in "Recently Played" row. Verify row is sorted by most recent. Verify "Last played: X ago" shows in game info overlay.

10. **Settings**: Navigate to settings → verify language selection, API key config, sound settings, about section all work.

11. **Error States**: Trigger database error → verify error widget with retry. Trigger API error → verify error widget with retry. Launch game with missing executable → verify error widget with browse/remove options.

12. **Empty States**: Verify no-games state shows illustration and "Add Game" CTA. Verify no-search-results state. Verify API-unreachable state.

13. **Window Management**: Verify window title is "Squirrel Play". Verify window can't be resized below 800×600. Verify F11 toggles fullscreen.

---

## Summary

The contract has the right scope and covers all remaining spec features, but it needs revision to:
1. Acknowledge existing implementations instead of proposing to recreate them
2. Add `HomeRowType.recentlyPlayed` to the enum
3. Specify the integration point for play count and last played updates on game launch
4. Specify metadata integration in `HomeBloc` for the game info overlay
5. Fix the i18n verification criterion
6. Choose one locale management approach (Cubit, not both ChangeNotifier and Cubit)
7. Clarify launch overlay timing vs. game launcher timing

These are all addressable issues. Once fixed, the contract will be ready for implementation.
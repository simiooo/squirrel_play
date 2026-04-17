# Sprint Contract: Sprint 6 — Polish — Responsive Design, i18n Completion, Sound & Animation Refinement

## 1. Sprint Goal and Scope

**Goal:** Deliver a production-ready, polished game library application with complete responsive design, full internationalization, refined animations, sound effects, favorites system, play tracking, settings page, comprehensive error handling, and window management.

**Scope:** This is the **FINAL SPRINT**. All remaining features from the product specification will be implemented to achieve a complete, shippable v1.0 of Squirrel Play.

---

## 2. Existing Implementations (Already Complete)

The following features have partial or complete implementations from previous sprints. The contract specifies **modifications** to these, not creation of duplicates:

| Feature | Existing Location | Status |
|---------|-------------------|--------|
| SoundService | `lib/data/services/sound_service.dart` | ✅ Exists — needs Settings integration |
| Breakpoints | `lib/core/utils/breakpoints.dart` | ✅ Exists — may need refinement |
| LaunchOverlay | `lib/presentation/widgets/home/launch_overlay.dart` | ✅ Exists — needs enhancement |
| Game.isFavorite | `lib/domain/entities/game.dart` | ✅ Exists |
| GameRepository.toggleFavorite() | `lib/domain/repositories/game_repository.dart` | ✅ Exists |
| Favorites row | `lib/data/repositories/home_repository_impl.dart` | ✅ Exists in getHomeRows() |
| HomeRowType.favorites | `lib/domain/entities/home_row.dart` | ✅ Exists |
| Game.playCount | `lib/domain/entities/game.dart` | ✅ Exists |
| GameRepository.incrementPlayCount() | `lib/domain/repositories/game_repository.dart` | ✅ Exists |
| Game.lastPlayedDate | `lib/domain/entities/game.dart` | ✅ Exists |
| GameRepository.updateLastPlayed() | `lib/domain/repositories/game_repository.dart` | ✅ Exists |
| Error state widgets | `lib/presentation/widgets/home/error_home_state.dart`, `error_state_widget.dart` | ✅ Exist — may need enhancement |
| Empty state widgets | `lib/presentation/widgets/home/empty_home_state.dart`, `empty_state_widget.dart` | ✅ Exist — may need enhancement |
| i18n infrastructure | `lib/l10n/app_en.arb` (~30 keys), `AppLocalizations` | ✅ Exists — needs completion |

---

## 3. Detailed Deliverables

### 3.1 Responsive Design Implementation

**Files to Modify:**
- `lib/core/utils/breakpoints.dart` — Review and refine breakpoint constants per spec
- `lib/presentation/widgets/responsive_layout_builder.dart` — **CREATE** responsive layout widget using LayoutBuilder + Breakpoints
- `lib/presentation/pages/home_page.dart` — Adapt layout for all breakpoints
- `lib/presentation/pages/library_page.dart` — Adapt grid for all breakpoints
- `lib/presentation/widgets/game_card.dart` — Responsive card sizing
- `lib/presentation/widgets/game_card_row.dart` — Responsive row sizing and visible card count
- `lib/presentation/widgets/top_bar.dart` — Collapse to hamburger on compact

**ResponsiveLayoutBuilder API:**
```dart
ResponsiveLayoutBuilder({
  required Map<Breakpoint, Widget> builders,
  required Breakpoint fallback,
})
```

**Implementation Details:**
| Breakpoint | Width | Card Size | Visible Cards | Layout Changes |
|------------|-------|-----------|---------------|----------------|
| Compact | < 640px | 140×210 | 2-3 | Top bar → hamburger menu, vertical scrolling fallback |
| Medium | 640–1024px | 170×255 | 3-4 | Standard horizontal rows |
| Expanded | 1024–1440px | 200×300 | 4-5 | Full layout as currently implemented |
| Large | > 1440px | 240×360 | 5-7 | Extra spacing, wider content area |

### 3.2 Internationalization (i18n) Completion

**Files to Modify:**
- `lib/l10n/app_en.arb` — Complete English strings (expand to ≥50 keys)
- `lib/l10n/app_zh.arb` — Complete Chinese Simplified strings (match all English keys)
- `lib/core/i18n/locale_cubit.dart` — **CREATE** BLoC for locale management (uses shared_preferences)
- `lib/main.dart` — Add locale delegation, locale resolution
- `lib/app/app.dart` — Connect LocaleCubit to MaterialApp.router
- All widget files — Replace hardcoded user-facing strings with `AppLocalizations.of(context).key`

**String Keys to Extract (minimum 50 keys):**
```
# Navigation
topBar.addGame, topBar.library, topBar.rescan, topBar.settings
topBar.timeFormat, topBar.batteryStatus

# Home Page
home.rows.recentlyAdded, home.rows.allGames, home.rows.favorites, home.rows.recentlyPlayed
home.emptyState.title, home.emptyState.message, home.emptyState.cta
home.focusOverlay.launchHint, home.focusOverlay.detailsHint

# Library Page
library.title, library.emptyState.title, library.emptyState.message
library.sort.name, library.sort.dateAdded, library.sort.lastPlayed, library.sort.playCount

# Add Game Dialog
addGame.title, addGame.manualTab, addGame.scanTab
addGame.manual.nameLabel, addGame.manual.pathLabel, addGame.manual.browseButton
addGame.scan.selectDirectories, addGame.scan.scanningProgress, addGame.scan.executablesFound
addGame.scan.confirmSelection, addGame.scan.noExecutablesFound

# Game Info Overlay
gameInfo.launchButton, gameInfo.favoriteButton, gameInfo.unfavoriteButton
gameInfo.playCount, gameInfo.lastPlayed, gameInfo.neverPlayed
gameInfo.genres, gameInfo.rating, gameInfo.releaseDate, gameInfo.developer

# Metadata
gameInfo.description.loading, gameInfo.description.empty
gameInfo.metadata.fetching, gameInfo.metadata.retryButton, gameInfo.metadata.manualSearch

# Settings Page
settings.title, settings.language.title, settings.language.english, settings.language.chinese
settings.apiKey.title, settings.apiKey.label, settings.apiKey.placeholder, settings.apiKey.saveButton
settings.apiKey.degradedMode, settings.apiKey.helpText
settings.about.title, settings.about.version, settings.about.credits

# Errors & Notifications
error.generic.title, error.generic.message, error.generic.retry
error.database.title, error.database.message
error.api.title, error.api.message
error.fileNotFound.title, error.fileNotFound.message
error.missingExecutable.title, error.missingExecutable.message

# Launch Confirmation
launch.confirmation.title, launch.confirmation.message, launch.confirmation.cancel

# Favorites
favorites.added, favorites.removed, favorites.emptyState

# Gamepad Hints
gamepad.aButton.select, gamepad.bButton.back, gamepad.xButton.details
gamepad.yButton.favorite, gamepad.startButton.menu, gamepad.backButton.home
```

### 3.3 Language Switching

**Files to Create:**
- `lib/presentation/widgets/language_selector.dart` — Dropdown/language picker widget

**Files to Modify:**
- `lib/presentation/widgets/top_bar.dart` — Add language selector button/dropdown
- `lib/presentation/pages/settings_page.dart` — Language selection section
- `lib/app/app.dart` — MaterialApp.router listens to LocaleCubit state for locale changes

**Behavior:**
- Language changes immediately without app restart
- Selected locale persisted to `shared_preferences` via LocaleCubit
- On app launch, load saved locale or use device locale as fallback
- LocaleCubit provided at app level for reactive updates

### 3.4 Animation Timing Refinements

**Files to Modify:**
- `lib/presentation/widgets/game_card.dart` — Card focus animations
- `lib/presentation/widgets/focusable_button.dart` — Button focus animations
- `lib/presentation/widgets/game_card_row.dart` — Row scroll animations
- `lib/presentation/widgets/dynamic_background.dart` — Background crossfade
- `lib/presentation/widgets/game_info_overlay.dart` — Overlay transitions
- `lib/presentation/dialogs/*.dart` — Dialog open/close animations

**Animation Standards (per spec):**
| Animation | Duration | Curve | Effect |
|-----------|----------|-------|--------|
| Card Focus In | 200ms | easeOutCubic | Scale 1.0 → 1.08, glow border |
| Card Focus Out | 150ms | easeInCubic | Scale 1.08 → 1.0, glow fade |
| Button Focus In | 150ms | easeOut | Background shift, accent underline |
| Button Focus Out | 100ms | easeIn | Reverse |
| Background Crossfade | 500ms | easeInOut | Opacity 0→1 |
| Page Enter | 300ms | easeOutCubic | Fade + slide up 16px |
| Page Exit | 200ms | easeInCubic | Fade + slide down |
| Dialog Open | 200ms | easeOutBack | Scale 0.95→1.0 + fade |
| Dialog Close | 150ms | easeIn | Scale 1.0→0.95 + fade |
| Row Scroll | 250ms | easeOutCubic | Parallax shift |
| Shimmer | 1500ms | linear | Left-to-right sweep, repeating |

### 3.5 Sound Effect Integration

**Files to Modify:**
- `lib/data/services/sound_service.dart` — **MODIFY** to add Settings integration (volume/mute control from Settings page)
- `lib/presentation/blocs/navigation/navigation_bloc.dart` — Play sounds on navigation
- `lib/presentation/widgets/game_card.dart` — Play focus sound
- `lib/presentation/widgets/focusable_button.dart` — Play focus/select sounds
- `pubspec.yaml` — Ensure assets/sounds/ directory is referenced

**Sound Files (placeholders documented):**
| Event | File Path | Fallback Behavior |
|-------|-----------|-------------------|
| Focus Move | `assets/sounds/focus_move.wav` | Silent (no error) |
| Focus Select | `assets/sounds/focus_select.wav` | Silent (no error) |
| Focus Back | `assets/sounds/focus_back.wav` | Silent (no error) |
| Page Transition | `assets/sounds/page_transition.wav` | Silent (no error) |
| Error | `assets/sounds/error.wav` | Silent (no error) |

**Sound Service Requirements:**
- Uses `audioplayers` package (already in pubspec)
- Preloads sounds on app start (async, non-blocking) — **ADD if not present**
- Gracefully handles missing files (try-catch, log only in debug) — **VERIFY existing**
- Volume control support (0.0 - 1.0) — **VERIFY existing**
- Mute toggle support — **VERIFY existing**
- Settings page can control volume/mute through the service — **ADD**

### 3.6 Game Launch Confirmation

**Files to Modify:**
- `lib/presentation/widgets/home/launch_overlay.dart` — **ENHANCE** existing overlay with:
  - Game cover image display
  - "Launching [Game Name]..." message
  - "Press B to cancel" hint
  - Countdown/progress indicator
  - Fade + scale animation for appearance
- `lib/presentation/pages/home_page.dart` — Show enhanced overlay before launching
- `lib/presentation/pages/library_page.dart` — Show enhanced overlay before launching
- `lib/core/services/game_launcher_service.dart` — Coordinate with overlay timing

**Behavior:**
- When user presses A on a game card, show overlay: "Launching [Game Name]..."
- Overlay displays game cover image, title, and "Press B to cancel" hint
- Auto-dismiss after **2 seconds** (aligned with GameLauncherService reset timer) and execute game
- If user presses B during countdown, cancel launch and dismiss overlay
- Uses fade + scale animation for appearance

### 3.7 Favorites System (UI Layer Only)

**Files to Modify:**
- `lib/presentation/widgets/game_card.dart` — Add favorite indicator (star icon)
- `lib/presentation/widgets/game_info_overlay.dart` — Add favorite toggle button
- `lib/presentation/blocs/home/home_bloc.dart` — Add Y button handler for favorite toggle
- `lib/presentation/blocs/library/library_bloc.dart` — Add Y button handler for favorite toggle

**UI Requirements:**
- Star icon on game cards (filled if favorite, outline if not)
- "Favorites" row on home page (first row, if any favorites exist) — **already exists**
- Y button toggles favorite on focused game
- Visual feedback when favorite status changes (brief toast/snackbar indicator)

### 3.8 Play Count Tracking (Integration & UI)

**Files to Modify:**
- `lib/presentation/blocs/home/home_bloc.dart` — Call `gameRepository.incrementPlayCount()` after successful game launch
- `lib/presentation/blocs/library/library_bloc.dart` — Call `gameRepository.incrementPlayCount()` after successful game launch
- `lib/presentation/widgets/game_info_overlay.dart` — Display play count

**Integration Specification:**
- After `GameLauncher.launchGame()` succeeds, the BLoC calls `gameRepository.incrementPlayCount(gameId)`
- The `GameLauncherService` should NOT directly depend on `GameRepository` (Clean Architecture)
- Display Format: "Played X times" (X = count) or "Never played" (if count = 0)

### 3.9 Last Played Sorting (Integration & UI)

**Files to Modify:**
- `lib/domain/entities/home_row.dart` — **ADD** `HomeRowType.recentlyPlayed` to enum
- `lib/data/repositories/home_repository_impl.dart` — Add "Recently Played" row sorted by `lastPlayedDate` descending
- `lib/presentation/blocs/home/home_bloc.dart` — Call `gameRepository.updateLastPlayed()` after successful game launch
- `lib/presentation/blocs/library/library_bloc.dart` — Call `gameRepository.updateLastPlayed()` after successful game launch
- `lib/presentation/widgets/game_info_overlay.dart` — Display "Last played: X ago"

**Integration Specification:**
- Add `HomeRowType.recentlyPlayed` to the enum (currently has `recentlyAdded`, `allGames`, `favorites`)
- After `GameLauncher.launchGame()` succeeds, the BLoC calls `gameRepository.updateLastPlayed(gameId)`
- `HomeRepositoryImpl.getHomeRows()` creates a "Recently Played" row sorted by `lastPlayedDate` descending
- Shows last 5-10 recently played games
- Display "Last played: X minutes/hours/days ago" in game info overlay

### 3.10 Metadata Integration in HomeBloc

**Files to Modify:**
- `lib/presentation/blocs/home/home_state.dart` — **ADD** `focusedGameMetadata` to `HomeLoaded` state
- `lib/presentation/blocs/home/home_bloc.dart` — Fetch metadata when focused game changes
- `lib/presentation/pages/home_page.dart` — Pass metadata to `GameInfoOverlay`

**Integration Specification:**
- `HomeLoaded` state includes `focusedGameMetadata: GameMetadata?` field
- When `focusedGame` changes, the BLoC fetches metadata via `MetadataRepository`
- `HomePage` passes `focusedGameMetadata` to `GameInfoOverlay` widget

### 3.11 Settings Page

**Files to Create:**
- `lib/presentation/pages/settings_page.dart` — Full settings page
- `lib/presentation/blocs/settings/settings_bloc.dart` — Settings state management
- `lib/presentation/blocs/settings/settings_event.dart`
- `lib/presentation/blocs/settings/settings_state.dart`

**Files to Modify:**
- `lib/presentation/widgets/top_bar.dart` — Add settings button (gear icon)
- `lib/app/router.dart` — Add settings route

**Settings Sections:**
1. **Language Selection**
   - Radio buttons or dropdown: English / 中文
   - Immediate application without restart (via LocaleCubit)
   
2. **API Key Configuration**
   - Text field for RAWG API key
   - Show current key masked (e.g., "••••••••last4")
   - Save button
   - "Clear Key" button
   - Help text explaining how to get a key
   - Visual indicator: "API Connected" / "Degraded Mode"
   
3. **Sound Settings**
   - Master volume slider (0-100%)
   - Mute toggle
   - Test sound button
   
4. **About Section**
   - App name and version
   - Credits / attribution
   - Link to RAWG

### 3.12 Error States (Enhancement)

**Files to Modify:**
- `lib/presentation/widgets/home/error_home_state.dart` — **ENHANCE** or replace with specific error types
- `lib/presentation/widgets/error_state_widget.dart` — **ENHANCE** with database, API, missing executable variants
- `lib/presentation/pages/home_page.dart` — Handle database errors
- `lib/presentation/pages/library_page.dart` — Handle database errors
- `lib/presentation/blocs/home/home_bloc.dart` — Emit error states
- `lib/presentation/blocs/library/library_bloc.dart` — Emit error states

**Error UI Requirements:**
| Error Type | Visual | Action |
|------------|--------|--------|
| Database Failure | Red icon, "Database Error" title, message | Retry button |
| API Failure | Orange icon, "Connection Error" title | Retry button, Offline mode hint |
| Missing Executable | Yellow icon, "Game Not Found" title | Browse for new location button, Remove game button |
| Generic Error | Red icon, "Something Went Wrong" | Retry button, Report issue link |

### 3.13 Empty State Illustrations (Enhancement)

**Files to Modify:**
- `lib/presentation/widgets/home/empty_home_state.dart` — **ENHANCE** with SVG illustrations
- `lib/presentation/widgets/empty_state_widget.dart` — **ENHANCE** with specific variants
- `assets/images/empty_state_games.svg` — Illustration for no games
- `assets/images/empty_state_search.svg` — Illustration for no search results
- `assets/images/empty_state_api.svg` — Illustration for API unreachable

**Empty State Requirements:**
| State | Illustration | Title | Message | CTA |
|-------|--------------|-------|---------|-----|
| No Games | Controller/gamepad illustration | "No Games Yet" | "Add your first game to get started" | "Add Game" button |
| No Search Results | Magnifying glass illustration | "No Results" | "Try a different search term" | "Clear Search" button |
| API Unreachable | Cloud/disconnect illustration | "Can't Connect" | "Game info unavailable. You can still play your games." | "Retry" button |

### 3.14 Window Management

**Files to Create:**
- `lib/core/services/window_manager_service.dart` — Window state management

**Files to Modify:**
- `lib/main.dart` — Initialize window manager
- `windows/runner/main.cpp` — Set window properties (if needed)
- `pubspec.yaml` — Add `window_manager` dependency

**Window Requirements:**
- **Title:** "Squirrel Play" (set in window manager and app metadata)
- **Minimum Size:** 800×600 pixels
- **Default Size:** 1280×720 (720p) or 1920×1080 (1080p) based on screen
- **Fullscreen Support:** F11 or gamepad Start button toggles fullscreen
- **Window State Persistence:** Remember last window size/position (optional, nice-to-have)

---

## 4. Success Criteria (Testable/Verifiable)

### SC1: Responsive Design
- **Criterion:** At each breakpoint (resize window to test), layout adapts correctly
- **Verification:**
  - Compact (<640px): Top bar shows hamburger, cards are 140×210, 2-3 visible
  - Medium (640-1024px): Cards are 170×255, 3-4 visible
  - Expanded (1024-1440px): Cards are 200×300, 4-5 visible
  - Large (>1440px): Cards are 240×360, 5-7 visible

### SC2: i18n Coverage
- **Criterion:** No hardcoded user-facing English strings remain in widget code
- **Verification:**
  - All visible labels, titles, messages, button text, error messages, and accessibility hints are extracted to ARB files
  - `app_en.arb` contains ≥50 keys
  - `app_zh.arb` contains all keys from `app_en.arb`
  - App displays Chinese when language switched
  - Code review: No hardcoded strings in Text() widgets that display to users

### SC3: Language Switching
- **Criterion:** Language can be switched in-app without restart
- **Verification:**
  - Change language in settings → all UI strings update immediately
  - Selected language persists after app restart
  - Default follows device locale on first launch

### SC4: Animation Timing
- **Criterion:** Code uses correct Duration and Curve values per spec
- **Verification:**
  - Card focus in: 200ms, easeOutCubic
  - Card focus out: 150ms, easeInCubic
  - Background crossfade: 500ms, easeInOut
  - Dialog open: 200ms, easeOutBack
  - Shimmer: 1500ms, linear, repeating

### SC5: Sound Effects
- **Criterion:** Sound files play when present, app works silently when missing
- **Verification:**
  - With sound files: focus, select, back, transition, error sounds play
  - Without sound files: app functions normally, no errors in console
  - Volume control in settings affects sound playback

### SC6: Game Launch Confirmation
- **Criterion:** Launch overlay appears and functions correctly
- **Verification:**
  - Press A on game → overlay shows with game name and "Launching..."
  - Overlay auto-dismisses after 2 seconds and game launches
  - Press B during countdown → overlay closes, game does NOT launch

### SC7: Favorites System
- **Criterion:** Games can be marked favorites and appear in Favorites row
- **Verification:**
  - Press Y on focused game → star icon appears, "Added to favorites" feedback
  - Favorites row appears on home page when ≥1 favorite exists
  - Press Y on favorite → star removed, "Removed from favorites" feedback
  - Favorites persist after app restart

### SC8: Play Count Tracking
- **Criterion:** Play count increments and displays correctly
- **Verification:**
  - Launch game → play count increments in database (via BLoC calling repository)
  - Game info overlay shows "Played X times"
  - Never-played games show "Never played"

### SC9: Recently Played
- **Criterion:** Recently played games appear in dedicated row
- **Verification:**
  - `HomeRowType.recentlyPlayed` enum value exists
  - Launch game → game appears in "Recently Played" row
  - Row sorted by most recent first
  - Game info overlay shows "Last played: X ago"

### SC10: Settings Page
- **Criterion:** Settings page accessible and functional
- **Verification:**
  - Settings button in top bar navigates to settings page
  - Language selection changes UI immediately via LocaleCubit
  - API key can be saved and is masked
  - About section shows version info

### SC11: Error States
- **Criterion:** Proper error UI for all error conditions
- **Verification:**
  - Database error: shows database error widget with retry
  - API error: shows API error widget with retry
  - Missing executable: shows missing executable widget with browse/remove options

### SC12: Empty States
- **Criterion:** Empty states have illustrations and CTAs
- **Verification:**
  - No games: shows illustration, "No Games Yet", "Add Game" button
  - No search results: shows illustration, "No Results", "Clear Search" button
  - API unreachable: shows illustration, "Can't Connect", "Retry" button

### SC13: Window Management
- **Criterion:** Window has proper title, minimum size, fullscreen support
- **Verification:**
  - Window title bar shows "Squirrel Play"
  - Window cannot be resized below 800×600
  - F11 or Start button toggles fullscreen

### SC14: Test Coverage
- **Criterion:** All new features have unit/widget tests
- **Verification:**
  - ≥25 new tests for Sprint 6 features
  - All tests pass (`flutter test`)
  - Coverage includes: favorites, play count, settings bloc, error widgets, empty states

---

## 5. Technical Constraints

### 5.1 Dependencies
**Add to pubspec.yaml:**
```yaml
dependencies:
  # Existing dependencies maintained
  window_manager: ^0.3.9       # For window management
  flutter_svg: ^2.0.9          # For empty state illustrations

  # Existing dependencies (locked versions from spec)
  flutter_bloc: ^9.1.1
  sqflite_common: ^2.5.6
  dio: ^5.4.0
  file_picker: ^11.0.2
  shared_preferences: ^2.5.5
  json_serializable: ^6.13.1
  formz: ^0.8.0
  gamepads: ^0.1.10+1
  animations: ^2.1.2
  mime: ^2.0.0
  audioplayers: ^6.0.0          # Already present for sound
```

### 5.2 Code Standards
- All new code follows existing Clean Architecture pattern
- All public APIs have documentation comments
- Maximum line length: 120 characters
- Use `const` constructors wherever possible
- BLoC events/states follow naming convention: `FeatureEventAction`, `FeatureStateCondition`
- All user-facing strings extracted to ARB files (no hardcoded strings)

### 5.3 Database Schema
No schema changes required — all needed columns (`is_favorite`, `play_count`, `last_played_date`) already exist per Sprint 3 schema.

### 5.4 Performance Requirements
- Language switch: <100ms to update UI
- Animation frame time: 16ms (60fps) target
- Sound loading: Non-blocking, async initialization
- Settings page load: <200ms

---

## 6. Dependencies and Assumptions

### 6.1 Dependencies from Previous Sprints
| Sprint | Dependency | Status |
|--------|------------|--------|
| Sprint 1 | Theme system, i18n infrastructure | ✅ Available |
| Sprint 2 | Gamepad navigation, focus system | ✅ Available |
| Sprint 3 | Database, game repository | ✅ Available |
| Sprint 4 | Home page, card rows, dynamic background | ✅ Available |
| Sprint 5 | RAWG API client, metadata service | ✅ Available |

### 6.2 Assumptions
1. **Database columns exist:** The `is_favorite`, `play_count`, and `last_played_date` columns were created in Sprint 3 and are available.
2. **Gamepad service available:** Gamepad input handling from Sprint 2 is functional and can be extended for Y button (favorite) and Start button (settings/fullscreen).
3. **Focus system extensible:** The focus management system from Sprint 2 can handle new interactive elements (settings buttons, language selector).
4. **Sound files optional:** The app will ship without sound files; users can add their own to `assets/sounds/`.
5. **SVG illustrations:** Empty state illustrations will be simple SVG files (can be placeholder shapes if custom graphics not available).

### 6.3 External Requirements
- **RAWG API key:** For testing API-related features (degraded mode works without key)
- **Windows development environment:** For testing window management features
- **Gamepad (optional):** For testing gamepad-specific features (keyboard fallback available)

---

## 7. Out of Scope (Explicitly Not Included)

The following are NOT part of Sprint 6:
- Light theme / custom themes (dark theme only per spec)
- Game time tracking beyond play count (no play duration)
- Auto-updater mechanism
- Cloud sync / multiple user profiles
- macOS/Linux support (Windows only)
- Mobile platforms (iOS/Android)
- Online multiplayer / social features
- Mod management
- Streaming integration
- Game installation/downloading
- ROM/emulation support

---

## 8. Definition of Done

Sprint 6 is complete when:
1. ✅ All deliverables in Section 3 are implemented
2. ✅ All success criteria in Section 4 are met and verifiable
3. ✅ All 267 existing tests continue to pass
4. ✅ ≥25 new tests for Sprint 6 features pass
5. ✅ `flutter analyze` shows no errors (warnings acceptable)
6. ✅ App runs on Windows with no runtime errors
7. ✅ Gamepad navigation works for all new features
8. ✅ Responsive design tested at all breakpoints
9. ✅ i18n verified in both English and Chinese
10. ✅ Self-evaluation document completed
11. ✅ Handoff document completed

---

## 9. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Sound service complexity | Medium | Low | Use well-tested `audioplayers` package, graceful fallback |
| Window manager platform issues | Low | Medium | Test on Windows early, have fallback |
| i18n string extraction volume | Medium | Low | Prioritize critical paths, use automated extraction |
| Responsive design edge cases | Medium | Medium | Test at exact breakpoint boundaries |
| Database migration issues | Low | High | Verify schema exists, no migrations needed |

---

*Contract Version: 2.0*
*Revised: 2026-04-17*
*Sprint: 6 (Final)*

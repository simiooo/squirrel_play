# Handoff: Sprint 2

## Status: Ready for QA (Round 2 - Bug Fixes Applied)

All Sprint 2 deliverables have been implemented. **8 critical bugs from Round 1 evaluation have been fixed.**

## Bug Fixes Applied (Round 1 Evaluation Feedback)

### Critical Bugs Fixed

1. **GameCard Enter key activation** (Bug #2)
   - **File**: `lib/presentation/widgets/game_card.dart`
   - **Fix**: Wrapped GameCard content in an `Actions` widget with `ActivateAction` that calls `_handlePress()`
   - **Verification**: Pressing Enter on a focused GameCard now triggers the `onPressed` callback

2. **Escape key doesn't close Add Game dialog** (Bug #3)
   - **File**: `lib/presentation/navigation/focus_traversal.dart`
   - **Fix**: Modified `_handleKeyEvent()` to return `false` for Escape key when `_isInDialogMode` is true, allowing the event to propagate to the dialog's `KeyboardListener`
   - **Verification**: Pressing Escape in the Add Game dialog now properly closes it

3. **Dialog tab switching broken with keyboard** (Bug #4)
   - **File**: `lib/presentation/navigation/focus_traversal.dart`
   - **Fix**: Modified `_handleKeyEvent()` to return `false` for all arrow keys when in dialog mode, allowing the dialog's `KeyboardListener` to handle tab switching
   - **Verification**: Left/right arrow keys now switch between "Manual Add" and "Scan Directory" tabs

### Major Bugs Fixed

4. **SoundService creates orphaned AudioPlayer instances** (Bug #1)
   - **File**: `lib/data/services/sound_service.dart`
   - **Fix**: Restructured `_playSound()` to use a simple `Map<String, AudioPlayer>` cache. Removed the `storePlayer` callback pattern that was creating duplicate players.
   - **Code change**:
     ```dart
     // Before: Created 2 players on first play (one orphaned)
     // After: Single player per sound type via Map cache
     final player = _players[soundName] ??= AudioPlayer()..setVolume(_volume);
     ```
   - **Verification**: Only one AudioPlayer is created per sound type

### Minor Bugs Fixed

5. **FocusableButton focus-out animation wrong** (Bug #5)
   - **File**: `lib/presentation/widgets/focusable_button.dart`
   - **Fix**: Changed `AnimatedContainer` to use conditional duration and curve:
     - Focus In: 150ms, `AppAnimationCurves.focusIn` (easeOut)
     - Focus Out: 100ms, `AppAnimationCurves.focusOut` (easeIn)
   - **Verification**: Focus-out animation is now faster (100ms vs 150ms) with correct curve

6. **AddGameDialog open/close animations not implemented** (Bug #6)
   - **File**: `lib/presentation/widgets/add_game_dialog.dart`
   - **Fix**: Added `AnimationController` with `Tween` for scale animation:
     - Open: scale 0.95 → 1.0 (200ms, easeOutBack)
     - Close: scale 1.0 → 0.95 (150ms, easeIn)
   - **Verification**: Dialog now animates when opening and closing

7. **clearAllRegistrations() clears top bar nodes** (Bug #7)
   - **File**: `lib/presentation/navigation/focus_traversal.dart`
   - **Fix**: Removed `_topBarNodes.clear()` from `clearAllRegistrations()`. Now only clears `_rowGroups`, `_gridGroups`, and `_contentNodes`.
   - **Verification**: Top bar focus nodes persist across page navigation

8. **consumeKeyboardToken() fallback violates contract** (Bug #8)
   - **File**: `lib/presentation/navigation/focus_traversal.dart`
   - **Fix**: Removed `currentNode.consumeKeyboardToken()` fallback in `activateCurrentNode()`. Replaced with debug log warning when activation fails.
   - **Verification**: Contract constraint is now properly enforced

## How to Run the App

```bash
# Add Flutter to PATH
export PATH="/home/simooo/flutter/bin:$PATH"

# Get dependencies
flutter pub get

# Run the app (Linux desktop)
flutter run -d linux

# Or build for Linux
flutter build linux --debug
```

**Note**: The `audioplayers` package requires gstreamer system libraries for Linux builds. If you encounter build errors about missing gstreamer, install the required packages:

```bash
# Fedora/RHEL
sudo dnf install gstreamer1-devel gstreamer1-plugins-base-devel

# Ubuntu/Debian
sudo apt-get install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

The app will run without sound files - it gracefully handles missing files with debug logging.

## What Was Implemented

### 1. Sound Service (`lib/data/services/sound_service.dart`)
- Full audio playback using `audioplayers: ^6.0.0`
- Lazy loading of sounds on first play
- 80ms debouncing for focus move sounds
- All 5 sound events: focus_move, focus_select, focus_back, page_transition, error

### 2. FocusableButton Widget (`lib/presentation/widgets/focusable_button.dart`)
- Reusable animated button with focus effects
- `isPrimary` styling variant
- Sound hooks (debounced on focus, immediate on press)
- 48×48px minimum touch target

### 3. GameCard Widget (`lib/presentation/widgets/game_card.dart`)
- 2:3 aspect ratio game cards
- Scale animation (1.0 → 1.08) on focus
- Glow and border effects on focus
- Placeholder gradients with game icons
- No `isFocused` parameter (uses `focusNode.hasFocus` only)

### 4. Enhanced FocusTraversalService (`lib/presentation/navigation/focus_traversal.dart`)
- Row and grid focus group registration
- `Actions.invoke()` for widget activation
- Callback registration for activation
- Focus history stack (max 10 entries)
- Dialog focus trapping
- Complete keyboard fallback (arrows, Enter, Escape, Space, F)

### 5. AddGameDialog (`lib/presentation/widgets/add_game_dialog.dart`)
- Two tabs: "Manual Add" and "Scan Directory"
- Placeholder content with localized messages
- Gamepad-navigable tab switching
- Focus trapping while open

### 6. TopBar Refactor (`lib/presentation/widgets/top_bar.dart`)
- Uses FocusableButton for all buttons
- Real navigation to `/library`
- Add Game dialog opens on button press
- Rescan shows placeholder SnackBar
- Page transition sounds

### 7. HomePage (`lib/presentation/pages/home_page.dart`)
- Demo row of 5 game cards
- Uses MockGames data
- Empty state with CTA

### 8. LibraryPage (`lib/presentation/pages/library_page.dart`)
- Demo 2×3 grid of game cards
- Uses MockGames data
- Empty state with CTA

### 9. Mock Data (`lib/data/mock/mock_games.dart`)
- 6 mock games with titles, colors, descriptions

### 10. Localization Updates
- All new keys added to English and Chinese ARB files

## Testing Instructions

### Keyboard Navigation (Gamepad Fallback)
1. **Arrow keys**: Navigate between top bar buttons and content
2. **Enter**: Activate focused button/card
3. **Escape**: Close dialog or go back
4. **Space**: Context action stub (logs only)
5. **F**: Favorite toggle stub (logs only)

### Top Bar Testing
1. Navigate to "Add Game" button and press Enter
   - Dialog should open with two tabs
   - Focus should be trapped in dialog
   - Left/right arrows should switch tabs
   - Escape should close dialog
   - Sound should play on open/close

2. Navigate to "Game Library" button and press Enter
   - Should navigate to Library page
   - Page transition sound should play
   - Focus should reset to first element

3. Navigate to "Rescan" button and press Enter
   - SnackBar should appear with "Rescan feature coming soon"

### Home Page Testing
1. Navigate down from top bar to content area
2. Left/right arrows should move between cards in the row
3. Focused card should scale up and show glow
4. Press Enter on a card to hear select sound

### Library Page Testing
1. Navigate to Library page via top bar
2. All 4 arrow keys should navigate the 2×3 grid
3. Focused card should show scale and glow effects

### Sound Testing
- Rapidly press arrow keys - focus should move quickly but sound should not play on every move (80ms debounce)
- Check debug console for sound event logs
- Without sound files, app logs "Could not play X: ..." but continues normally

## Deviations from Contract

None. All contract requirements have been implemented as specified.

**Note on Round 1 Evaluation**: The initial implementation had 8 bugs (3 critical, 1 major, 4 minor) that have now been fixed as documented in the "Bug Fixes Applied" section above.

## Known Issues / Limitations

1. **GStreamer Dependency**: Linux builds require gstreamer system libraries for audioplayers. This is a deployment environment issue, not a code issue.

2. **Sound Files Optional**: The app works without sound files - it logs to debug console when sounds would play but files are missing.

3. **Placeholder Content**: Add Game dialog shows placeholder text as specified in contract ("This feature will be available in a future update").

4. **No Real Game Data**: Uses MockGames constant as specified. Real data persistence comes in Sprint 3.

## Verification Commands

```bash
# Verify no analysis errors
flutter analyze

# Verify dependencies resolve
flutter pub get

# Generate localization files
flutter gen-l10n
```

All commands should complete successfully.

## Files Modified/Created

### Modified Files (Sprint 2 Implementation)
- `pubspec.yaml` - Added audioplayers dependency
- `analysis_options.yaml` - Added line length guidance
- `lib/data/services/sound_service.dart` - Full audio implementation
- `lib/presentation/navigation/focus_traversal.dart` - Enhanced with rows, grids, history, dialogs
- `lib/presentation/widgets/top_bar.dart` - Refactored with FocusableButton
- `lib/presentation/pages/home_page.dart` - Added demo card row
- `lib/presentation/pages/library_page.dart` - Added demo card grid
- `lib/app/router.dart` - Added navigation observer
- `lib/l10n/app_en.arb` - Added new keys
- `lib/l10n/app_zh.arb` - Added Chinese translations

### Modified Files (Round 1 Bug Fixes)
- `lib/data/services/sound_service.dart` - Fixed orphaned AudioPlayer bug (Bug #1)
- `lib/presentation/widgets/game_card.dart` - Added Actions widget for Enter key (Bug #2)
- `lib/presentation/navigation/focus_traversal.dart` - Fixed Escape/arrow key handling (Bugs #3, #4, #7, #8)
- `lib/presentation/widgets/focusable_button.dart` - Fixed focus-out animation (Bug #5)
- `lib/presentation/widgets/add_game_dialog.dart` - Added open/close animations (Bug #6)

### New Files
- `lib/presentation/widgets/focusable_button.dart`
- `lib/presentation/widgets/game_card.dart`
- `lib/presentation/widgets/add_game_dialog.dart`
- `lib/data/mock/mock_games.dart`

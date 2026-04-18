# Handoff: Sprint 2

## Status: Ready for QA

## What to Test

### 1. Navigation from HomePage
- Launch the app
- Press A (Enter) on any game card in the home page card row
- Verify the app navigates to `/game/{id}` (check URL in debug output or browser address bar)
- Verify the detail page shows the selected game's title, description (if available), and stats

### 2. Navigation from LibraryPage
- Navigate to Library page
- Press A (Enter) on any game card in the grid
- Verify the app navigates to `/game/{id}`

### 3. Detail Page States
- **Loading**: Briefly shows a `CircularProgressIndicator` before content loads
- **Loaded**: Shows game title, description, developer (if metadata exists), play count, last played date, favorite status
- **Error**: If game ID doesn't exist, shows error message with red icon

### 4. Focus Behavior
- When the detail page loads, the first action button ("启动游戏") should automatically have focus (orange/elevated background)
- Use D-pad left/right or arrow keys to navigate between the three action buttons
- Focus should move horizontally: Launch → Settings → Delete → Settings → Launch

### 5. Back Navigation
- Press B (Escape) on the detail page
- Verify the app pops back to the previous page (Home or Library)
- This is handled automatically by `FocusTraversalService._handleCancel()` — no custom back handler was added

### 6. Action Buttons (Stubs)
- Three buttons are visible: "启动游戏", "设置", "删除"
- Pressing A on any of them logs to console but does not perform the actual action (Sprint 3 scope)

## Running the Application

- Command: `flutter run -d linux`
- The app starts on the Home page. Navigate to a game card and press A to open the detail page.

## Known Gaps

- **Launch/Stop actions**: "启动游戏" and "停止" buttons are present but non-functional. Sprint 3 wires these to `GameLauncher.launchGame()` and `GameLauncher.stopGame()`.
- **Edit dialog**: "设置" button does not open `EditGameDialog`. Sprint 3 scope.
- **Delete dialog**: "删除" button does not open `DeleteGameDialog`. Sprint 3 scope.
- **Process lifecycle tracking**: `GameDetailRunningStateChanged` event exists but is stubbed. Sprint 3 subscribes to `GameLauncher.runningGamesStream`.
- **Action button mutual exclusion**: All three buttons are always visible. Dynamic hiding based on `isRunning` is Sprint 3 scope.
- **Localization**: Button labels are hardcoded in Chinese. Sprint 3 adds ARB entries and runs `flutter gen-l10n`.

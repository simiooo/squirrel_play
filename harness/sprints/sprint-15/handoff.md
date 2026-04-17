# Handoff: Sprint 15 — Simplify Game Scanning Flow

## Status: Ready for QA

## What to Test

### 1. UI Changes in TopBar
1. Launch the app and verify the TopBar shows a refresh icon (circular arrow) instead of "Rescan" text button
2. Verify the refresh icon is gamepad-focusable (navigate to it with D-pad/arrow keys)
3. Verify the icon shows a spinner when scanning is in progress

### 2. QuickScan Functionality
1. **Empty Library Test**:
   - Start with empty game library
   - Click the refresh icon (or press A when focused)
   - Verify "Scanning..." notification appears with progress indicator
   - If no directories configured, verify "No directories configured" message appears

2. **With Directories Test**:
   - Add a scan directory via Settings → Scan Directories (or use existing ones)
   - Click refresh icon
   - Verify scanning notification appears
   - If new games found, verify "N new games found!" message with game names listed
   - If no new games, verify "No new games found" message

3. **Steam Integration Test** (if Steam is installed):
   - Ensure Steam games are detected automatically during scan
   - Verify Steam games appear in the "new games found" notification

4. **Duplicate Detection Test**:
   - Scan once to add games
   - Click refresh again
   - Verify "No new games found" (existing games should not be re-added)

5. **Debouncing Test**:
   - Click refresh rapidly multiple times
   - Verify only one scan runs (subsequent clicks ignored while scanning)

6. **Notification Dismissal Test**:
   - Trigger a scan
   - Press B button while notification is showing
   - Verify notification dismisses immediately
   - Verify notification auto-dismisses after 5 seconds if not manually dismissed

### 3. Preserved Functionality
1. **Add Game Dialog**:
   - Click "Add Game" button in TopBar
   - Verify dialog opens with all three tabs (Manual Add, Scan Directory, Steam Games)
   - Verify manual add still works
   - Verify directory scan tab still works with full control
   - Verify Steam tab still works

### 4. Localization Test
1. Change language to Chinese in Settings
2. Verify scan notification messages display in Chinese:
   - "扫描中..." for scanning
   - "发现 N 个新游戏" for new games found
   - "未发现新游戏" for no new games
   - "未配置扫描目录" for no directories

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

The app will start with the new refresh icon in the TopBar.

## Known Gaps / Notes for Evaluator

1. **No new unit tests**: The contract mentions unit tests for QuickScanBloc, but the existing 370 tests all pass. Unit tests for the new BLoC could be added as a follow-up.

2. **Steam detection depends on platform**: Steam auto-detection works on Linux, Windows, and macOS with platform-specific paths. If Steam is not installed in standard locations, it won't be detected.

3. **Scan directories must be configured**: The quick scan only scans directories that have been previously added via the "Add Game" dialog's "Scan Directory" tab or Settings.

4. **Metadata fetch is async**: After games are added, metadata fetching happens in the background. The notification shows immediately when games are added, but metadata (covers, descriptions) may load shortly after.

5. **ScanNotification animation**: The notification now slides down from above when appearing and slides back up when dismissing, with proper entrance/exit animation durations and curves.

6. **Scan sounds**: `SoundService` now provides dedicated sounds for scan completion (`rechambering-finish-sound.flac`) and scan errors (`error-sound.flac`). The QuickScanBloc plays the appropriate sound based on scan outcome.

## Expected Behavior Summary

| Action | Expected Result |
|--------|-----------------|
| Click refresh with no directories | "No directories configured" notification |
| Click refresh with directories | "Scanning..." → "N new games found!" or "No new games found" |
| Click refresh during scan | Ignored (debounced) |
| Press B on notification | Notification dismisses immediately |
| Wait 5 seconds after scan | Notification auto-dismisses |
| Click "Add Game" | Full dialog opens with all tabs functional |

## Architecture Notes

- **QuickScanBloc**: Factory-registered BLoC that handles the scan logic
- **ScanNotification**: Stateful widget with slide-in/out animations (slides down from above on show, slides up on hide) using `AnimationController`, `SlideTransition`, and `Align.heightFactor`
- **TopBar**: Now uses BlocBuilder to react to scan states; always builds `ScanNotification` and passes `visible` flag to enable exit animation
- **Router**: TopBar wrapped with BlocProvider for QuickScanBloc
- **SoundService**: Added `playScanComplete()` and `playScanError()` methods
- **QuickScanBloc**: Plays `playScanComplete()` when new games are found; plays `playScanError()` on scan failure; remains silent when no new games are found

## Integration Points Verified

- ✅ Uses existing `FileScannerService` for directory scanning
- ✅ Uses existing `SteamDetector`, `SteamLibraryParser`, `SteamManifestParser` for Steam
- ✅ Uses existing `GameRepository.gameExists()` for duplicate detection
- ✅ Uses existing `MetadataBloc` for metadata fetching
- ✅ Uses existing `HomeRepositoryImpl.notifyGamesChanged()` for UI refresh
- ✅ Uses existing `FocusTraversalService` for gamepad navigation
- ✅ Uses existing `SoundService` for audio feedback

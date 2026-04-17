# Sprint Contract: Sprint 15 — Simplify Game Scanning Flow

## Scope
Replace the heavyweight "Rescan" button flow with a lightweight refresh icon that triggers automatic background scanning of all saved directories and Steam libraries. Results are shown via a non-intrusive notification banner rather than a full dialog. The existing "Add Game" dialog remains available for manual additions with full control.

## Implementation Plan

### 1. TopBar UI Changes (`lib/presentation/widgets/top_bar.dart`)
- Replace the "Rescan" `FocusableButton` with a smaller refresh `IconButton` using `Icons.refresh`
- Add a `FocusNode` for the refresh icon (registered with `FocusTraversalService`)
- Add a spinner overlay on the icon when scanning is in progress (using `CircularProgressIndicator` or animated icon)
- Integrate with `QuickScanBloc` to trigger scans
- Show scan results via `ScanNotification` widget (not a dialog)
- Play appropriate sounds via `SoundService`
- **Note**: The existing Rescan button's FocusNode at `_buttonFocusNodes[3]` will be replaced, changing from a `FocusableButton` to an `IconButton` with a custom FocusNode

### 2. New BLoC: QuickScanBloc (`lib/presentation/blocs/quick_scan/quick_scan_bloc.dart`)
Create a new BLoC with the following structure:

**Events:**
```dart
abstract class QuickScanEvent {}
class QuickScanRequested extends QuickScanEvent {}
class QuickScanCancelled extends QuickScanEvent {}
```

**States:**
```dart
abstract class QuickScanState {}
class QuickScanIdle extends QuickScanState {}
class QuickScanScanning extends QuickScanState {
  final String? currentPath;
  QuickScanScanning({this.currentPath});
}
class QuickScanComplete extends QuickScanState {
  final int newGamesFound;
  final List<Game> addedGames;
  QuickScanComplete({required this.newGamesFound, required this.addedGames});
}
class QuickScanNoNewGames extends QuickScanState {
  final bool noDirectoriesConfigured;
  QuickScanNoNewGames({this.noDirectoriesConfigured = false});
}
class QuickScanError extends QuickScanState {
  final String message;
  QuickScanError({required this.message});
}
```

**Logic:**
- `QuickScanRequested` triggers parallel scanning of:
  - All saved directories from `ScanDirectoryRepository.getAllDirectories()`
  - Steam libraries via `SteamDetector.detectSteamPath()` → `SteamLibraryParser.parseLibraryFolders()`
  - **Debouncing**: If state is already `QuickScanScanning`, the event is ignored (no-op)
- Uses `FileScannerService.scanDirectories()` for directory scanning
- **Cross-source deduplication**: After combining directory and Steam scan results, remove duplicate executable paths before checking the database
- Compares discovered executables against existing games via `GameRepository.gameExists()`
- **Partial scan failure tolerance**: If some directories fail but others succeed, the scan continues with successful results (failed directories are logged but don't block the entire scan)
- **Null executable handling**: Steam games with null `primaryExecutable` are skipped (same as `SteamScannerBloc`)
- Auto-adds new games without user confirmation
- Triggers metadata fetch by directly dispatching `FetchMetadata` events to `MetadataBloc` (matching `SteamScannerBloc` pattern)
- Notifies `HomeRepository` to refresh UI via `notifyGamesChanged()`
- **State lifecycle**: `QuickScanComplete`/`QuickScanNoNewGames`/`QuickScanError` persist until the notification is dismissed, then transition to `QuickScanIdle`
- **Cancellation**: Supports `QuickScanCancelled` event to cancel an in-progress scan via `FileScannerService.cancelScan()`

### 3. New Widget: ScanNotification (`lib/presentation/widgets/scan_notification.dart`)
Create a lightweight overlay notification:
- Slides down from below the TopBar
- **Animation tokens**:
  - Slide-in: `AppAnimationDurations.dialogOpen` (200ms) with `AppAnimationCurves.dialogOpen` (easeOutBack)
  - Slide-out: `AppAnimationDurations.dialogClose` (150ms) with `AppAnimationCurves.dialogClose` (easeIn)
  - Progress bar: `AppAnimationDurations.progressBar` (300ms)
- **Color tokens**:
  - Background: `AppColors.surface`
  - Progress bar: `AppColors.primaryAccent`
  - Primary text: `AppColors.textPrimary`
  - Secondary text (game names): `AppColors.textSecondary`
- Shows "Scanning..." with `LinearProgressIndicator` during scan
- On completion:
  - If new games found: "{count} new games found!" with game names (up to 5, then "+X more")
  - If no new games: "No new games found" (or "No directories configured" when `noDirectoriesConfigured` is true)
  - If error: "Scan error: {message}"
- **Auto-dismiss**: All notification types auto-dismiss after 5 seconds
- Gamepad-dismissible (press B to close immediately)
- The `ScanNotification` widget needs FocusNode management for gamepad dismiss (B button)

### 4. DI Registration (`lib/app/di.dart`)
Register `QuickScanBloc` as a factory:
```dart
getIt.registerFactory<QuickScanBloc>(() => QuickScanBloc(
  gameRepository: getIt<GameRepository>(),
  scanDirectoryRepository: getIt<ScanDirectoryRepository>(),
  fileScannerService: getIt<FileScannerService>(),
  steamDetector: getIt<SteamDetector>(),
  steamLibraryParser: getIt<SteamLibraryParser>(),
  homeRepository: getIt<HomeRepository>() as HomeRepositoryImpl, // Required for notifyGamesChanged()
  metadataBloc: getIt<MetadataBloc>(), // Direct reference pattern like SteamScannerBloc
  uuid: getIt<Uuid>(),
));
```

**Note**: `QuickScanBloc` depends on `HomeRepositoryImpl` (not just `HomeRepository`) because `notifyGamesChanged()` is needed. This matches the existing pattern in `AddGameBloc` and `SteamScannerBloc`.

### 5. Localization Updates (`lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`)
Add new strings:
- `topBarRefresh`: "Refresh" / "刷新"
- `topBarScanning`: "Scanning..." / "扫描中..."
- `topBarScanNewGames`: "{count} new games found" / "发现 {count} 个新游戏"
- `topBarScanNoNewGames`: "No new games found" / "未发现新游戏"
- `topBarScanNoDirectories`: "No directories configured" / "未配置扫描目录"
- `topBarScanError`: "Scan error" / "扫描错误"
- `topBarRefreshHint`: "Refresh game library" / "刷新游戏库"

### 6. Sound Design
- Refresh icon activation: `SoundService.instance.playFocusSelect()`
- Scan complete (new games): `SoundService.instance.playFocusSelect()`
- Scan complete (no games): No sound (or subtle tick)
- **Scan error**: `SoundService.instance.playError()` (not `playFocusBack()`)

## Success Criteria

1. **UI Change**: The "Rescan" text button in TopBar is replaced with a refresh icon button
   - Verify: Icon is visible and gamepad-focusable
   - Verify: Icon shows spinner/progress indicator when scanning

2. **QuickScanBloc**: New BLoC handles automatic scanning
   - Verify: BLoC transitions through states: Idle → Scanning → Complete/NoNewGames/Error → Idle (after dismiss)
   - Verify: BLoC ignores `QuickScanRequested` when already in `QuickScanScanning` state (debouncing)
   - Verify: BLoC scans all saved directories
   - Verify: BLoC scans Steam libraries (if Steam is installed)
   - Verify: BLoC auto-adds new games without confirmation
   - Verify: BLoC triggers metadata fetch for new games via direct `MetadataBloc` dispatch
   - Verify: BLoC handles partial scan failures (continues with successful results)

3. **ScanNotification**: Lightweight notification shows scan results
   - Verify: "Scanning..." appears during scan with progress indicator
   - Verify: "N new games found" appears when games are discovered
   - Verify: "No new games found" appears when no new games
   - Verify: "No directories configured" appears when no directories are set up
   - Verify: Error message appears on scan failure
   - Verify: Notification auto-dismisses after 5 seconds
   - Verify: Notification can be dismissed with gamepad B button

4. **Duplicate Detection**: Already-added games are not re-added
   - Verify: Scanning a directory with existing games shows "No new games found"
   - Verify: No duplicate entries appear in the database
   - Verify: Cross-source duplicates (same executable found by both directory and Steam scan) are handled

5. **Preserved Behavior**: "Add Game" dialog remains functional
   - Verify: "Add Game" button still opens the full dialog
   - Verify: Manual add, directory scan, and Steam tabs still work
   - Verify: Full scan flow with confirmation still available
   - Verify: The old `_handleRescan` method path (`AddGameDialog.show(context, initialTab: 1, isRescan: true)`) is removed and replaced with `QuickScanBloc` dispatch

6. **Localization**: All new strings are localized
   - Verify: English strings display correctly
   - Verify: Chinese strings display correctly (if locale is zh)

7. **Gamepad Navigation**: Refresh icon is fully gamepad-accessible
   - Verify: Icon can be focused via gamepad navigation
   - Verify: A button triggers scan
   - Verify: B button dismisses notification

## Out of Scope for This Sprint
- Removing the "Add Game" dialog or its functionality
- Changing the manual add flow
- Modifying the Steam scanner BLoC or its UI
- Adding new scan sources (GOG, Epic, etc.)
- Background/periodic auto-scanning
- Scan history or logs
- Configurable scan settings (depth, patterns)
- Batch operations on discovered games (edit before adding)

## Dependencies
- Sprint 14 (Flatpak detection + metadata sources) - COMPLETED
- Sprint 9 (Steam scanning) - COMPLETED
- Sprint 3 (directory scanning) - COMPLETED

## Files to Create/Modify

### New Files:
- `lib/presentation/blocs/quick_scan/quick_scan_bloc.dart`
- `lib/presentation/blocs/quick_scan/quick_scan_event.dart`
- `lib/presentation/blocs/quick_scan/quick_scan_state.dart`
- `lib/presentation/widgets/scan_notification.dart`

### Modified Files:
- `lib/presentation/widgets/top_bar.dart` (replace Rescan button)
- `lib/app/di.dart` (register QuickScanBloc)
- `lib/l10n/app_en.arb` (add new strings)
- `lib/l10n/app_zh.arb` (add new strings)

## Testing Approach
1. Unit tests for QuickScanBloc state transitions
2. Unit tests for debouncing (ignore requests while scanning)
3. Unit tests for duplicate detection logic (including cross-source)
4. Unit tests for partial scan failure handling
5. Widget tests for ScanNotification display
6. Integration test: Click refresh → verify scanning → verify notification → verify games added

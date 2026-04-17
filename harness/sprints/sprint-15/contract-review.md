# Contract Review: Sprint 15 — Simplify Game Scanning Flow

## Assessment: NEEDS_REVISION

The contract is largely well-structured and aligns with the spec's Sprint 15 scope. However, there are several issues that need to be addressed before implementation proceeds — primarily around the QuickScanBloc design, DI registration, and a few missing edge cases.

## Scope Coverage

The contract's scope correctly covers the spec's Sprint 15 requirements:
- ✅ Replace "Rescan" text button with refresh icon button
- ✅ Background automatic scanning (no dialog)
- ✅ Lightweight notification banner instead of full dialog
- ✅ Auto-add new games without confirmation
- ✅ Keep "Add Game" dialog intact for manual additions
- ✅ i18n strings for English and Chinese

The scope is appropriately bounded — no scope creep. "Out of Scope" section is clear and reasonable.

## Success Criteria Review

### Criterion 1: UI Change — Refresh icon replaces Rescan text button
- **Adequate**. Clear and testable.

### Criterion 2: QuickScanBloc handles automatic scanning
- **Needs revision**. See "QuickScanBloc Design" section below for detailed concerns.

### Criterion 3: ScanNotification displays scan results
- **Mostly adequate**. The auto-dismiss behavior differs between spec and contract: the spec says "No new games" auto-dismisses after 3 seconds, while the contract says all notifications auto-dismiss after 5 seconds. This inconsistency should be resolved. I recommend following the spec (3s for no results, 5s for results found).

### Criterion 4: Duplicate Detection
- **Needs revision**. The contract says "BLoC scans all saved directories" and "scans Steam libraries" but the duplicate detection description ("Already-added games are not re-added") does not specify how duplicates are detected when scanning across BOTH sources simultaneously. Since both directory scanning and Steam scanning could discover the same game executable, there needs to be explicit cross-source deduplication logic.

### Criterion 5: Preserved Behavior — Add Game dialog still works
- **Adequate**. Clear and testable.

### Criterion 6: Localization
- **Adequate**.

### Criterion 7: Gamepad Navigation
- **Adequate**. The focus node registration with `FocusTraversalService` is correctly called out.

## Detailed Concerns

### 1. QuickScanBloc — Design Issues

**Problem A: `QuickScanSteamRequested` event is underspecified.** The contract defines a `QuickScanSteamRequested` event but the description only explains `QuickScanRequested`. What does the Steam-specific event do differently? The spec says QuickScan should scan *both* saved directories AND Steam libraries simultaneously on a single action. A separate event implies the user could trigger a Steam-only scan, which contradicts the spec. **Recommendation**: Remove `QuickScanSteamRequested` — a single `QuickScanRequested` event that scans everything is cleaner and matches the spec.

**Problem B: `QuickScanComplete` includes `addedGames` list, but the notification shows "up to 5 names, then +X more".** This means the state carries all added game objects, which could be expensive. This is fine for practical purposes, but the contract should specify that `addedGames` is the full list (the notification widget will truncate display).

**Problem C: No debouncing/rejection of concurrent scans.** The spec's acceptance criteria say: "Given the QuickScanBloc, when a scan is already in progress and the user clicks refresh again, then the second request is ignored." The contract mentions this in Success Criterion 2 ("Verify: BLoC transitions through states") but doesn't specify the mechanism. The BLoC should explicitly ignore `QuickScanRequested` events when state is `QuickScanScanning`. **Recommendation**: Add explicit documentation in the BLoC design that `QuickScanRequested` is a no-op when in `QuickScanScanning` state.

**Problem D: No cancellation support.** `FileScannerService` has a `cancelScan()` method. The QuickScanBloc should support cancelling an in-progress scan (e.g., user navigates away or wants to restart). Consider adding a `QuickScanCancelled` event or at minimum documenting that cancellation is out of scope for this sprint.

### 2. DI Registration — Type Safety Issue

The contract's DI registration contains:

```dart
homeRepository: getIt<HomeRepository>() as HomeRepositoryImpl,
```

This cast from interface to concrete implementation is a code smell and will break if a different `HomeRepository` implementation is registered. The `HomeRepositoryImpl.notifyGamesChanged()` method is needed to trigger UI refresh after games are added. Looking at the existing codebase, both `AddGameBloc` and `SteamScannerBloc` use this same pattern (`as HomeRepositoryImpl`), so it's an established pattern in this codebase. However, the `HomeRepository` interface should be updated to include `notifyGamesChanged()` so the cast isn't needed. That's a refactoring concern outside this sprint's scope, but the contract should acknowledge this dependency clearly.

**Recommendation**: Add a note in the contract that `QuickScanBloc` depends on `HomeRepositoryImpl` (not just `HomeRepository`) because `notifyGamesChanged()` is needed. This matches the existing pattern in `AddGameBloc` and `SteamScannerBloc`.

### 3. Notification Design — Dark Theme Alignment

The contract specifies: "surface background, primaryAccent for progress bar". This is consistent with the design system tokens (`AppColors.surface`, `AppColors.primaryAccent`). However:

- The contract should specify `AppColors.textPrimary` for notification text (not left to interpretation).
- The contract should specify `AppColors.textSecondary` for secondary text (e.g., game names).
- The "slides down from below the TopBar" pattern should reference the existing animation tokens. Specifically, use `AppAnimationDurations.dialogOpen` (200ms) with `AppAnimationCurves.dialogOpen` (easeOutBack) for the slide-in, and `AppAnimationDurations.dialogClose` (150ms) with `AppAnimationCurves.dialogClose` (easeIn) for slide-out.
- The `LinearProgressIndicator` during scanning should use `AppAnimationDurations.progressBar` (300ms) per design tokens.

**Recommendation**: Add explicit design token references to the ScanNotification widget specification.

### 4. Duplicate Detection — Cross-Source Consistency

The contract says:
- "QuickScanRequested triggers parallel scanning of: All saved directories... Steam libraries..."
- "Compares discovered executables against existing games via GameRepository.gameExists()"

This is correct for deduplication against the database. However, there's a gap: what if `FileScannerService` discovers a `.exe` that a Steam library also discovers? The same executable could be found by both scans. The `gameExists()` check handles this for already-added games, but if two *new* executables with the same path are found by different scanners, they'd both be added.

**Recommendation**: Add a deduplication step that merges discovered executables across sources before adding to the database. Specifically: after both directory scan and Steam scan complete, remove duplicate paths from the combined list before checking `gameExists()`.

### 5. Integration Points — Missing Details

**A: MetadataBloc callback pattern**. The contract says "Triggers metadata fetch via callback to MetadataBloc". Looking at the codebase, `SteamScannerBloc` passes a `MetadataBloc` instance and dispatches `FetchMetadata` events directly. `AddGameBloc` uses an `OnGamesAddedCallback` pattern. The contract should specify which pattern `QuickScanBloc` uses. Since it's auto-adding without user confirmation (more like SteamScannerBloc), the MetadataBloc reference pattern used by `SteamScannerBloc` is more appropriate than the callback pattern. **Recommendation**: Specify that `QuickScanBloc` receives a `MetadataBloc` instance and dispatches `FetchMetadata` events for each newly added game, matching the `SteamScannerBloc` pattern.

**B: `onGamesAdded` parameter in DI registration**. The contract shows `onGamesAdded: null` in the QuickScanBloc DI registration, but if we're using the MetadataBloc direct reference pattern (as in SteamScannerBloc), `onGamesAdded` should not be a constructor parameter at all. This needs to be clarified.

**C: FocusTraversalService integration**. The contract mentions "Add a FocusNode for the refresh icon (registered with FocusTraversalService)" which is correct. However, it should also note that the existing Rescan button's FocusNode at `_buttonFocusNodes[3]` in `top_bar.dart` will be replaced, changing from a `FocusableButton` to an `IconButton` with a custom FocusNode. The ScanNotification widget also needs FocusNode management for gamepad dismiss (B button).

**D: `SoundService.playError()`**. The contract references using `playFocusBack()` for scan errors. The `SoundService` now has `playError()` (added in a later sprint). The contract should use `playError()` for error states instead of `playFocusBack()`.

### 6. Edge Cases

**A: No saved directories and no Steam**. The contract says "QuickScanRequested triggers parallel scanning of all saved directories and Steam libraries." What happens when there are zero saved directories AND Steam is not installed? This should result in `QuickScanNoNewGames` (or potentially a specific message like "No directories configured"), not an error. **Recommendation**: Add a new state or handle this case explicitly — `QuickScanNoNewGames` should include a field like `bool noDirectoriesConfigured` so the notification can show a more helpful message.

**B: Steam not installed on any platform**. The contract correctly notes that `SteamDetector.detectSteamPath()` returns null when Steam isn't found. The QuickScanBloc should gracefully skip Steam scanning when `detectSteamPath()` returns null (this is implied but should be explicit).

**C: Scan errors for individual directories**. `FileScannerService.scanDirectories()` yields `ScanProgress` with an `error` field for directories that can't be accessed. The QuickScanBloc should handle partial scan failures — if some directories fail but others succeed, the scan should still produce results. **Recommendation**: Add documentation that partial scan failures are tolerated; failed directories are skipped but successful results are still processed.

**D: Empty executable path from Steam games**. `SteamGameData.primaryExecutable` can return null. The `SteamScannerBloc` skips games with null executables. The QuickScanBloc should do the same — document this.

**E: What happens to the old `_handleRescan` method?** The contract should explicitly state that the `AddGameDialog.show(context, initialTab: 1, isRescan: true)` path is removed and replaced with `QuickScanBloc` dispatch.

### 7. Minor Issues

- **L10n key naming**: The contract uses `topBarRefresh`, `topBarScanning`, etc. These should follow the existing project naming convention. Checking the existing l10n keys would confirm the pattern, but these names are reasonable.
- **State return to `QuickScanIdle`**: The contract's scan flow sequence says "State returns to QuickScanIdle" at step 10, but doesn't specify *when*. After the notification auto-dismisses? Or immediately? **Recommendation**: The state should remain at `QuickScanComplete`/`QuickScanNoNewGames`/`QuickScanError` until the notification is dismissed, then transition to `QuickScanIdle`. This way the UI can observe the state. Otherwise, if the state transitions to `QuickScanIdle` immediately after showing results, the notification widget won't know what to show.
- **`List<Game>` in state vs `List<String>`**: `QuickScanComplete` carries `List<Game> addedGames`, but the notification only needs game titles for display. Carrying full `Game` entities in the state is fine (it matches the existing `SteamScannerBloc` pattern), but the contract should be clear this is intentional.

## Suggested Changes

1. **Remove `QuickScanSteamRequested` event** — a single `QuickScanRequested` event that scans both sources is simpler and matches the spec.

2. **Add explicit debouncing documentation** — The BLoC must ignore `QuickScanRequested` when already in `QuickScanScanning` state.

3. **Specify auto-dismiss timing** — "No new games" should auto-dismiss after 3 seconds (matching spec), "New games found" after 5 seconds, "Error" after 5 seconds.

4. **Add cross-source deduplication** — After combining directory and Steam scan results, remove duplicate executable paths before checking the database.

5. **Use MetadataBloc reference pattern** — Instead of `onGamesAdded` callback, `QuickScanBloc` should directly reference and dispatch events to `MetadataBloc`, matching `SteamScannerBloc`.

6. **Use `SoundService.playError()` for scan errors** — The method exists in the codebase and is more semantically correct.

7. **Add explicit design token references** for ScanNotification animations and colors.

8. **Handle "no directories configured" edge case** — `QuickScanNoNewGames` state should differentiate between "scanned but nothing found" and "nothing to scan."

9. **Clarify state lifecycle** — `QuickScanComplete`/`QuickScanNoNewGames`/`QuickScanError` should persist until the notification is dismissed, not immediately transition to `QuickScanIdle`.

10. **Document partial scan failure tolerance** — Failed directories should not block the entire scan.

## Test Plan Preview

When evaluating the implementation, I will test:

1. **TopBar UI**: Verify the refresh icon replaces "Rescan" text button, is gamepad-focusable, and shows a spinner during scanning.
2. **Scan flow**: Trigger a scan, verify state transitions (Idle → Scanning → Complete/NoNewGames/Error).
3. **QuickScanBloc debouncing**: Press refresh rapidly — second press during scanning should be ignored.
4. **Duplicate detection**: Add a game, then scan the same directory — verify "No new games found."
5. **Cross-source deduplication**: If Steam and directory scan find the same executable, verify only one game is added.
6. **Notification auto-dismiss**: Verify "No new games" dismisses after 3s, "N new games" after 5s.
7. **Gamepad dismiss**: Verify B button dismisses notification early.
8. **Edge cases**: No saved directories, Steam not installed, partial scan failures, null executable paths from Steam.
9. **Preserved behavior**: "Add Game" button still opens full dialog.
10. **DI registration**: Verify `QuickScanBloc` is properly registered with all required dependencies.
11. **Metadata triggering**: Verify newly scanned games get metadata fetched.
12. **Home page refresh**: Verify newly added games appear on the home page without manual refresh.
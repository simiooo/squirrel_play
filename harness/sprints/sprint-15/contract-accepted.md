# Sprint 15 Contract Acceptance

## Status: ACCEPTED

## Review Summary

The revised Sprint 15 contract fully addresses all 11 issues raised in the previous review. The contract is well-structured, sufficiently detailed, and aligned with the spec's Sprint 15 scope. The Generator may proceed with implementation.

## Issues Resolution

1. **`QuickScanSteamRequested` event removed** — Resolved. Events now only include `QuickScanRequested` and `QuickScanCancelled`. A single event triggers scanning of both directories and Steam libraries simultaneously, matching the spec.

2. **Debouncing documented** — Resolved. Explicit note on line 53: "If state is already `QuickScanScanning`, the event is ignored (no-op)." Success criterion 2 also includes a verification point for this behavior.

3. **Cross-source deduplication** — Resolved. Explicit step added (line 55): "After combining directory and Steam scan results, remove duplicate executable paths before checking the database." Success criterion 4 also verifies cross-source duplicate handling.

4. **MetadataBloc direct reference pattern** — Resolved. The BLoC now "directly dispatches `FetchMetadata` events to `MetadataBloc`" (line 61), matching the `SteamScannerBloc` pattern. DI registration includes `metadataBloc: getIt<MetadataBloc>()` instead of a callback.

5. **`onGamesAdded` parameter removed from DI** — Resolved. The DI registration (lines 90-99) no longer includes `onGamesAdded: null`. It instead passes `metadataBloc` directly.

6. **`SoundService.playError()` for scan errors** — Resolved. Line 118 explicitly specifies `playError()` and even notes "(not `playFocusBack()`)" to prevent confusion.

7. **Design token references for ScanNotification** — Resolved. Lines 69-78 now specify explicit animation tokens (`AppAnimationDurations.dialogOpen`, `AppAnimationCurves.dialogOpen`, etc.) and color tokens (`AppColors.surface`, `AppColors.primaryAccent`, `AppColors.textPrimary`, `AppColors.textSecondary`).

8. **"No directories configured" edge case** — Resolved. `QuickScanNoNewGames` state now includes `noDirectoriesConfigured` boolean field (line 42). Success criterion 3 verifies the "No directories configured" message appears when appropriate (line 139).

9. **State lifecycle clarified** — Resolved. Line 62 explicitly states: "`QuickScanComplete`/`QuickScanNoNewGames`/`QuickScanError` persist until the notification is dismissed, then transition to `QuickScanIdle`."

10. **Partial scan failure tolerance** — Resolved. Line 57 documents: "If some directories fail but others succeed, the scan continues with successful results (failed directories are logged but don't block the entire scan)." Success criterion 2 also includes a verification point for this.

11. **Cancellation support** — Resolved. `QuickScanCancelled` event added to the event list (line 24) and documented (line 64): "Supports `QuickScanCancelled` event to cancel an in-progress scan via `FileScannerService.cancelScan()`."

Additional sub-issues also resolved:
- **Null executable handling**: Explicitly documented at line 59.
- **Old `_handleRescan` removal**: Explicitly stated as a success criterion verification point (line 153).
- **DI type safety**: Acknowledged with explanatory note (line 102) matching existing codebase pattern.
- **FocusNode management**: Both the refresh icon (lines 11, 15) and ScanNotification gamepad dismiss (line 85) are documented.

## Remaining Notes

1. **Auto-dismiss timing**: The contract uses a flat 5 seconds for all notification types. The previous review suggested differentiating timing (3s for "no results", 5s for "results found"). The flat 5s approach is a reasonable design simplification — consistent behavior is simpler to implement and test. If the team later finds 5s too long for "no results" notifications, this can be tuned post-sprint.

2. **`addedGames` carries full `List<Game>` entities**: This matches the `SteamScannerBloc` pattern and is intentional. The `ScanNotification` widget will handle display truncation (up to 5 names, then "+X more"). No issue, just confirming this is by design.

3. **`HomeRepositoryImpl` cast in DI**: The contract correctly notes this follows the existing pattern (`AddGameBloc`, `SteamScannerBloc`). A future refactor to move `notifyGamesChanged()` into the `HomeRepository` interface would eliminate the cast, but that's outside this sprint's scope.
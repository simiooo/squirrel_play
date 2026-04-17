# Contract Accepted: Sprint 9

Contract approved at 2026-04-17. The Generator may proceed with implementation.

## Verification Summary

All seven previously identified issues have been fully resolved in the revised contract:

1. **Cross-platform executable path**: Replaced hardcoded `.exe` with platform-aware `SteamManifestParser` that uses `FileScannerService` patterns and returns `List<String> possibleExecutablePaths` with Windows/Linux/macOS-specific logic.

2. **GameRepository injection**: `GameRepository` is listed as an explicit constructor dependency of `SteamScannerBloc`, with a dedicated "Duplicate Detection" subsection specifying `_gameRepository.gameExists(executablePath)`.

3. **Metadata fetch integration**: Option A is explicitly specified — `SteamScannerBloc` dispatches `FetchGameMetadata` events to `MetadataBloc` via `getIt<MetadataBloc>().add(...)` after importing games.

4. **AddGameBloc SwitchTab**: The revised contract provides the updated `_onSwitchTab` handler with `tabIndex == 2` mapped to `SteamGamesForm`, plus the new state added to the `AddGameState` union.

5. **PlatformInfo abstraction**: Full `PlatformInfo` interface and `PlatformInfoImpl` are defined, registered as singleton in DI, and injected into all Steam services.

6. **VDF/ACF parser robustness**: Dedicated section (Section 7) covering BOM stripping, line ending normalization, Unicode, escaped quotes, brace counting, and graceful malformed entry handling with warning logs.

7. **Installation size field**: `SteamGameData` includes `int? installSize`, manifest parser extracts `StagingSize`, and UI displays "install size (if available)".

Additionally, the data/UI state split (`SteamGameData` vs `SteamGameViewModel`) and the `SteamScannerImportComplete` state for import result handling were addressed — both resolving minor concerns from the original review.
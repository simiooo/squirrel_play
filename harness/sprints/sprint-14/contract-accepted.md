# Sprint 14 Contract Acceptance

## Status: ACCEPTED

## Review Summary

All 9 issues from the previous contract review (5 must-fix blockers + 4 should-fix items) have been fully addressed in the revised contract. The contract is comprehensive, internally consistent, and ready for implementation.

## Issues Resolution

1. **steamAppId data flow** — RESOLVED. New "Steam Game Import Data Flow" section (lines 334-363) specifies that `SteamScannerBloc._onImportSelectedGames()` creates an initial `GameMetadata` with `externalId: 'steam:{steamGame.appId}'` during import, preserving the appId for later metadata resolution. The `canProvide()`/`fetch()` signatures no longer take a `steamAppId` parameter; instead, `SteamLocalSource` resolves the appId from the stored `externalId` or `executablePath`.

2. **DI registrations use singletons** — RESOLVED. All metadata sources (`SteamLocalSource`, `SteamStoreSource`, `RawgSource`) and `MetadataAggregator` are registered with `registerSingleton` (lines 392-426). No factory-singleton inconsistency remains.

3. **MetadataRepositoryImpl in "Files to Modify"** — RESOLVED. Explicitly listed as item 3 under "Modified Files" (line 506) and detailed in its own "Integration with MetadataRepositoryImpl" section (lines 321-330).

4. **MetadataAggregator constructor consistency** — RESOLVED. The constructor now uses named parameters (`steamLocalSource`, `steamStoreSource`, `rawgSource`) in both the class definition (lines 252-258) and DI registration (lines 411-417). No `List<MetadataSource>` pattern remains.

5. **SteamStoreAppDetail model** — RESOLVED. Listed in "Files to Create" (line 495) as `lib/data/services/metadata/models/steam_store_app_detail.dart` with full model specification (lines 169-219) including `@JsonSerializable()` annotations, nested classes (`SteamStoreAppData`, `SteamStoreScreenshot`, `SteamStoreGenre`, `SteamStoreReleaseDate`), and a note about handling the dynamic app ID key in responses (line 222).

6. **SteamLocalSource sparse data documented** — RESOLVED. Lines 111-119 explicitly document that `SteamLocalSource` provides "sparse metadata only" (title, externalId, coverImageUrl, heroImageUrl) and does NOT provide description, screenshots, genres, developer, or publisher. Marked as "acceptable for Sprint 14" with risk mitigation and out-of-scope sections reinforcing the decision.

7. **SteamStoreSource HTTP client** — RESOLVED. Lines 148-150 specify a dedicated Dio instance registered as a named singleton (`'steamStoreDio'`) with its own base URL (`https://store.steampowered.com/api/`) and no API key. Full DI registration shown at lines 379-389.

8. **MetadataService method migration** — RESOLVED. Lines 284-299 provide a detailed migration table mapping each method (`findMatch`, `manualSearch`, `fetchMetadata`, `batchFetchMetadata`, `initialize`) to its new location, and lines 293-299 specify how `MetadataService` constructor changes to accept `MetadataAggregator` and `RawgSource`.

9. **metadata_source_priority.dart folded into MetadataAggregator** — RESOLVED. Line 74 explicitly states the file is "intentionally folded into `MetadataAggregator`" with priority configuration embedded in the constructor. The file is absent from the "Files to Create" list.

## Remaining Notes

1. **Minor ambiguity in SteamLocalSource fallback wording**: Line 119 states "the aggregator will attempt the next source" when SteamLocalSource returns sparse data, but the Fetch Logic (lines 273-277) only falls through on `null` returns. If `SteamLocalSource.fetch()` returns sparse-but-non-null data, the aggregator will NOT fall through to `SteamStoreSource`. This is explicitly documented as acceptable for Sprint 14, so it's not a blocker — but the Generator should be aware of this behavioral distinction. In practice, `SteamLocalSource` may return `null` for games where it can't determine the appId, allowing `SteamStoreSource` to be tried in those cases.

2. **SteamLocalSource depends on SteamManifestParser for appId resolution** (line 126-127): The contract specifies this dependency but the manifest parser currently parses manifest files from disk on demand. The Generator should verify that `SteamLocalSource` can efficiently look up cached manifest data, or fall back to the `externalId` stored during import.

3. **307+ existing tests must pass without modification** (Criterion 16): This is a high bar given the invasive `MetadataService` refactoring. The Generator should write new tests for the metadata sources first, then carefully refactor `MetadataService` to ensure existing test expectations still hold.
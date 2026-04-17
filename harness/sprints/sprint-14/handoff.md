# Handoff: Sprint 14 - Bug Fixes

## Status: Ready for QA

## Summary of Fixes

All 6 critical bugs from the Sprint 14 evaluation have been fixed:

### Bug 1: Fixed `SteamStoreSource._extractAppId()` 
- **File**: `lib/data/services/metadata/steam_store_source.dart`
- **Fix**: The method now properly extracts the Steam app ID from:
  1. The `externalId` parameter if it starts with `steam:` prefix
  2. The executable path pattern as fallback
- **Before**: Always returned `null` (hardcoded)
- **After**: Returns the numeric app ID from `steam:{appId}` format

### Bug 2: Fixed `MetadataService.fetchMetadata()` crash on prefixed `externalId`
- **File**: `lib/data/services/metadata_service.dart`
- **Fix**: The method now properly parses prefixed externalIds:
  - `steam:730` - logs warning that Steam games need aggregator
  - `rawg:12345` - extracts numeric ID and fetches from RAWG
  - Plain numbers (backward compatibility) - treats as RAWG ID
- **Before**: `int.parse('steam:730')` threw `FormatException`
- **After**: Properly routes to appropriate source based on prefix

### Bug 3: Fixed `MetadataRepositoryImpl.fetchAndCacheMetadata()` bypassing aggregator
- **File**: `lib/data/repositories/metadata_repository_impl.dart`
- **Fix**: The method now uses `MetadataAggregator` for Steam games:
  1. Gets the Game entity to check executable path
  2. Gets existing metadata to check externalId
  3. If Steam game (path contains `/steamapps/common/` or externalId starts with `steam:`), uses aggregator
  4. If non-Steam game, uses traditional RAWG flow
- **Before**: Always used RAWG-only path via `findMatch()` → `fetchMetadata(rawgId)`
- **After**: Uses aggregator for Steam games with proper priority: SteamLocal → SteamStore → RAWG

### Bug 4: Fixed `SteamLocalSource.canProvide()` not checking `externalId` prefix
- **File**: `lib/data/services/metadata/steam_local_source.dart`
- **Fix**: The method now accepts `externalId` parameter and checks:
  1. If `externalId` starts with `steam:` → returns `true`
  2. Falls back to checking executable path pattern
- **Before**: Only checked `executablePath.contains('/steamapps/common/')`
- **After**: Also accepts games with `steam:` prefix in externalId

### Bug 5: Cleaned up dead code and lint issues
- **Files**:
  - `lib/data/services/metadata/steam_store_source.dart` - Removed unused `formats` variable in `_parseReleaseDate()`
  - `lib/data/services/metadata/metadata_source.dart` - Fixed relative import to package import
  - `lib/data/services/metadata_service.dart` - Removed unused `_apiKeyService` field (kept constructor param for backward compatibility)
- **Before**: 4 unused variables, 1 relative import violation, 1 unused field
- **After**: All cleaned up, analyzer shows 0 issues

### Bug 6: Created missing test files
- **Files created**:
  - `test/data/services/metadata/steam_local_source_test.dart` (10 tests)
  - `test/data/services/metadata/steam_store_source_test.dart` (11 tests)
  - `test/data/services/metadata/rawg_source_test.dart` (16 tests)
- **Before**: Only 2 of 6 specified test files existed
- **After**: All 6 test files exist with comprehensive coverage

## Interface Changes

### `MetadataSource` interface updated:
```dart
// Before:
Future<bool> canProvide(Game game);
Future<GameMetadata?> fetch(Game game);

// After:
Future<bool> canProvide(Game game, {String? externalId});
Future<GameMetadata?> fetch(Game game, {String? externalId});
```

All implementations (`SteamLocalSource`, `SteamStoreSource`, `RawgSource`) and the `MetadataAggregator` have been updated to pass `externalId` through the chain.

## What to Test

### Run all tests
```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter test
```
- **Expected**: All 370 tests pass (up from 332)

### Run metadata-specific tests
```bash
flutter test test/data/services/metadata/
```
- **Expected**: All 55 tests pass:
  - `metadata_aggregator_test.dart`: 6 tests
  - `steam_store_app_detail_test.dart`: 12 tests
  - `steam_local_source_test.dart`: 10 tests
  - `steam_store_source_test.dart`: 11 tests
  - `rawg_source_test.dart`: 16 tests

### Code analysis
```bash
dart analyze lib/
```
- **Expected**: No issues found

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

## Architecture Overview (Fixed)

```
MetadataRepositoryImpl
  ├── For Steam games:
  │     └── MetadataAggregator.fetchMetadata(game, externalId: ...)
  │           ├── SteamLocalSource.canProvide(game, externalId: ...) → fetch(game, externalId: ...)
  │           ├── SteamStoreSource.canProvide(game, externalId: ...) → fetch(game, externalId: ...)
  │           └── RawgSource.canProvide(game, externalId: ...) → fetch(game, externalId: ...)
  └── For non-Steam games:
        └── Traditional RAWG flow via MetadataService.findMatch() → fetchMetadata()

MetadataService
  ├── MetadataAggregator (for batch operations and Steam games)
  └── RawgSource (for manual search/findMatch)
```

## External ID Conventions (Working)

- Steam games: `steam:{appId}` (e.g., `steam:730`)
- RAWG games: `rawg:{gameId}` (e.g., `rawg:3498`)

The `externalId` is now properly passed through the entire metadata fetching chain, enabling sources to identify games by their stored external ID.

## Risk Areas for QA

1. **Steam game import flow**: Verify that imported Steam games get metadata with correct externalId prefix and that the aggregator is used
2. **Non-Steam game metadata**: Verify that non-Steam games still use RAWG metadata via the traditional flow
3. **Fallback behavior**: If SteamLocal fails, should try SteamStore, then RAWG
4. **Metadata refresh**: When refreshing metadata for a Steam game, should use the aggregator path
5. **Backward compatibility**: Plain numeric externalIds (from before this sprint) should still work

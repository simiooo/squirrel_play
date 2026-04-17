# Sprint Contract: Sprint 14 — Flatpak Steam Path Detection + Multi-Source Metadata Parser

## Scope

This sprint delivers two closely related enhancements:

1. **Flatpak Steam Path Detection**: Add Flatpak Steam installation path detection to `SteamDetector._detectLinuxSteam()` so Flatpak-installed Steam on Linux is correctly discovered.

2. **Multi-Source Metadata Parser**: Architect a strategy-pattern-based multi-source metadata system where metadata can be fetched from different sources (Steam local manifest, Steam Store API, RAWG API) with configurable priority ordering. Steam games should prioritize Steam's own metadata for accuracy.

## Dependencies

- Sprint 9 (Steam scanning) - Steam detection and library parsing infrastructure
- Sprint 5 (RAWG metadata) - Existing metadata service and matching engine
- Sprint 13 (focusable controls) - For any new UI elements

---

## Part 1: Flatpak Steam Path Detection

### Implementation Details

**File to modify**: `lib/data/services/steam_detector.dart`

**Change**: Add the Flatpak Steam path to the list of common paths in `_detectLinuxSteam()`, positioned after the existing `$home/.steam/steam` entry (highest priority for native installations) but before `$home/.local/share/Steam`:

```dart
final commonPaths = [
  '$home/.steam/steam',
  '$home/.var/app/com.valvesoftware.Steam/.local/share/Steam', // NEW: Flatpak
  '$home/.local/share/Steam',
  '$home/.steam/debian-installation',
];
```

**Validation**: The existing `validateSteamPath()` method checks for the `steamapps` subdirectory inside each path, which works correctly for Flatpak installations since Flatpak Steam has the same directory structure inside its container.

### Testing Requirements

Add unit tests for `SteamDetector` covering Flatpak path detection scenarios:

**Test file**: `test/data/services/steam_detector_test.dart` (new file)

**Test cases**:
1. Flatpak Steam path exists and is valid (contains `steamapps/`)
2. Flatpak Steam path doesn't exist, native paths exist
3. Neither Flatpak nor native paths exist
4. Both Flatpak and native paths exist - native path is preferred (returned first)

---

## Part 2: Multi-Source Metadata Parser (Strategy Pattern)

### Problem Statement

Currently, all metadata comes from RAWG API exclusively. For Steam games, Steam's own data (local manifest `name` field + Steam Store API) is more authoritative — it has the correct game name, doesn't require fuzzy matching, and includes Steam-specific metadata like Steam screenshots. The current single-source approach means Steam games are identified by filename heuristics rather than definitive Steam IDs.

### Architecture Overview

Create a new directory structure under `lib/data/services/metadata/`:

```
lib/data/services/metadata/
├── metadata_source.dart           # Abstract interface
├── metadata_source_type.dart      # Enum: steamLocal, steamStore, rawg
├── steam_local_source.dart        # Steam manifest data (name, appId, installDir)
├── steam_store_source.dart        # Steam Store API (screenshots, descriptions)
├── rawg_source.dart               # Existing RAWG API (wrapped)
├── metadata_aggregator.dart       # Orchestrates sources by priority
└── models/
    └── steam_store_app_detail.dart  # Steam Store API response model
```

**Note**: `metadata_source_priority.dart` is intentionally folded into `MetadataAggregator` — no separate file needed. Priority configuration is embedded in the aggregator's constructor.

### Component Specifications

#### 1. `MetadataSource` Interface (`metadata_source.dart`)

```dart
abstract class MetadataSource {
  /// Unique identifier for this source.
  MetadataSourceType get sourceType;

  /// Whether this source can provide metadata for the given game.
  /// For Steam sources, checks if executablePath contains '/steamapps/common/'.
  Future<bool> canProvide(Game game);

  /// Fetches metadata from this source.
  /// Returns null if metadata cannot be fetched.
  Future<GameMetadata?> fetch(Game game);

  /// Human-readable name for UI display.
  String get displayName;
}
```

#### 2. `MetadataSourceType` Enum (`metadata_source_type.dart`)

```dart
enum MetadataSourceType {
  steamLocal,  // Data from local Steam manifest files
  steamStore,  // Data from Steam Store Web API
  rawg,        // Data from RAWG API
}
```

#### 3. `SteamLocalSource` (`steam_local_source.dart`)

**Responsibilities**:
- `canProvide()`: Returns `true` if the game's `executablePath` contains `/steamapps/common/` (Steam library pattern), OR if the game has existing metadata with `externalId` prefixed as `steam:`
- `fetch()`: Returns sparse metadata from Steam CDN URLs:
  - `title`: Extracted from the executable path's parent directory name (fallback) or from cached manifest data if available
  - `externalId`: `steam:{appId}` where appId is extracted from the manifest file path or existing metadata
  - `coverImageUrl`: `https://cdn.akamai.steamstatic.com/steam/apps/{appId}/header.jpg`
  - `heroImageUrl`: `https://cdn.akamai.steamstatic.com/steam/apps/{appId}/library_hero.jpg`
  - `lastFetched`: `DateTime.now()`

**Important**: `SteamLocalSource` provides **sparse metadata only** — name + CDN header/hero images. It does NOT provide description, screenshots, genres, developer, or publisher. This is acceptable for Sprint 14. Steam games will get enriched data when `SteamStoreSource` is called as a fallback (if `SteamLocalSource` returns sparse data, the aggregator will attempt the next source).

**Steam App ID Resolution**:
1. Check if game has existing metadata with `externalId` starting with `steam:`
2. If not, check if `executablePath` matches Steam library pattern and extract `appId` from the corresponding `appmanifest_{appId}.acf` file path
3. Return `null` if appId cannot be determined

**Dependencies**: `SteamManifestParser` (for looking up cached manifest data by executable path)

#### 4. `SteamStoreSource` (`steam_store_source.dart`)

**Responsibilities**:
- `canProvide()`: Returns `true` if the game's `executablePath` contains `/steamapps/common/` OR if game has metadata with `externalId` prefixed as `steam:`
- `fetch()`: Calls Steam Store Web API to get rich metadata:
  - Detailed description
  - Screenshots
  - Developer/publisher
  - Genres
  - Release date
  - Capsule images

**API Details**:
- Steam Store API is free, unauthenticated, and returns JSON — no API key needed
- Endpoint: `https://store.steampowered.com/api/appdetails?appids={appId}`
- Rate-limited: max 200 requests per minute (generous)
- Implement a 200ms delay between requests for safety
- Response format uses the app ID as a dynamic JSON key: `{"730": {"success": true, "data": {...}}}`

**HTTP Client**:
- `SteamStoreSource` receives a dedicated `Dio` instance via DI
- This is a separate instance from RAWG's Dio, with its own base URL (`https://store.steampowered.com/api/`) and no API key
- Register as named instance: `getIt.registerSingleton<Dio>(steamStoreDio, instanceName: 'steamStoreDio')`

**Error Handling**:
- Network errors, 404s, rate limits: return `null` and let aggregator fall through to next source
- Log which sources were tried for debugging (use `dart:developer` `log()` function)

**Response Mapping** (from `SteamStoreAppDetail`):
```
response["{appId}"]["data"]["name"] → GameMetadata.description (prefixed with title)
response["{appId}"]["data"]["short_description"] → GameMetadata.description
response["{appId}"]["data"]["header_image"] → GameMetadata.coverImageUrl
response["{appId}"]["data"]["background_raw"] or ["background"] → GameMetadata.heroImageUrl
response["{appId}"]["data"]["screenshots"][*]["path_full"] → GameMetadata.screenshots
response["{appId}"]["data"]["developers"][0] → GameMetadata.developer
response["{appId}"]["data"]["publishers"][0] → GameMetadata.publisher
response["{appId}"]["data"]["genres"][*]["description"] → GameMetadata.genres
response["{appId}"]["data"]["release_date"]["date"] → GameMetadata.releaseDate (parsed)
```

#### 5. `SteamStoreAppDetail` Model (`models/steam_store_app_detail.dart`)

**Purpose**: JSON-serializable model for Steam Store API response parsing.

**Structure**:
```dart
@JsonSerializable()
class SteamStoreAppDetail {
  final bool success;
  final SteamStoreAppData? data;
  
  factory SteamStoreAppDetail.fromJson(Map<String, dynamic> json) => ...
}

@JsonSerializable()
class SteamStoreAppData {
  final String name;
  final String shortDescription;
  final String headerImage;
  @JsonKey(name: 'background_raw')
  final String? backgroundRaw;
  final List<SteamStoreScreenshot> screenshots;
  final List<String> developers;
  final List<String> publishers;
  final List<SteamStoreGenre> genres;
  final SteamStoreReleaseDate releaseDate;
  
  factory SteamStoreAppData.fromJson(Map<String, dynamic> json) => ...
}

@JsonSerializable()
class SteamStoreScreenshot {
  @JsonKey(name: 'path_full')
  final String pathFull;
  
  factory SteamStoreScreenshot.fromJson(Map<String, dynamic> json) => ...
}

@JsonSerializable()
class SteamStoreGenre {
  final String description;
  
  factory SteamStoreGenre.fromJson(Map<String, dynamic> json) => ...
}

@JsonSerializable()
class SteamStoreReleaseDate {
  final String date;
  
  factory SteamStoreReleaseDate.fromJson(Map<String, dynamic> json) => ...
}
```

**Note**: The response uses the app ID as a dynamic key. The parsing logic in `SteamStoreSource` must handle this by extracting the first (and only) key from the response object.

#### 6. `RawgSource` (`rawg_source.dart`)

**Responsibilities**:
- Wraps the existing `MetadataMatchingEngine` and `RawgApiClient`
- `canProvide()`: Returns `true` if the RAWG API key is configured
- `fetch()`: Uses the existing matching/fetching logic from `MetadataService`
- Returns `GameMetadata` with `externalId` as `rawg:{gameId}`

**Internal Methods** (not part of `MetadataSource` interface):
- `findMatch(String filename)` → returns `MetadataMatchResult?` (used by `MetadataService`)
- `searchManually(String query)` → returns `List<MetadataAlternative>` (used by `MetadataService`)

**Note**: This preserves all existing RAWG matching logic without modification.

#### 7. `MetadataAggregator` (`metadata_aggregator.dart`)

**Responsibilities**:
- Takes named source parameters and builds internal prioritized source lists
- Default priority for Steam games: `[SteamLocalSource, SteamStoreSource, RawgSource]`
- Default priority for non-Steam games: `[RawgSource]`

**Constructor** (named parameters):
```dart
class MetadataAggregator {
  final SteamLocalSource _steamLocalSource;
  final SteamStoreSource _steamStoreSource;
  final RawgSource _rawgSource;

  MetadataAggregator({
    required SteamLocalSource steamLocalSource,
    required SteamStoreSource steamStoreSource,
    required RawgSource rawgSource,
  })  : _steamLocalSource = steamLocalSource,
        _steamStoreSource = steamStoreSource,
        _rawgSource = rawgSource;

  /// Fetches metadata by trying sources in priority order.
  /// Returns null if all sources fail.
  Future<GameMetadata?> fetchMetadata(Game game);

  /// Determines if a game is a Steam game based on executable path.
  bool _isSteamGame(Game game);
}
```

**Fetch Logic**:
1. Determine if this is a Steam game via `_isSteamGame(game)` (checks if `executablePath` contains `/steamapps/common/`)
2. Select appropriate source priority list
3. Iterate through sources in priority order
4. Call `canProvide()` on each source
5. If a source can provide, call `fetch()` and return the result
6. Fall through to next source if `fetch()` returns null
7. If all sources fail, return null
8. Log which sources were tried and which succeeded/failed for debugging

### Integration with `MetadataService`

**File to modify**: `lib/data/services/metadata_service.dart`

**Method Migration**:

| Method | New Location | Notes |
|--------|--------------|-------|
| `findMatch(String filename)` | `RawgSource._findMatch()` | Internal method, called by `MetadataService.findMatch()` |
| `manualSearch(String query)` | `MetadataService.manualSearch()` | Public API, delegates to `RawgSource.searchManually()` |
| `fetchMetadata(String gameId, String externalId)` | `MetadataAggregator.fetchMetadata()` | Now aggregator-driven |
| `batchFetchMetadata(List<Game>, ...)` | `MetadataAggregator.fetchMetadata()` | Now aggregator-driven per game |
| `initialize()` | `MetadataService.initialize()` | Stays, but moves RAWG client init to `RawgSource` |

**Changes**:
1. Add `MetadataAggregator` and `RawgSource` as dependencies
2. `findMatch()` delegates to `RawgSource.findMatch()`
3. `manualSearch()` delegates to `RawgSource.searchManually()`
4. `fetchMetadata()` uses `MetadataAggregator.fetchMetadata()` instead of direct RAWG calls
5. `batchFetchMetadata()` now iterates through games and calls `MetadataAggregator.fetchMetadata()` for each
6. `initialize()` moves RAWG client initialization to `RawgSource.initialize()`

**Constructor Update**:
```dart
class MetadataService {
  final ApiKeyService _apiKeyService;
  final MetadataAggregator _metadataAggregator;
  final RawgSource _rawgSource;
  // ... existing fields

  MetadataService({
    required ApiKeyService apiKeyService,
    required MetadataAggregator metadataAggregator,
    required RawgSource rawgSource,
  })  : _apiKeyService = apiKeyService,
        _metadataAggregator = metadataAggregator,
        _rawgSource = rawgSource;
  // ...
}
```

### Integration with `MetadataRepositoryImpl`

**File to modify**: `lib/data/repositories/metadata_repository_impl.dart`

**Changes**:
1. `fetchAndCacheMetadata()` now calls `MetadataService.fetchMetadata()` which internally uses `MetadataAggregator`
2. `batchFetchMetadata()` delegates to `MetadataService.batchFetchMetadata()` which now uses the aggregator
3. `manualSearch()` continues to delegate to `MetadataService.manualSearch()`
4. `updateMetadata()` uses `MetadataService.fetchMetadata()` with the new external ID

No breaking changes to the public API of `MetadataRepositoryImpl`.

### Steam Game Import Data Flow

**Problem**: When a Steam game is imported via `SteamScannerBloc`, the `steamGame.appId` is available but lost after import. The `Game` entity has no `steamAppId` field, and `SteamLocalSource.canProvide()` needs the appId to function.

**Solution**: During Steam import in `SteamScannerBloc._onImportSelectedGames()`, create an initial `GameMetadata` record with:
- `externalId: 'steam:${steamGame.appId}'`
- `lastFetched: DateTime.now()`
- Minimal other fields (title from `steamGame.name`)

This way, `SteamLocalSource.canProvide()` can find the appId from `GameMetadata.externalId` when later called for metadata enrichment.

**Implementation in `SteamScannerBloc`**:
```dart
// After creating and saving the game
await _gameRepository.addGame(game);

// Create initial metadata with Steam app ID
final initialMetadata = GameMetadata(
  gameId: game.id,
  externalId: 'steam:${steamGame.appId}',
  description: null,
  coverImageUrl: null,
  heroImageUrl: null,
  genres: const [],
  screenshots: const [],
  lastFetched: DateTime.now(),
);
await _metadataRepository.saveMetadata(initialMetadata);

// Then trigger metadata fetch for enrichment
_metadataBloc.add(FetchMetadata(...));
```

### Data Model Conventions

- `GameMetadata.externalId` already exists as `String?` — no schema change needed
- Convention: `externalId` is prefixed with source type:
  - `steam:730` (Steam app ID)
  - `rawg:3498` (RAWG game ID)
- `Game` entity: No new fields needed; Steam app ID is derived from `executablePath` matching Steam library pattern or stored as `externalId` with `steam:` prefix on the associated metadata record

### Dependency Injection Updates

**File to modify**: `lib/app/di.dart`

**New Registrations**:
```dart
// Dio instance for Steam Store API (separate from RAWG)
getIt.registerSingleton<Dio>(
  Dio(
    BaseOptions(
      baseUrl: 'https://store.steampowered.com/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  ),
  instanceName: 'steamStoreDio',
);

// Metadata Sources (singletons - aggregator holds permanent references)
getIt.registerSingleton<SteamLocalSource>(
  SteamLocalSource(
    manifestParser: getIt<SteamManifestParser>(),
  ),
);

getIt.registerSingleton<SteamStoreSource>(
  SteamStoreSource(
    dio: getIt<Dio>(instanceName: 'steamStoreDio'),
  ),
);

getIt.registerSingleton<RawgSource>(
  RawgSource(
    apiKeyService: getIt<ApiKeyService>(),
  ),
);

// Metadata Aggregator (singleton with named source parameters)
getIt.registerSingleton<MetadataAggregator>(
  MetadataAggregator(
    steamLocalSource: getIt<SteamLocalSource>(),
    steamStoreSource: getIt<SteamStoreSource>(),
    rawgSource: getIt<RawgSource>(),
  ),
);

// Update MetadataService registration to include aggregator and rawgSource
getIt.registerSingleton<MetadataService>(
  MetadataService(
    apiKeyService: getIt<ApiKeyService>(),
    metadataAggregator: getIt<MetadataAggregator>(),
    rawgSource: getIt<RawgSource>(),
  ),
);
```

### Error Handling

- Each `MetadataSource.fetch()` returns `null` on failure (no exceptions propagated to caller)
- `MetadataAggregator` logs which sources were tried and which failed for debugging (use `dart:developer` `log()`)
- Steam Store API errors (network, rate limit, 404) silently fall through to next source
- RAWG API errors preserved as-is (existing behavior)

---

## Success Criteria

### Part 1: Flatpak Steam Path Detection

| Criterion | Verification Method |
|-----------|-------------------|
| 1. Flatpak path added to `_detectLinuxSteam()` | Code review: path `'$home/.var/app/com.valvesoftware.Steam/.local/share/Steam'` appears in `commonPaths` list after `$home/.steam/steam` and before `$home/.local/share/Steam` |
| 2. Flatpak path is validated correctly | Unit test: `validateSteamPath()` returns `true` when `steamapps/` subdirectory exists in Flatpak path |
| 3. Native path preferred over Flatpak | Unit test: When both `~/.steam/steam` and Flatpak path exist, `detectSteamPath()` returns native path |
| 4. Flatpak path detected when native missing | Unit test: When only Flatpak path exists, `detectSteamPath()` returns Flatpak path |
| 5. Unit tests exist and pass | Run `flutter test test/data/services/steam_detector_test.dart` - all tests pass |

### Part 2: Multi-Source Metadata Parser

| Criterion | Verification Method |
|-----------|-------------------|
| 1. `MetadataSource` interface exists | Code review: `lib/data/services/metadata/metadata_source.dart` contains abstract class with `sourceType`, `canProvide()`, `fetch()`, `displayName` |
| 2. `MetadataSourceType` enum exists | Code review: `lib/data/services/metadata/metadata_source_type.dart` contains enum with `steamLocal`, `steamStore`, `rawg` |
| 3. `SteamLocalSource` implemented | Code review: `lib/data/services/metadata/steam_local_source.dart` implements `MetadataSource`, detects Steam games by `/steamapps/common/` path pattern |
| 4. `SteamStoreSource` implemented | Code review: `lib/data/services/metadata/steam_store_source.dart` calls Steam Store API, implements 200ms rate limiting, uses named Dio instance |
| 5. `SteamStoreAppDetail` model exists | Code review: `lib/data/services/metadata/models/steam_store_app_detail.dart` with `json_serializable` annotations |
| 6. `RawgSource` implemented | Code review: `lib/data/services/metadata/rawg_source.dart` wraps existing `MetadataMatchingEngine`, has `findMatch()` and `searchManually()` methods |
| 7. `MetadataAggregator` implemented | Code review: `lib/data/services/metadata/metadata_aggregator.dart` uses named constructor parameters, orchestrates sources by priority |
| 8. Steam games use Steam-priority order | Unit test: Mock sources and verify `SteamLocalSource.fetch()` is called before `SteamStoreSource.fetch()` for Steam games |
| 9. Non-Steam games use RAWG only | Unit test: Non-Steam game (no Steam path) uses only `RawgSource` |
| 10. Fallback works correctly | Unit test: When `SteamLocalSource` returns null, `SteamStoreSource` is tried; when both fail, `RawgSource` is tried |
| 11. `externalId` uses source prefix | Unit test: Steam metadata has `externalId` like `steam:730`, RAWG metadata has `externalId` like `rawg:3498` |
| 12. `MetadataService` refactored | Code review: `lib/data/services/metadata_service.dart` uses `MetadataAggregator`, delegates `findMatch()` and `manualSearch()` to `RawgSource` |
| 13. `MetadataRepositoryImpl` updated | Code review: `lib/data/repositories/metadata_repository_impl.dart` works with new aggregator-driven flow |
| 14. Steam import stores `externalId` | Code review: `SteamScannerBloc._onImportSelectedGames()` creates initial `GameMetadata` with `externalId: 'steam:{appId}'` |
| 15. DI registrations updated | Code review: `lib/app/di.dart` registers all metadata sources as singletons, uses named Dio for Steam Store |
| 16. All existing tests pass | Run `flutter test` - all 307+ existing tests pass without modification |
| 17. New metadata source tests pass | Run `flutter test` - new tests for metadata sources pass |

---

## Out of Scope for This Sprint

1. **Metadata merging**: Combining data from multiple sources (e.g., Steam's name + RAWG's rating). This sprint uses first-successful-source only.
2. **Steam Store API caching**: Caching Steam Store API responses to reduce API calls.
3. **Background metadata refresh**: Automatically refreshing metadata after a period.
4. **UI changes**: No new UI screens or widgets (except any required for testing).
5. **Steam Workshop integration**: Not part of this sprint.
6. **Non-Steam game store sources**: GOG, Epic, etc. are not included.
7. **Rich data from SteamLocalSource**: Only name + CDN images; full metadata requires Steam Store API fallback.

---

## Files to Create/Modify

### New Files
1. `lib/data/services/metadata/metadata_source.dart`
2. `lib/data/services/metadata/metadata_source_type.dart`
3. `lib/data/services/metadata/steam_local_source.dart`
4. `lib/data/services/metadata/steam_store_source.dart`
5. `lib/data/services/metadata/rawg_source.dart`
6. `lib/data/services/metadata/metadata_aggregator.dart`
7. `lib/data/services/metadata/models/steam_store_app_detail.dart`
8. `test/data/services/steam_detector_test.dart`
9. `test/data/services/metadata/steam_local_source_test.dart`
10. `test/data/services/metadata/steam_store_source_test.dart`
11. `test/data/services/metadata/rawg_source_test.dart`
12. `test/data/services/metadata/metadata_aggregator_test.dart`
13. `test/data/services/metadata/steam_store_app_detail_test.dart`

### Modified Files
1. `lib/data/services/steam_detector.dart` - Add Flatpak path
2. `lib/data/services/metadata_service.dart` - Refactor to use `MetadataAggregator` and `RawgSource`
3. `lib/data/repositories/metadata_repository_impl.dart` - Update to work with aggregator-driven flow
4. `lib/presentation/blocs/steam_scanner/steam_scanner_bloc.dart` - Create initial metadata with `externalId: 'steam:{appId}'` during import
5. `lib/app/di.dart` - Register new metadata sources, aggregator, and named Dio instance

---

## Implementation Order

1. **Phase 1**: Flatpak path detection
   - Modify `steam_detector.dart`
   - Write unit tests for `SteamDetector`
   - Verify on Linux (if available)

2. **Phase 2**: Steam Store API model
   - Create `SteamStoreAppDetail` model with `json_serializable`
   - Write unit tests for model parsing

3. **Phase 3**: Metadata source infrastructure
   - Create `MetadataSource` interface
   - Create `MetadataSourceType` enum
   - Create `MetadataAggregator` with named constructor parameters

4. **Phase 4**: Individual metadata sources
   - Implement `SteamLocalSource` (sparse metadata only)
   - Implement `SteamStoreSource` with Dio and rate limiting
   - Implement `RawgSource` wrapping existing matching engine

5. **Phase 5**: Integration
   - Refactor `MetadataService` to use `MetadataAggregator`
   - Update `MetadataRepositoryImpl` for aggregator-driven flow
   - Update `SteamScannerBloc` to store `externalId` during import
   - Update DI registrations

6. **Phase 6**: Testing and validation
   - Write comprehensive unit tests
   - Verify all existing tests pass
   - Test with real Steam games (if available)

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing metadata fetching | Preserve `MetadataMatchingEngine` inside `RawgSource`; all existing RAWG logic remains unchanged |
| Steam Store API rate limiting | Implement 200ms delay between requests; fall through to RAWG on rate limit |
| Flatpak path not working on all distros | Position Flatpak path after native path so native takes precedence; validate with `steamapps/` check |
| SteamLocalSource provides sparse data | Documented as acceptable for Sprint 14; SteamStoreSource provides fallback enrichment |
| Steam appId lost after import | Create initial `GameMetadata` with `externalId: 'steam:{appId}'` during import |
| Circular dependencies in DI | Use singletons for sources (aggregator holds permanent references) |
| Performance degradation | `MetadataAggregator` short-circuits on first successful source; no unnecessary API calls |

---

## Definition of Done

- [ ] All success criteria met
- [ ] All new files created with proper headers and documentation
- [ ] All modified files updated without breaking existing functionality
- [ ] Unit tests written for all new components
- [ ] All existing tests pass (307+)
- [ ] Code follows project style guidelines (trailing commas, package imports)
- [ ] DI registrations verified working
- [ ] Self-evaluation completed
- [ ] Handoff document written

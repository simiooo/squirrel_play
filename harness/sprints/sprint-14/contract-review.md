# Contract Review: Sprint 14

## Assessment: NEEDS_REVISION

The contract is generally well-structured and addresses a real architectural gap (Flatpak + multi-source metadata). However, there are several integration blind spots and inconsistencies that will cause implementation failures if not resolved before work begins.

---

## Scope Coverage

**Alignment with Sprint 14 spec**: GOOD. Both Part 1 (Flatpak path) and Part 2 (Multi-Source Metadata Parser) are covered. The scope is faithful to the spec.

**Concerns**:
- The spec mentions `metadata_source_priority.dart` as a separate file in the directory structure, but the contract omits it without explanation. Is priority configuration embedded in `MetadataAggregator` or extracted? The contract should clarify.
- The spec mentions a `_isSteamGame()` helper method on `MetadataAggregator`, which the contract includes. Good.
- The spec mentions `mergeMetadata()` as a future method on `MetadataAggregator` — the contract correctly marks this as out of scope.

---

## Success Criteria Review

### Part 1: Flatpak Steam Path Detection

- **Criterion 1** (Flatpak path added): ADEQUATE — Specific path string and position are verifiable.
- **Criterion 2** (Flatpak path validated correctly): ADEQUATE — References `validateSteamPath()` return behavior.
- **Criterion 3** (Native path preferred over Flatpak): ADEQUATE — Clear ordering expectation.
- **Criterion 4** (Flatpak path detected when native missing): ADEQUATE.
- **Criterion 5** (Unit tests exist and pass): ADEQUATE.

**Part 1 assessment**: All criteria are testable and objective. No issues.

### Part 2: Multi-Source Metadata Parser

- **Criterion 1-6** (Individual source implementations): ADEQUATE for code review criteria.
- **Criterion 7** (Steam games use Steam-priority order): **CONCERN** — "Unit test: Steam game with `steamAppId` tries `SteamLocalSource` first" — but how does the test verify source ordering unless the aggregator exposes its source list or logs which sources were tried? The test needs to mock sources and verify call order. The criterion should specify this.
- **Criterion 8** (Non-Steam games use RAWG only): ADEQUATE.
- **Criterion 9** (Fallback works correctly): ADEQUATE.
- **Criterion 10** (`externalId` uses source prefix): **CONCERN** — The `externalId` prefix convention (`steam:730`, `rawg:3498`) is mentioned, but the contract doesn't specify WHERE the prefix is set. `SteamLocalSource.fetch()` returns a `GameMetadata` — does it set `externalId` to `steam:{appId}`? And when a Steam game is imported via `SteamGamesTab`, the current code doesn't set `externalId` at all. This is a critical data flow gap.
- **Criterion 11** (`MetadataService` refactored): ADEQUATE, but see architectural concerns below.
- **Criterion 12** (DI registrations updated): ADEQUATE.
- **Criterion 13** (All existing tests pass): ADEQUATE but high risk — the `MetadataService` refactoring is invasive.
- **Criterion 14** (New metadata source tests pass): ADEQUATE.

---

## Technical Approach Alignment with Existing Codebase

### Issue 1: `MetadataService` Constructor Signature Mismatch (CRITICAL)

**Current constructor** (`lib/data/services/metadata_service.dart` line 26):
```dart
MetadataService({required ApiKeyService apiKeyService})
```

**Contract proposes**:
```dart
MetadataService({
  required ApiKeyService apiKeyService,
  required MetadataAggregator metadataAggregator,
})
```

This is a breaking change. `MetadataService` is registered as a singleton in `di.dart` (line 77-79):
```dart
getIt.registerSingleton<MetadataService>(
  MetadataService(apiKeyService: getIt<ApiKeyService>()),
);
```

Additionally, `MetadataService` is initialized async in `di.dart` (line 158):
```dart
await getIt<MetadataService>().initialize();
```

The `initialize()` method creates the `RawgApiClient` and `MetadataMatchingEngine` lazily. With the new architecture, `RawgApiClient` initialization moves into `RawgSource`. The contract needs to address:
- Should `MetadataService.initialize()` still exist?
- What happens to the lazy `_apiClient` and `_matchingEngine` fields?
- Should `RawgSource` handle its own API client initialization?

**Risk**: If not handled carefully, the lazy initialization pattern will break, and `MetadataService` will fail to route to `RawgSource` when the API key is set after startup.

### Issue 2: DI Registration Contradiction (MAJOR)

The contract shows:
```dart
getIt.registerFactory<SteamLocalSource>(...)
getIt.registerFactory<SteamStoreSource>(...)
getIt.registerFactory<RawgSource>(...)

getIt.registerSingleton<MetadataAggregator>(
  MetadataAggregator(
    steamLocalSource: getIt<SteamLocalSource>(),
    steamStoreSource: getIt<SteamStoreSource>(),
    rawgSource: getIt<RawgSource>(),
  ),
);
```

`MetadataAggregator` is a singleton that receives instances of factory-registered sources. This means:
- The aggregator holds **one instance** of each source, forever
- If `SteamStoreSource` needs to be refreshed (e.g., API client state), it won't be
- Factory registration is pointless here since the aggregator captures the instance at creation time

**Recommendation**: Either:
- Register all sources as singletons (since the aggregator holds them permanently anyway), OR
- Have the aggregator accept factory functions (`ValueGetter<SteamLocalSource>`) and resolve fresh instances per call

The AGENTS.md warns: "BLoCs that need fresh state per dialog/screen use `registerFactory`, not `registerSingleton`" — but these are **services**, not BLoCs. Services that hold stateless logic (like API clients) should generally be singletons.

### Issue 3: `MetadataSource.canProvide()` and the `steamAppId` Parameter (MAJOR)

The contract defines:
```dart
Future<bool> canProvide(Game game, {String? steamAppId});
Future<GameMetadata?> fetch(Game game, {String? steamAppId});
```

**Problem**: Where does `steamAppId` come from? The `Game` entity has no `steamAppId` field:

```dart
class Game extends Equatable {
  final String id;
  final String title;
  final String executablePath;
  final String? directoryId;
  ...
}
```

The contract says: "Steam app ID is derived from `executablePath` matching Steam library pattern (already parsed by `SteamManifestParser`) or stored as `externalId` with `steam:` prefix on the associated metadata record."

But `GameMetadata.externalId` is only populated **after** metadata is fetched. At the time `canProvide()` is called, metadata may not exist yet. This creates a circular dependency:
1. To know if a game is a Steam game, we need its `steamAppId`
2. To get `steamAppId`, we need metadata (stored in `externalId`)
3. But we're calling `canProvide()` **to decide which metadata source to use**

**Resolution needed**: The contract should specify one of these approaches:
- (a) Match `executablePath` containing `/steamapps/common/` as the primary Steam detection (no `steamAppId` needed for `canProvide`), then extract `appId` from path pattern for `fetch()`
- (b) Add a lookup from `SteamManifestParser`'s cached data to find the `appId` given an `executablePath`
- (c) Store the `steamAppId` on the `Game` entity (schema change)

Option (a) is what the contract hints at but doesn't make explicit enough. The `_isSteamGame()` method is described but the `canProvide()` / `fetch()` signatures already accept `steamAppId` as optional — this inconsistency needs resolution.

### Issue 4: Data Flow Gap During Steam Game Import (MAJOR)

In `SteamScannerBloc._onImportSelectedGames()` (lines 243-321), the imported game is created as:
```dart
final game = Game(
  id: _uuid.v4(),
  title: steamGame.name,
  executablePath: executablePath,
  addedDate: DateTime.now(),
);
```

The `steamGame.appId` (the Steam application ID) is **never saved** anywhere. It's not stored on `Game`, and metadata isn't created during import (metadata fetch is triggered via a BLoC event).

This means when `SteamLocalSource.canProvide()` is later called for this game, it won't find a `steamAppId` in `externalId` (because metadata hasn't been fetched yet) and won't have it from the `Game` entity either.

**The contract MUST address this**: Either:
- Store `steam:{appId}` in `GameMetadata.externalId` during the Steam import process (not just during metadata fetch)
- Or modify the import flow to create an initial GameMetadata record with `externalId: 'steam:{appId}'`
- Or have `SteamLocalSource` look up the `appId` by matching `executablePath` against cached `SteamManifestParser` data

### Issue 5: `MetadataService` Refactoring Completeness (MAJOR)

The contract says to "Replace the current single-source logic in `findMatch()` and `fetchMetadata()` with `MetadataAggregator`". But `MetadataService` is accessed through `MetadataRepositoryImpl`, which has its own orchestration logic:
- `fetchAndCacheMetadata()` calls `_metadataService.findMatch()` then `_metadataService.fetchMetadata()`
- `batchFetchMetadata()` iterates through games and calls `fetchAndCacheMetadata()`

The refactoring must also update `MetadataRepositoryImpl` since it's the one calling `MetadataService` methods. The contract doesn't mention this file at all.

Additionally, `MetadataService` has these public methods that callers depend on:
- `findMatch(String filename)` — returns `MetadataMatchResult?`
- `manualSearch(String query)` — returns `List<MetadataAlternative>`
- `fetchMetadata(String gameId, String externalId)` — returns `GameMetadata?`
- `batchFetchMetadata(List<Game>, {Map<String, String>?})` — returns `List<GameMetadata>`

After refactoring, some of these (like `findMatch` and `manualSearch`) become `RawgSource`-specific, while the aggregator-oriented flow becomes the primary entry point. The contract should specify which methods remain on `MetadataService` and which move to other classes.

### Issue 6: Steam Store API Error Handling (MINOR)

The contract says the Steam Store API endpoint is `https://store.steampowered.com/api/appdetails?appids={appId}`. The response format for this endpoint returns:
```json
{"730": {"success": true, "data": {...}}}
```

or:
```json
{"730": {"success": false}}
```

Note the **game ID is a key, not a predictable field name**. The contract should document that `SteamStoreSource` must parse the response using the `appId` as the key, since the JSON structure uses the app ID as a dynamic key. This is a common source of bugs.

---

## Missing Integration Points

1. **`SteamManifestParser` as a dependency of `SteamLocalSource`**: The contract shows `SteamLocalSource` depending on `SteamManifestParser`, but `SteamManifestParser` currently parses manifest files from disk on-demand (it doesn't maintain an in-memory cache). `SteamLocalSource.fetch()` would need to either:
   - Re-parse manifest files (slow, disk I/O)
   - Access a cached map of `appId → SteamManifestData`
   - Or work purely from `GameMetadata.externalId` and CDN URLs (no disk access needed for basic cover images)

   The contract says `SteamLocalSource` "uses the `name` field as the authoritative game title, `appId` for Steam Store linking" — this implies it needs `SteamManifestData`. But how does it get it? There's no in-memory cache of manifests.

2. **`MetadataRepositoryImpl` updates**: As noted above, this is not mentioned in the contract's "Files to Modify" section but MUST be updated.

3. **HTTP client for Steam Store API**: The contract doesn't specify what HTTP client `SteamStoreSource` should use. The project uses `dio` for RAWG. Should `SteamStoreSource` use `dio` as well? The `RawgApiClient` has rate-limiting, retry logic, and error handling built in. `SteamStoreSource` needs similar infrastructure.

4. **Logger dependency**: The contract shows `MetadataAggregator` and `SteamStoreSource` taking a `Logger` dependency, but the project doesn't appear to use a logging package (no `logger` in pubspec dependencies). Should use `dart:developer` log or the `print` statements used in `RawgApiClient`.

---

## Architectural Concerns with Strategy Pattern Implementation

### Concern 1: Singleton vs Factory Semantics

As discussed in Issue 2, the DI strategy is inconsistent. The `MetadataAggregator` is a singleton holding references to what could be stateless service instances. This is fine **if** the sources are truly stateless. But `RawgSource` wraps `MetadataMatchingEngine` which wraps `RawgApiClient` which has rate-limiting state (`_requestTimestamps`). If `RawgSource` holds a `RawgApiClient` instance, that stateful rate limiter is now shared across all calls, which is actually desirable. Confirm this is intentional.

### Concern 2: Aggregator's First-Successful-Source Strategy

The contract specifies:
> "If a source can provide, call `fetch()` and return the result. Fall through to next source if `fetch()` returns null."

This is a **first-successful-source** strategy, not a merging strategy. The contract correctly marks merging as out of scope. However, this means:

- If `SteamLocalSource` can provide metadata (the game's appId is known), it will ALWAYS be used, even if its data is sparse (just name + cover image URL, no description, no screenshots).
- The `SteamLocalSource` returns minimal data: title from manifest, cover image from CDN. It won't have screenshots, genres, developer, etc.
- This means Steam games will get **less metadata** than non-Steam games (which get full RAWG data), unless `SteamStoreSource` falls through on `SteamLocalSource` success.

**Recommendation**: Either:
- (a) Acknowledge this limitation explicitly and accept that Steam games will initially get sparse metadata from `SteamLocalSource` (name + cover image only)
- (b) Change `SteamLocalSource.fetch()` to return `null` when data is too sparse, letting it fall through to `SteamStoreSource`
- (c) Document that the intended flow is: `SteamLocalSource` provides quick local data immediately, then `SteamStoreSource` enriches in background (but this would require merging, which is out of scope)

Option (a) is pragmatic for this sprint, but should be explicitly stated.

### Concern 3: `MetadataAggregator` Constructor Inconsistency

The contract shows two different constructor patterns for `MetadataAggregator`:

**In the class definition**:
```dart
MetadataAggregator({required List<MetadataSource> sources, Logger? logger})
```

**In DI registration**:
```dart
MetadataAggregator(
  steamLocalSource: getIt<SteamLocalSource>(),
  steamStoreSource: getIt<SteamStoreSource>(),
  rawgSource: getIt<RawgSource>(),
)
```

These are incompatible. The class takes a `List<MetadataSource>`, but DI registration passes named parameters. The contract should pick one pattern and stick with it. I'd recommend named parameters for explicitness, with the internal `_sources` list built from those parameters.

---

## Steam Store API Integration Specification Quality

### Strengths
- Correct endpoint URL documented (`https://store.steampowered.com/api/appdetails?appids={appId}`)
- Rate limiting strategy is reasonable (200ms delay)
- Error handling (return null, fall through) is appropriate
- No API key needed — correctly identified

### Weaknesses

1. **No response parsing specification**: The Steam Store API returns data nested under the app ID key. The contract should include a sample response mapping:
   ```
   response["730"]["data"]["name"] → GameMetadata.title (via description field?)
   response["730"]["data"]["short_description"] → GameMetadata.description
   response["730"]["data"]["header_image"] → GameMetadata.coverImageUrl
   response["730"]["data"]["screenshots"][*]["path_full"] → GameMetadata.screenshots
   response["730"]["data"]["developers"] → GameMetadata.developer
   response["730"]["data"]["publishers"] → GameMetadata.publisher
   response["730"]["data"]["genres"][*]["description"] → GameMetadata.genres
   response["730"]["data"]["release_date"]["date"] → GameMetadata.releaseDate
   ```

2. **No model class for Steam Store API response**: The project uses `json_serializable` for RAWG models. `SteamStoreSource` needs a model class for deserializing Steam Store API responses. This should be in the "Files to Create" list.

3. **Missing CDN URL for hero image**: The contract mentions `https://cdn.akamai.steamstatic.com/steam/apps/{appId}/library_hero.jpg` for `SteamLocalSource`, but doesn't mention this for `SteamStoreSource`. `SteamStoreSource` should use `response["730"]["data"]["background_raw"]` or similar field from the API response, not hard-code CDN URLs.

4. **Missing `RawgApiClient` reuse vs new Dio instance**: Should `SteamStoreSource` create its own `Dio` instance, or should it share the existing one? The project only has `RawgApiClient` which is Dio-based, but it has RAWG-specific configuration (base URL, API key query param). `SteamStoreSource` needs a separate `Dio` instance with Steam Store base URL and no API key.

---

## Suggested Changes

### Must-Fix (Blockers)

1. **Resolve `steamAppId` data flow**: Specify how `SteamLocalSource` and `SteamStoreSource` determine the Steam app ID for a game. The most pragmatic approach: (a) detect Steam games by `executablePath` containing `/steamapps/common/`, (b) extract `appId` by looking up cached `SteamManifestData` or parsing the manifest file path. Alternatively, modify the Steam import flow to persist `externalId: 'steam:{appId}'` immediately.

2. **Fix DI registration strategy**: Decide whether `SteamLocalSource`, `SteamStoreSource`, and `RawgSource` are factories or singletons. If `MetadataAggregator` holds permanent references, they should be singletons. If the aggregator needs fresh instances per call, use factory functions. Remove the inconsistency.

3. **Add `MetadataRepositoryImpl` to "Files to Modify"**: The repository implementation directly calls `MetadataService` methods. It must be updated to work with the new `MetadataAggregator`-driven flow.

4. **Fix `MetadataAggregator` constructor**: Unify the constructor signature between the class definition and DI registration. Use named parameters for sources.

5. **Add Steam Store API response model**: Add `SteamStoreAppDetail` model (or equivalent) to the "Files to Create" list, or explicitly state that `SteamStoreSource` will parse JSON directly without a model class.

### Should-Fix (Important but not blockers)

6. **Address the sparse metadata issue**: Explicitly document what `SteamLocalSource.fetch()` returns (likely just name + CDN header image). Clarify whether Steam games getting less metadata than non-Steam games is acceptable for Sprint 14, or whether `SteamLocalSource` should return `null` to allow fallback to `SteamStoreSource`.

7. **Specify the HTTP client for `SteamStoreSource`**: State whether it creates its own `Dio` instance, receives one via DI, or uses `dart:io HttpClient`.

8. **Address `MetadataService` method migration**: Specify which `MetadataService` methods remain vs. move to other classes. At minimum:
   - `findMatch()` → becomes `RawgSource`-internal
   - `manualSearch()` → remains on `MetadataService` or moves to `RawgSource`? (Used by `MetadataRepositoryImpl.manualSearch()`)
   - `fetchMetadata()` → becomes aggregator-driven
   - `batchFetchMetadata()` → becomes aggregator-driven
   - `initialize()` → moves API key init to `RawgSource`

9. **Add `metadata_source_priority.dart`** or explicitly state it's folded into `MetadataAggregator`.

### Nice-to-Have (Non-blocking)

10. **Logger vs. print**: Specify what logging approach to use (the project uses `print()` in `RawgApiClient`, no formal logging package).

11. **Testability**: Consider making `SteamDetector._detectLinuxSteam()` and `validateSteamPath()` testable via dependency injection of `FileSystem` or `PlatformInfo` for the Flatpak tests. Currently `SteamDetector` takes `PlatformInfo` but `validateSteamPath()` uses `Directory` directly.

---

## Test Plan Preview

When I evaluate this sprint, I will test:

### Part 1: Flatpak Detection
1. Verify the Flatpak path string appears in `_detectLinuxSteam()`
2. Run existing unit tests for `SteamDetector` to ensure no regressions
3. If testable on Linux, verify Flatpak detection with mock filesystem

### Part 2: Multi-Source Metadata
1. Verify all new files exist in the correct directory structure
2. Verify `MetadataSource` interface has `sourceType`, `canProvide()`, `fetch()`, `displayName`
3. Verify `SteamLocalSource` correctly identifies Steam games by path pattern
4. Verify `SteamStoreSource` calls the correct Steam Store API endpoint and parses the response
5. Verify `RawgSource` wraps existing matching engine
6. Verify `MetadataAggregator` tries sources in priority order and falls through on null
7. Verify DI registrations work without circular dependencies
8. **Critical**: Verify that importing a Steam game stores the `steamAppId` somewhere accessible to later metadata resolution
9. Run all 307+ existing tests without modifications
10. Verify `MetadataRepositoryImpl` correctly delegates to the aggregator
# Sprint Contract: Sprint 5 — External API Integration — Smart Metadata Fetching

## 1. Sprint Goal and Scope

### Goal
Integrate with the RAWG API to automatically fetch and display rich game metadata (cover images, hero images, descriptions, genres, ratings) for all games in the library. Implement smart filename-to-game matching, batch metadata fetching with progress indication, and manual search for correcting mismatches.

### Scope
This sprint transforms the placeholder UI from Sprint 4 into a fully metadata-enriched experience:
- **Before**: Game cards show gradient placeholders; home page shows "No description available"
- **After**: Game cards display real cover images, titles, genres, and ratings; home page shows cinematic hero backgrounds with full descriptions

### Out of Scope
- IGDB API fallback (RAWG only for this sprint)
- Game trailers or video content
- User reviews or community data
- Automatic metadata refresh (manual re-fetch only)
- Metadata for games not in RAWG database (manual entry not supported)

---

## 2. Detailed Deliverables

### 2.1 API Client Layer (`lib/data/datasources/remote/`)

| File | Purpose |
|------|---------|
| `rawg_api_client.dart` | Dio-based HTTP client for RAWG API with rate limiting (max 5 req/sec), retry logic, and error handling |
| `rawg_api_models.dart` | JSON-serializable models for RAWG API responses (GameSearchResult, GameDetailResponse, Genre, Developer, Publisher, Screenshot) |
| `rawg_api_models.g.dart` | Generated JSON serialization code |
| `api_config.dart` | API configuration including base URL, endpoints, and key management |

**Key Requirements:**
- Rate limiting: Maximum 5 requests per second using `dio` interceptors
- Retry logic: 3 retries with exponential backoff for 5xx errors
- Error handling: Distinguish between network errors, rate limits (429), and not found (404)
- Timeout: 10 seconds per request

### 2.2 Filename Matching Service (`lib/core/utils/`)

| File | Purpose |
|------|---------|
| `filename_cleaner.dart` | **Enhanced** — Replace stub implementation with full smart cleaning |

**Cleaning Rules (in order of application):**
1. Remove file extension (.exe)
2. Replace underscores/hyphens with spaces
3. Remove version patterns: `v1.0`, `1.0.0`, `v1.0.0`, `(v1.0)`, `[1.0.0]`
4. Remove common suffixes (case-insensitive): `setup`, `installer`, `uninstall`, `launcher`, `patch`, `update`
5. Remove platform suffixes: `win32`, `win64`, `x64`, `x86`, `windows`, `pc`
6. Remove language suffixes: `en`, `eng`, `english`, `multi`
7. Remove edition suffixes: `goty`, `deluxe`, `premium`, `gold`, `complete`, `ultimate`
8. Remove common prefixes: `the`, `a`, `an` (only if followed by space)
9. Collapse multiple spaces to single space
10. Trim leading/trailing whitespace

**Example Transformations:**
- `The Witcher 3 v1.32 setup.exe` → `Witcher 3`
- `Hollow Knight Win64 Launcher.exe` → `Hollow Knight`
- `Cyberpunk 2077 v2.1 GOTY Win64.exe` → `Cyberpunk 2077`

### 2.3 Metadata Service (`lib/data/services/`)

| File | Purpose |
|------|---------|
| `metadata_service.dart` | Core service orchestrating metadata fetching, matching, and caching |
| `metadata_matching_engine.dart` | Fuzzy matching logic to select best game from search results |

**Matching Engine Algorithm:**
1. Clean filename using `FilenameCleaner.cleanForSearch()`
2. Search RAWG API with cleaned name
3. Score each result using fuzzy string similarity (Levenshtein distance)
4. Select best match if score ≥ 0.7 (70% similarity)
5. Return `MetadataMatchResult` with: `gameId`, `confidence`, `isAutoMatch`, `alternatives`

### 2.4 Metadata Repository (`lib/data/repositories/`)

| File | Purpose |
|------|---------|
| `metadata_repository_impl.dart` | Concrete implementation for metadata CRUD operations |
| `domain/repositories/metadata_repository.dart` | Abstract interface |

**Operations:**
- `Future<GameMetadata?> getMetadataForGame(String gameId)` — from local cache
- `Future<GameMetadata> fetchAndCacheMetadata(String gameId, String gameTitle)` — from API
- `Future<List<GameMetadata>> batchFetchMetadata(List<Game> games)` — with progress callbacks
- `Future<GameMetadata> updateMetadata(String gameId, String newExternalId)` — manual override
- `Future<void> clearMetadata(String gameId)` — delete cached metadata

### 2.5 Metadata BLoC (`lib/presentation/blocs/metadata/`)

| File | Purpose |
|------|---------|
| `metadata_bloc.dart` | State management for metadata fetching |
| `metadata_event.dart` | Events: FetchMetadata, BatchFetch, ManualSearch, SelectMatch |
| `metadata_state.dart` | States: MetadataInitial, MetadataLoading, MetadataLoaded, MetadataMatchRequired, MetadataError |

**State Flow:**
```
FetchMetadata → MetadataLoading → MetadataLoaded (success)
                              → MetadataMatchRequired (low confidence)
                              → MetadataError (API failure)
```

### 2.6 UI Components

| File | Purpose |
|------|---------|
| `lib/presentation/widgets/metadata_loading_card.dart` | Shimmer/skeleton loading card while metadata fetches |
| `lib/presentation/widgets/metadata_error_card.dart` | Card with retry button for failed fetches |
| `lib/presentation/widgets/metadata_search_dialog.dart` | Manual search dialog for selecting correct game |
| `lib/presentation/widgets/cached_game_image.dart` | Wrapper around `cached_network_image` for game covers/hero images |

**Shimmer Specifications:**
- Base color: `AppColors.surface` (#1A1A1E)
- Highlight color: `AppColors.surfaceElevated` (#2A2A30)
- Duration: 1500ms, repeating
- Pattern: Left-to-right sweep

### 2.7 Enhanced Existing Components

| File | Changes |
|------|---------|
| `lib/presentation/widgets/game_card.dart` | Replace placeholder with `CachedGameImage`; show genres as chips; show rating badge |
| `lib/presentation/widgets/home/dynamic_background.dart` | Load hero image from `game.metadata?.heroImageUrl` with crossfade |
| `lib/presentation/widgets/home/game_info_overlay.dart` | Display real description, genres, rating from metadata |
| `lib/presentation/blocs/add_game/add_game_bloc.dart` | Trigger metadata fetch after adding games |
| `lib/app/di.dart` | Register new dependencies (MetadataService, MetadataRepository, RawgApiClient) |

### 2.8 Settings/Configuration

| File | Purpose |
|------|---------|
| `lib/data/services/api_key_service.dart` | Store/retrieve RAWG API key from `shared_preferences` |
| `lib/presentation/widgets/api_key_dialog.dart` | Dialog to input/configure API key |

**API Key Handling:**
- Store in `shared_preferences` under key `rawg_api_key`
- Support environment variable `RAWG_API_KEY` as fallback
- Show dialog on first launch if no key configured
- Allow reconfiguration from settings (Sprint 6)

### 2.9 Database Schema (No Changes Required)

The existing schema from Sprint 3 already supports metadata:
- `game_metadata` table exists
- `game_genres` table exists
- `game_screenshots` table exists

**Required:** Implement full CRUD operations in `DatabaseHelper` for:
- Insert/update metadata with transaction
- Insert genres (batch)
- Insert screenshots (batch)
- Query metadata with joined genres/screenshots

---

## 3. Success Criteria (Testable/Verifiable)

### SC1: RAWG API Client Functionality
**Criterion:** The API client can successfully search for games and retrieve details.
**Verification:**
- Unit test: `rawg_api_client_test.dart` — mock Dio, verify search returns parsed models
- Unit test: Verify rate limiting interceptor delays requests to ≤5/sec
- Unit test: Verify retry logic attempts 3 times on 5xx errors

### SC2: Filename Cleaning Accuracy
**Criterion:** Common filename patterns are correctly cleaned for API search.
**Verification:**
- Unit test: `filename_cleaner_test.dart` — test all 10 cleaning rules
- Test cases must pass:
  - `"The Witcher 3 v1.32 setup.exe"` → `"Witcher 3"`
  - `"Hollow Knight Win64 Launcher.exe"` → `"Hollow Knight"`
  - `"Cyberpunk 2077 v2.1 GOTY Win64.exe"` → `"Cyberpunk 2077"`
  - `"Stardew Valley 1.5.6.exe"` → `"Stardew Valley"`

### SC3: Automatic Metadata Fetch on Game Add
**Criterion:** When a game is added (manual or scan), metadata fetch triggers automatically.
**Verification:**
- Widget test: Add game via dialog → verify `MetadataBloc` receives `FetchMetadata` event
- Integration test: Add game with known title → verify metadata appears in database within 5 seconds

### SC4: Metadata Display on Game Cards
**Criterion:** Game cards show cover image, title, genres, and rating when metadata is available.
**Verification:**
- Widget test: `game_card_test.dart` — verify `CachedNetworkImage` displays when `coverImageUrl` provided
- Widget test: Verify genre chips render (max 3 genres)
- Widget test: Verify rating badge shows when rating > 0
- Manual test: Launch app, verify real game covers appear (not gradients)

### SC5: Metadata Display on Home Page Background
**Criterion:** Home page shows hero image, description, and genres for focused game.
**Verification:**
- Widget test: `dynamic_background_test.dart` — verify hero image loads and crossfades
- Widget test: `game_info_overlay_test.dart` — verify real description displays (not "No description available")
- Manual test: Navigate between cards, verify background changes with metadata

### SC6: Shimmer Loading State
**Criterion:** Cards show shimmer animation while metadata is being fetched.
**Verification:**
- Widget test: `metadata_loading_card_test.dart` — verify `Shimmer` widget is present during loading
- Manual test: Add new game, observe shimmer effect before cover appears

### SC7: Manual Metadata Search
**Criterion:** User can search and select correct game when auto-match fails.
**Verification:**
- Widget test: `metadata_search_dialog_test.dart` — verify search input, results list, selection
- Integration test: Trigger `MetadataMatchRequired` state → verify dialog opens → select match → verify metadata updates

### SC8: Metadata Caching
**Criterion:** Fetched metadata persists in local database and loads on app restart without re-fetching.
**Verification:**
- Unit test: `metadata_repository_impl_test.dart` — verify metadata stored in SQLite
- Integration test: Add game, fetch metadata, kill app, restart → verify metadata displays immediately (no shimmer)

### SC9: Image Caching
**Criterion:** Cover and hero images are cached locally using `cached_network_image`.
**Verification:**
- Widget test: Verify `CachedNetworkImage` widget used in `GameCard` and `DynamicBackground`
- Manual test: Disable internet, verify previously loaded images still display

### SC10: Error Handling with Retry
**Criterion:** API failures show retry option; partial data is still displayed.
**Verification:**
- Widget test: `metadata_error_card_test.dart` — verify error message and retry button
- Unit test: Simulate API failure → verify `MetadataError` state with retry action
- Manual test: Block RAWG API domain, verify error UI with retry button

### SC11: Batch Fetching with Progress
**Criterion:** When multiple games are added, metadata fetches with visible progress.
**Verification:**
- Widget test: Verify progress indicator appears during batch fetch
- Integration test: Scan directory with 5+ games → verify progress updates as each game's metadata is fetched

### SC12: API Key Configuration
**Criterion:** API key can be configured and is used for all requests.
**Verification:**
- Unit test: `api_key_service_test.dart` — verify key stored/retrieved from `shared_preferences`
- Unit test: Verify API client includes key in all request headers/query params
- Manual test: Clear key, restart app → verify prompt for API key

---

## 4. Technical Constraints

### 4.1 Mandatory Dependencies (Already in pubspec.yaml)
| Package | Version | Usage |
|---------|---------|-------|
| `dio` | ^5.8.0 | HTTP client for RAWG API |
| `json_serializable` | ^6.13.1 | API response model serialization |
| `cached_network_image` | ^3.4.0 | Image caching for covers and hero images |
| `shimmer` | ^3.0.0 | Skeleton loading animations |
| `shared_preferences` | ^2.5.5 | API key storage |

### 4.2 Code Generation Requirements
- All API response models MUST use `json_serializable`
- Run `flutter pub run build_runner build` after creating/modifying models
- Generated `.g.dart` files MUST be committed to version control

### 4.3 API Constraints
- **Primary API**: RAWG (rawg.io) — free tier: 20,000 requests/month
- **Rate Limit**: Maximum 5 requests per second (implement in Dio interceptor)
- **Image Handling**: Always use `cached_network_image`, never hot-link
- **Timeout**: 10 seconds per request

### 4.4 Architecture Constraints
- Follow existing Clean Architecture pattern
- All new repositories must have abstract interface in `domain/repositories/`
- All new BLoCs must use existing pattern (events in `_event.dart`, states in `_state.dart`)
- All API calls must go through repository layer, never from BLoC directly

### 4.5 UI Constraints
- Shimmer colors must use design tokens: `AppColors.surface`, `AppColors.surfaceElevated`
- Image placeholders must match existing gradient style when loading
- Error UI must follow existing error state pattern (`ErrorStateWidget`)

---

## 5. Dependencies and Assumptions

### 5.1 Dependencies on Previous Sprints
| Sprint | Dependency | Status |
|--------|------------|--------|
| Sprint 4 | Home page with dynamic background | ✅ PASSED (8.0/10) |
| Sprint 4 | GameCard component with focus animations | ✅ PASSED |
| Sprint 4 | GameInfoOverlay component | ✅ PASSED |
| Sprint 3 | Database schema (games, metadata tables) | ✅ PASSED |
| Sprint 3 | Game repository implementation | ✅ PASSED |
| Sprint 2 | Focus management system | ✅ PASSED |
| Sprint 1 | Theme system with design tokens | ✅ PASSED |

### 5.2 External Dependencies
| Dependency | Requirement |
|------------|-------------|
| RAWG API Key | User must provide their own free API key from rawg.io |
| Internet Connection | Required for initial metadata fetch; cached data works offline |
| Windows Platform | Target platform for testing (app runs on Windows) |

### 5.3 Assumptions
1. **RAWG API Availability**: The RAWG API is available and responsive during development
2. **Game Coverage**: Most popular PC games are in the RAWG database
3. **Filename Quality**: Executable filenames contain recognizable game names (not random strings)
4. **Image URLs**: RAWG-provided image URLs are valid and accessible
5. **Single API Source**: RAWG is sufficient; IGDB fallback not needed for v1

### 5.4 Risk Mitigation
| Risk | Mitigation |
|------|------------|
| RAWG API rate limits | Implement strict rate limiting (5 req/sec) and caching |
| API key not configured | Prompt user on first launch; allow manual entry |
| Poor filename matches | Implement manual search dialog for user correction |
| Large image downloads | Use `cached_network_image` with max age and disk limits |
| Network failures | Implement retry logic; show cached data if available |

---

## 6. Testing Requirements

### 6.1 Unit Tests (Minimum 15)
- `test/data/datasources/remote/rawg_api_client_test.dart` — API client, rate limiting, retry logic
- `test/core/utils/filename_cleaner_test.dart` — All cleaning rules
- `test/data/services/metadata_service_test.dart` — Matching engine, batch processing
- `test/data/repositories/metadata_repository_impl_test.dart` — CRUD operations, caching
- `test/data/services/api_key_service_test.dart` — Key storage/retrieval

### 6.2 Widget Tests (Minimum 10)
- `test/presentation/widgets/metadata_loading_card_test.dart` — Shimmer animation
- `test/presentation/widgets/metadata_error_card_test.dart` — Error UI, retry action
- `test/presentation/widgets/metadata_search_dialog_test.dart` — Search, selection
- `test/presentation/widgets/cached_game_image_test.dart` — Image loading, placeholder, error
- `test/presentation/blocs/metadata/metadata_bloc_test.dart` — State transitions

### 6.3 Integration Tests (Minimum 2)
- End-to-end: Add game → metadata fetch → display on card and home page
- End-to-end: Manual search flow for incorrect auto-match

### 6.4 Manual Testing Checklist
- [ ] Add 5 games via directory scan, verify all get metadata
- [ ] Verify shimmer appears during fetch, then real covers appear
- [ ] Navigate home page, verify hero backgrounds change
- [ ] Disable internet, verify cached images still display
- [ ] Test manual search: add game with ambiguous name, correct the match
- [ ] Configure API key, verify it's saved and used

---

## 7. Definition of Done

This sprint is complete when:

1. ✅ All deliverables in Section 2 are implemented
2. ✅ All success criteria in Section 3 are verified (tests passing)
3. ✅ Minimum test coverage: 25 new tests (15 unit + 10 widget)
4. ✅ `flutter analyze` shows zero errors
5. ✅ `flutter test` shows all tests passing
6. ✅ Manual testing checklist completed
7. ✅ Self-evaluation document written (`self-eval.md`)
8. ✅ Handoff document written (`handoff.md`)

---

## 8. Post-Sprint State

After Sprint 5, the application will have:
- Real game metadata displayed on all cards and home page
- Smart filename matching with manual correction capability
- Fully functional image caching for smooth browsing
- Robust error handling for network issues
- A complete, visually rich game library experience

This sets up Sprint 6 for polish: responsive refinements, i18n completion, sound effects, and favorites system.

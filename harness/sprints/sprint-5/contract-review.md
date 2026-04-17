# Contract Review: Sprint 5

## Assessment: APPROVED_WITH_CONDITIONS

The contract is comprehensive and well-structured. It covers all major deliverables from the spec and builds properly on Sprint 4's foundation. However, there are several gaps and ambiguities that should be addressed before or during implementation to avoid rework. I'm approving with conditions — the items below should be resolved during implementation.

---

## Scope Coverage

### Fully Covered Deliverables (from spec)

| Spec Deliverable | Contract Coverage | Notes |
|---|---|---|
| RAWG API client with rate limiting & error handling | ✅ Section 2.1 | Thorough — rate limiting, retry, timeout, error types all specified |
| API key configuration | ✅ Section 2.8 | Stored in `shared_preferences`, env var fallback |
| Smart filename matching | ✅ Section 2.2 | Excellent detail — 10 cleaning rules with examples |
| Automatic metadata fetch on game add | ✅ Section 2.7 & SC3 | AddGameBloc triggers MetadataBloc |
| Metadata on game cards | ✅ Section 2.7 & SC4 | Cover image, genres, rating |
| Metadata on home page background | ✅ Section 2.7 & SC5 | Hero image, description, genres |
| Manual metadata search | ✅ Section 2.6 & SC7 | Search dialog for correcting mismatches |
| Metadata caching | ✅ Section 2.4 & SC8 | Local database persistence |
| Shimmer loading state | ✅ Section 2.6 & SC6 | Detailed shimmer specs with colors and duration |
| Image caching | ✅ Section 2.6 & SC9 | `cached_network_image` |
| Error handling with retry | ✅ Section 2.6 & SC10 | Error card with retry button |
| Batch fetching with progress | ✅ SC11 | Progress indicator during batch fetch |

### Partially Covered / Gaps

1. **Screenshots display (Minor Gap)**: The spec says metadata display on the home page should include "screenshots" (spec section 5: "cover image, hero image, description, and screenshots"). The contract's `GameDetailResponse` model includes screenshots, and the `GameMetadata` entity has a `screenshots` field, but **no UI component is specified for displaying screenshots**. The `game_info_overlay.dart` enhancement only mentions "real description, genres, rating" — screenshots are missing. This should either be explicitly scoped out or a minimal display mechanism (e.g., a horizontal scrollable thumbnail strip) should be added.

2. **Manual re-fetch flow (Gap)**: The contract explicitly scopes out "Automatic metadata refresh" and says "manual re-fetch only," but **no UI trigger for manual re-fetch is specified**. The `MetadataRepository` has an `updateMetadata()` method, but there's no BLoC event or UI element (e.g., a "Refresh Metadata" button on a game card or detail view) to trigger it. Without this, users who get a wrong match can correct it via the search dialog, but users whose metadata fails to load have no way to retry from the UI after dismissing the error card. **Recommendation**: Add a "Retry" or "Re-fetch Metadata" action to the game card context menu or long-press menu, and add a `RefreshMetadata` event to the `MetadataBloc`.

3. **API key dialog UX edge case (Ambiguity)**: Section 2.8 says "Show dialog on first launch if no key configured" but doesn't specify what happens if the user dismisses the dialog without entering a key. Does the app show the dialog again on next launch? Does it work in a degraded mode (no metadata, gradient placeholders)? Does it block the app entirely? **Recommendation**: The dialog should be dismissible, and the app should function in a degraded mode (showing gradient placeholders, no metadata). A persistent notification or settings indicator should remind the user to configure the API key. The dialog should re-appear on next launch until a key is configured.

4. **Batch fetching BLoC architecture (Ambiguity)**: The `MetadataBloc` state flow shows a single-game flow: `FetchMetadata → MetadataLoading → MetadataLoaded`. But batch fetching (SC11) requires managing progress across multiple games. Is there a single `MetadataBloc` instance managing all games' metadata, or does each game have its own? The contract lists `BatchFetch` as an event, but the state model doesn't include a batch progress state (e.g., `MetadataBatchProgress(current: 3, total: 10)`). **Recommendation**: Add a `MetadataBatchLoading` state with progress information, or clarify that batch fetching dispatches individual `FetchMetadata` events per game and the progress is tracked at the UI layer.

5. **Database CRUD operations (Contradiction)**: Section 2.9 says "No Changes Required" to the schema, then immediately lists "Required: Implement full CRUD operations in DatabaseHelper." This is contradictory — either the schema needs changes or it doesn't. What's likely meant is that the **schema (table definitions) doesn't change**, but the **CRUD operations for metadata** need to be **implemented** (they may be stubs or missing currently). **Recommendation**: Clarify that the schema is unchanged but `DatabaseHelper` needs new methods for metadata CRUD (insert/update with transaction, batch genre insert, batch screenshot insert, query with joins).

6. **`MetadataMatchResult` model location (Missing)**: Section 2.3 mentions `MetadataMatchResult` with fields `gameId`, `confidence`, `isAutoMatch`, `alternatives`, but this model isn't listed in any deliverables file table. **Recommendation**: Add it to the deliverables — likely in `lib/data/services/metadata_matching_engine.dart` or as a separate model file.

---

## Success Criteria Review

### SC1: RAWG API Client Functionality — ✅ Adequate
Well-specified with unit tests for rate limiting, retry logic, and response parsing. The 5 req/sec rate limit and 3-retry exponential backoff are clear constraints.

### SC2: Filename Cleaning Accuracy — ✅ Excellent
The 10 cleaning rules with specific example transformations are unambiguous and directly testable. This is one of the strongest success criteria in the contract.

### SC3: Automatic Metadata Fetch on Game Add — ⚠️ Needs Clarification
The criterion says "verify `MetadataBloc` receives `FetchMetadata` event" but doesn't specify the integration mechanism. How does `AddGameBloc` communicate with `MetadataBloc`? Direct event dispatch? Through a repository? The contract should specify the integration pattern.

### SC4: Metadata Display on Game Cards — ✅ Adequate
Clear widget tests specified. The "max 3 genres" as chips is a good detail. Rating badge visibility condition (rating > 0) is testable.

### SC5: Metadata Display on Home Page Background — ✅ Adequate
Good coverage of hero image crossfade and description display. Missing: screenshots display (see gap above).

### SC6: Shimmer Loading State — ✅ Adequate
Specific shimmer specs (colors, duration, pattern) make this very testable.

### SC7: Manual Metadata Search — ✅ Adequate
Widget test and integration test specified. The `MetadataMatchRequired` state triggering the dialog is clear.

### SC8: Metadata Caching — ✅ Adequate
Integration test with app restart is a strong verification method.

### SC9: Image Caching — ✅ Adequate
Using `cached_network_image` is the right approach. Offline verification is a good manual test.

### SC10: Error Handling with Retry — ✅ Adequate
Error card with retry button is well-specified. The "partial data is still displayed" aspect is important and testable.

### SC11: Batch Fetching with Progress — ⚠️ Needs Clarification
"Progress indicator" is vague. What kind of indicator? A progress bar? A counter ("3/10 games")? A per-game status list? The BLoC state model doesn't include a batch progress state. **Recommendation**: Specify the progress UI (e.g., "A progress bar showing X/N games processed" or "A status indicator showing 'Fetching metadata for Game X...'") and add a `MetadataBatchProgress` state.

### SC12: API Key Configuration — ✅ Adequate
Unit tests for storage/retrieval and inclusion in requests are clear. The manual test (clear key, restart, verify prompt) is good.

---

## Technical Constraints Review

### Dependencies — ✅ Appropriate
All listed dependencies (`dio`, `json_serializable`, `cached_network_image`, `shimmer`, `shared_preferences`) are already in `pubspec.yaml` and match the spec's requirements.

### Code Generation — ✅ Correct
`json_serializable` with `build_runner` is the right approach for API models. Committing `.g.dart` files is standard practice.

### API Constraints — ✅ Well-Specified
Rate limiting (5 req/sec), timeout (10s), and free tier limits (20,000/month) are all documented.

### Architecture Constraints — ✅ Consistent
Clean Architecture pattern, abstract interfaces in `domain/repositories/`, BLoC pattern — all consistent with existing codebase.

### UI Constraints — ✅ Good
Using design tokens (`AppColors.surface`, `AppColors.surfaceElevated`) for shimmer colors ensures visual consistency.

---

## Building on Sprint 4 Foundation

### What Exists and Needs Enhancement

| Existing Component | Sprint 5 Enhancement | Assessment |
|---|---|---|
| `FilenameCleaner` (stub) | Full implementation with 10 rules | ✅ Correctly identified |
| `GameMetadata` entity | Already has all needed fields | ✅ No changes needed |
| Database schema (`game_metadata`, `game_genres`, `game_screenshots` tables) | CRUD operations need implementation | ✅ Correctly identified |
| `GameCard` widget | Replace placeholder with `CachedGameImage`, add genres/rating | ✅ Clear |
| `DynamicBackground` | Load hero image from metadata | ✅ Clear |
| `GameInfoOverlay` | Display real description, genres, rating | ✅ Clear (but missing screenshots) |
| `AddGameBloc` | Trigger metadata fetch after adding games | ✅ Clear (but integration mechanism unspecified) |
| `di.dart` | Register new dependencies | ✅ Clear |

### Sprint 4 Evaluation Notes

Sprint 4 passed at 8.0/10. Key issues that were fixed:
- Reactive data updates are now wired up (`notifyGamesChanged()`)
- HomeBloc lifecycle is properly managed via BlocProvider
- All rows display (2-row limit removed)
- i18n strings are properly extracted

One code quality note from Sprint 4 evaluation: the `as HomeRepositoryImpl` cast in DI is a code smell. Sprint 5 should avoid similar patterns — if `MetadataService` needs to be cast to a concrete type, consider adding the method to the interface instead.

---

## Suggested Changes

### Must Address Before Implementation

1. **Add `MetadataBatchProgress` state**: The `MetadataBloc` needs a state for batch fetching progress. Add `MetadataBatchLoading({int current, int total, String currentGameName})` to the state model. This is essential for SC11 to be testable.

2. **Specify AddGameBloc → MetadataBloc integration**: Document how `AddGameBloc` triggers metadata fetching. Options:
   - (A) `AddGameBloc` dispatches `FetchMetadata` events to `MetadataBloc` via `context.read<MetadataBloc>().add(...)`
   - (B) `AddGameBloc` calls `MetadataService.fetchAndCacheMetadata()` directly
   - (C) A separate orchestrator handles the flow
   **Recommendation**: Option A is most consistent with the BLoC pattern. Specify this explicitly.

3. **Clarify database CRUD scope**: Explicitly state which `DatabaseHelper` methods need to be added (e.g., `insertMetadata()`, `getMetadataForGame()`, `insertGenres()`, `insertScreenshots()`, `deleteMetadata()`).

4. **Add `MetadataMatchResult` to deliverables**: List it explicitly in the file table, likely in `lib/data/services/metadata_matching_engine.dart` or `lib/data/models/metadata_match_result.dart`.

### Should Address During Implementation

5. **Add screenshots display to `GameInfoOverlay`**: Even a minimal horizontal scrollable thumbnail strip would satisfy the spec. If intentionally deferred, explicitly scope it out in the "Out of Scope" section.

6. **Add manual re-fetch UI trigger**: Add a `RefreshMetadata` event to `MetadataBloc` and a UI affordance (long-press menu on game card, or a button in the error card) to trigger re-fetching.

7. **Specify API key dialog dismissal behavior**: Document that the dialog is dismissible and the app works in degraded mode without an API key.

8. **Specify rate limiting queue behavior**: When the 5 req/sec limit is hit, should requests be queued and delayed, or should they fail with a 429-like error? **Recommendation**: Queue and delay (sliding window or token bucket) — this is more user-friendly than failing.

---

## Test Plan Preview

When I evaluate this sprint, I will test:

1. **Filename cleaning**: Verify all 10 rules with the example transformations and edge cases
2. **API client**: Verify rate limiting, retry logic, and error handling with mocked Dio
3. **Auto metadata fetch**: Add a game and verify metadata appears on the card and home page
4. **Shimmer state**: Add a game and observe shimmer before metadata loads
5. **Manual search**: Trigger a low-confidence match and verify the search dialog appears
6. **Error handling**: Simulate API failure and verify error card with retry
7. **Caching**: Add game, fetch metadata, restart app, verify metadata loads from cache
8. **Image caching**: Load images, disable internet, verify images still display
9. **Batch progress**: Add 5+ games via scan and verify progress indication
10. **API key**: Clear key, restart, verify prompt appears
11. **Home page integration**: Navigate between games and verify hero backgrounds change with metadata
12. **Edge cases**: Empty search results, network timeout, rate limit response, malformed API responses

---

## Summary

The Sprint 5 contract is well-structured and covers the core spec requirements. The filename cleaning rules are exceptionally well-specified. The main gaps are:
- Missing batch progress state in BLoC
- Unspecified AddGameBloc → MetadataBloc integration mechanism
- Missing screenshots display UI
- No manual re-fetch trigger
- Ambiguous API key dialog dismissal behavior
- Contradictory database section

These are addressable during implementation without requiring a full contract revision. I'm approving with conditions that items 1-4 under "Must Address" are resolved during implementation.
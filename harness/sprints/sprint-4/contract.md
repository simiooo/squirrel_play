# Sprint Contract: Sprint 4 — Directory Metadata Chain of Responsibility

## Scope

Implement the Chain of Responsibility pattern for directory-level metadata parsing when games are manually added or discovered via directory scanning. When a game executable is discovered, the system inspects sibling files in the same directory to determine the best initial game title, with Steam directory detection as the first priority and filename-based title generation as the fallback.

This sprint delivers:
- `GameMetadataHandler` abstract base class
- `DirectoryContext` data holder with mutable parsed metadata fields
- `SteamDirectoryHandler`: detects `steamapps/common/` paths and parses `appmanifest_*.acf` for official title + appId
- `DefaultMetadataHandler`: generates a title from executable filename using existing `FilenameCleaner`
- `DirectoryMetadataChain` builder wiring handlers in order
- Integration into `AddGameBloc` for both manual add and scan confirmation flows
- Extension of `DiscoveredExecutableModel` with optional `suggestedTitle`
- Unit tests for all handlers, chain behavior, and AddGameBloc integration

## Implementation Plan

### 1. Chain of Responsibility Core (New Files)

Create `lib/data/services/directory_metadata_chain/` directory with:

**`game_metadata_handler.dart`**
- Abstract base class `GameMetadataHandler`
- `GameMetadataHandler? _nextHandler` private field
- `void setNext(GameMetadataHandler handler)` method
- `Future<void> handle(DirectoryContext context)` method with default logic: `if (_nextHandler != null) await _nextHandler!.handle(context)`

**`directory_context.dart`**
- Class `DirectoryContext` with:
  - `final String executablePath`
  - `final String fileName`
  - `final String directoryPath`
  - `String? title` (mutable, set by handlers)
  - `String? steamAppId` (mutable, set by SteamDirectoryHandler)
- Constructor takes all `final` fields; mutable fields start as `null`

**`steam_directory_handler.dart`**
- Extends `GameMetadataHandler`
- Depends on `SteamManifestParser` (injected via constructor)
- In `handle(DirectoryContext context)`:
  1. Check if `context.directoryPath` contains `steamapps/common/` (case-insensitive, normalize separators)
  2. If yes, determine the parent library path (path before `steamapps`)
  3. Use `SteamManifestParser.scanLibrary(libraryPath)` to get all manifests
  4. Match the executable path against `manifest.possibleExecutablePaths`
  5. On match: set `context.title = manifest.name` and `context.steamAppId = manifest.appId`
  6. If no match or not a Steam path: call `super.handle(context)` to pass to next handler

**`default_metadata_handler.dart`**
- Extends `GameMetadataHandler`
- In `handle(DirectoryContext context)`:
  1. Set `context.title = FilenameCleaner.cleanForDisplay(context.fileName)`
  2. No call to `super.handle(context)` — this is the terminal handler

**`directory_metadata_chain.dart`**
- Static builder class with a single factory method:
  - `static GameMetadataHandler build({required SteamManifestParser manifestParser})`
  - Wires: `SteamDirectoryHandler` → `setNext` → `DefaultMetadataHandler`
  - Returns the head of the chain (`SteamDirectoryHandler`)

### 2. Model Extension (Modified File)

**`lib/data/models/discovered_executable_model.dart`**
- Add optional `String? suggestedTitle` field
- Add to constructor with default `null`
- Add to `copyWith` method
- Update `toString()`, `==`, and `hashCode` to include `suggestedTitle` (or document why `hashCode`/`==` remain path-based only)

### 3. BLoC Integration (Modified File)

**`lib/presentation/blocs/add_game/add_game_bloc.dart`**
- Add `GameMetadataHandler _metadataHandler` as a constructor parameter with a default (from DI or a factory)
- In `_onFileSelected(FileSelected event)`:
  - After emitting `ManualAddForm` with `executablePath` and `fileName`, run the chain:
  - `final context = DirectoryContext(executablePath: event.path, fileName: event.fileName, directoryPath: event.path.substring(0, event.path.lastIndexOf(platformSeparator)))`
  - `await _metadataHandler.handle(context)`
  - Use `context.title` as the initial `name` instead of `event.fileName.replaceAll('.exe', '')`
- In `_onConfirmManualAdd(ConfirmManualAdd event)`:
  - No change to final `Game.title` — it uses `current.name.trim()` as before (the chain only sets the initial suggestion)
- In `_onConfirmScanSelection(ConfirmScanSelection event)`:
  - For each selected executable, before creating `Game`, run the chain to get a suggested title
  - Use `FilenameCleaner.cleanForDisplay(executable.fileName)` as fallback if chain returns null
  - Set `executable.suggestedTitle` with the result
  - Use `executable.suggestedTitle ?? executable.fileName.replaceAll('.exe', '')` as the `Game.title`

### 4. Dependency Injection (Modified File)

**`lib/app/di.dart`**
- Register `DirectoryMetadataChain.build` as a factory or singleton that receives `SteamManifestParser`
- Inject the chain into `AddGameBloc` factory registration

### 5. Tests (New Files)

**`test/data/services/directory_metadata_chain/directory_context_test.dart`**
- Tests construction and mutable field behavior

**`test/data/services/directory_metadata_chain/steam_directory_handler_test.dart`**
- Mock `SteamManifestParser` using `mocktail`
- Tests:
  - When path is in `steamapps/common/` and manifest matches executable → sets title and appId, does NOT call next
  - When path is in `steamapps/common/` but no manifest matches → calls next handler
  - When path is NOT in `steamapps/common/` → calls next handler immediately
  - Register `registerFallbackValue` for any custom types used in mocks

**`test/data/services/directory_metadata_chain/default_metadata_handler_test.dart`**
- Tests:
  - Sets `context.title` using `FilenameCleaner.cleanForDisplay`
  - Does not call next handler

**`test/data/services/directory_metadata_chain/directory_metadata_chain_test.dart`**
- Tests:
  - `build()` returns a `GameMetadataHandler` (type check)
  - Chain order: Steam handler gets first shot, default is terminal
  - End-to-end: Steam path with mock parser → Steam title; non-Steam path → cleaned filename title

**`test/presentation/blocs/add_game/add_game_bloc_test.dart`** (new file)
- Mock `GameRepository`, `HomeRepositoryImpl`, `SteamManifestParser` (or the chain)
- Tests:
  - `FileSelected` event triggers chain and uses suggested title in emitted state
  - `ConfirmScanSelection` uses `suggestedTitle` from chain for `Game.title`
  - `ConfirmManualAdd` uses the name from state (which was set by chain in `FileSelected`)

## Success Criteria

1. **Chain Architecture Exists**: `GameMetadataHandler`, `DirectoryContext`, `SteamDirectoryHandler`, `DefaultMetadataHandler`, and `DirectoryMetadataChain` all exist in `lib/data/services/directory_metadata_chain/` and `flutter analyze` reports zero errors.
   - *Verification*: Run `flutter analyze` and inspect file list.

2. **Steam Directory Detection Works**: `SteamDirectoryHandler` correctly identifies executables under a `steamapps/common/` path, calls `SteamManifestParser.scanLibrary()`, matches the executable to a manifest, and populates `DirectoryContext.title` with the manifest `name` and `steamAppId` with the manifest `appId`.
   - *Verification*: Unit test `steam_directory_handler_test.dart` passes; mock parser returning a manifest with matching `possibleExecutablePaths` results in title being set.

3. **Default Fallback Works**: `DefaultMetadataHandler` always sets `context.title = FilenameCleaner.cleanForDisplay(context.fileName)` and never delegates further.
   - *Verification*: Unit test `default_metadata_handler_test.dart` passes.

4. **Chain Ordering Is Correct**: `DirectoryMetadataChain.build()` wires `SteamDirectoryHandler → DefaultMetadataHandler`. When the Steam handler cannot resolve a title, the default handler is reached and sets a cleaned filename title.
   - *Verification*: Unit test `directory_metadata_chain_test.dart` passes with both Steam-match and non-Steam-match scenarios.

5. **`DiscoveredExecutableModel` Has `suggestedTitle`**: The model includes the new optional field, updated `copyWith`, and `toString()`.
   - *Verification*: Inspect `discovered_executable_model.dart`; run `flutter analyze`.

6. **`AddGameBloc` Integrates the Chain**:
   - On `FileSelected`, the chain is invoked and the resulting `title` is used as the initial `name` in `ManualAddForm` state.
   - On `ConfirmScanSelection`, each selected executable gets its `suggestedTitle` populated via the chain, and `Game.title` uses the suggested title.
   - *Verification*: Unit tests in `add_game_bloc_test.dart` pass; `flutter test` passes overall.

7. **DI Registration**: `di.dart` registers the metadata chain and injects it into `AddGameBloc`.
   - *Verification*: Inspect `di.dart`; app builds and runs.

8. **All Existing Tests Pass**: `flutter test` passes with no regressions (370+ tests).
   - *Verification*: Run `flutter test` and confirm 100% pass rate.

## Out of Scope for This Sprint

- **RAWG fallback in chain**: The chain only handles Steam directory detection and default filename cleaning. RAWG-based title suggestion is out of scope (handled by the metadata aggregation system in Sprints 2–3).
- **Persistent storage of `suggestedTitle`**: `suggestedTitle` is a runtime field on `DiscoveredExecutableModel`; it is not persisted to the database.
- **UI changes to display suggested titles**: The scan results UI may optionally show `suggestedTitle`, but explicit UI redesign is out of scope.
- **Title confidence scoring**: No additional scoring beyond what `FilenameCleaner` already provides.
- **Background/scheduled metadata refresh**: Not part of this sprint.

## Dependencies / Prerequisites

- **Sprint 1** (completed): `GameMetadata` entity and model have `title` field available. Database schema supports metadata.
- **Sprint 2** (completed): `SteamMetadataAdapter` and `SteamManifestParser` exist and are registered in DI.
- **Sprint 3** (completed): RAWG batch/paginated search is available; not directly used here but the metadata pipeline is complete.
- **Existing code**:
  - `SteamManifestParser` with `scanLibrary()` and `SteamManifestData` (with `name`, `appId`, `possibleExecutablePaths`)
  - `FilenameCleaner.cleanForDisplay()`
  - `AddGameBloc` with `_onFileSelected`, `_onConfirmManualAdd`, `_onConfirmScanSelection`
  - `DiscoveredExecutableModel`
  - `get_it` DI setup in `lib/app/di.dart`

## Files to Modify

| File | Change |
|------|--------|
| `lib/data/models/discovered_executable_model.dart` | Add `suggestedTitle` field, update constructor, `copyWith`, `toString` |
| `lib/presentation/blocs/add_game/add_game_bloc.dart` | Accept `GameMetadataHandler` in constructor; invoke chain in `_onFileSelected` and `_onConfirmScanSelection` |
| `lib/app/di.dart` | Register `DirectoryMetadataChain.build` result; inject into `AddGameBloc` factory |

## Files to Create

| File | Purpose |
|------|---------|
| `lib/data/services/directory_metadata_chain/game_metadata_handler.dart` | Abstract base class |
| `lib/data/services/directory_metadata_chain/directory_context.dart` | Data holder for chain processing |
| `lib/data/services/directory_metadata_chain/steam_directory_handler.dart` | Steam path detection + ACF parsing |
| `lib/data/services/directory_metadata_chain/default_metadata_handler.dart` | Filename-based title generation |
| `lib/data/services/directory_metadata_chain/directory_metadata_chain.dart` | Builder class wiring handlers |
| `test/data/services/directory_metadata_chain/directory_context_test.dart` | Unit tests for context |
| `test/data/services/directory_metadata_chain/steam_directory_handler_test.dart` | Unit tests for Steam handler |
| `test/data/services/directory_metadata_chain/default_metadata_handler_test.dart` | Unit tests for default handler |
| `test/data/services/directory_metadata_chain/directory_metadata_chain_test.dart` | Unit tests for chain builder + end-to-end |
| `test/presentation/blocs/add_game/add_game_bloc_test.dart` | Unit tests for AddGameBloc chain integration |

# Sprint Contract: Foundation — Database, Entity & Process Tracking

## Scope

Extend the data layer to support per-game launch arguments and rebuild the `GameLauncher` service from a fire-and-forget model to full process lifecycle tracking (launch, monitor, stop). All existing tests must continue to pass, and new tests must verify the process tracking behavior.

This sprint delivers the foundational data and service changes that Sprint 2 (Game Detail Page UI) and Sprint 3 (Detail Page Actions) depend on.

---

## Implementation Plan

### 1. Database Schema v4 — Launch Arguments Column

**Files modified:**
- `lib/data/datasources/local/database_constants.dart`
- `lib/data/datasources/local/database_helper.dart`

**Changes:**
- Add `colLaunchArguments = 'launch_arguments'` to `DatabaseConstants` column names.
- Update `databaseVersion` from `3` to `4`.
- Update `createGamesTable` SQL to include `launch_arguments TEXT` column.
- Add migration block in `database_helper.dart` `onUpgrade` for `oldVersion < 4`:
  ```sql
  ALTER TABLE games ADD COLUMN launch_arguments TEXT
  ```

### 2. `Game` Entity — `launchArguments` Field

**File modified:**
- `lib/domain/entities/game.dart`

**Changes:**
- Add `final String? launchArguments` field.
- Update constructor with `this.launchArguments` (default `null`).
- Update `copyWith` with `String? launchArguments` parameter.
- Update `props` list to include `launchArguments`.

### 3. `GameModel` — `launchArguments` Field

**File modified:**
- `lib/data/models/game_model.dart`

**Changes:**
- Add `final String? launchArguments` field with `@JsonKey(name: DatabaseConstants.colLaunchArguments)`.
- Update constructor with `this.launchArguments` (default `null`).
- Update `fromMap` to read `launch_arguments` from the database map.
- Update `toMap` to write `launch_arguments` to the database map.
- Update `copyWith` with `String? launchArguments` parameter.

**Generated code:**
- `lib/data/models/game_model.g.dart` must be regenerated via `flutter pub run build_runner build --delete-conflicting-outputs`.

### 4. `GameRepository` & `GameRepositoryImpl` — Updated Mappings

**Files modified:**
- `lib/domain/repositories/game_repository.dart` *(no signature changes needed — the interface already accepts/returns `Game` entities, which now carry `launchArguments`)*
- `lib/data/repositories/game_repository_impl.dart`

**Changes:**
- Update `_mapToEntity` to pass `launchArguments: model.launchArguments`.
- Update `_mapToModel` to pass `launchArguments: entity.launchArguments`.

### 5. `GameLauncher` Interface Redesign

**File modified:**
- `lib/domain/services/game_launcher.dart`

**Changes:**
Keep existing members and add:
- `Future<void> stopGame(String gameId)` — forcefully terminates a running game process.
- `bool isGameRunning(String gameId)` — synchronous check for whether a game is currently tracked.
- `Stream<Map<String, RunningGameInfo>> get runningGamesStream` — broadcast stream of all running games.
- New class `RunningGameInfo`:
  - `final String gameId`
  - `final String title`
  - `final DateTime startTime`
  - `final int? pid` *(optional, if available from `Process`)*

The existing `LaunchResult`, `LaunchStatus` enum, and `launchStatusStream` are preserved unchanged to minimize blast radius in `HomeBloc` and other consumers.

### 6. `GameLauncherService` Reimplementation

**File modified:**
- `lib/data/services/game_launcher_service.dart`

**Changes:**
- Replace `ProcessStartMode.detached` with non-detached `Process.start` so the `Process` object is retained.
- Add `final Map<String, Process> _runningProcesses` to track active processes by game ID.
- Add `final StreamController<Map<String, RunningGameInfo>> _runningGamesController` (broadcast) for `runningGamesStream`.
- Add `Map<String, RunningGameInfo> _runningGames` to hold the current snapshot.
- `launchGame(Game game)`:
  1. Parse `game.launchArguments` (if non-null) using `shellSplit` or simple space-splitting into a `List<String>`.
  2. Call `Process.start(game.executablePath, args, workingDirectory: ..., mode: ProcessStartMode.normal)`.
  3. On success, store the `Process` in `_runningProcesses[game.id]`.
  4. Create a `RunningGameInfo` and add it to `_runningGames`.
  5. Emit the updated map on `_runningGamesController`.
  6. Attach an `process.exitCode.then(...)` listener to clean up the map and emit on exit.
  7. Preserve existing `launchStatusStream` behavior (idle → launching → idle/error).
- `stopGame(String gameId)`:
  1. Look up the process in `_runningProcesses`.
  2. Call `process.kill()`.
  3. Remove from `_runningProcesses` and `_runningGames`.
  4. Emit updated map on `_runningGamesController`.
- `isGameRunning(String gameId)`:
  1. Return `_runningProcesses.containsKey(gameId)`.
- `dispose()`:
  1. Close `_runningGamesController`.
  2. Preserve existing `_statusController.close()` and `_resetTimer?.cancel()`.

### 7. Dependency Injection

**File modified:**
- `lib/app/di.dart`

**Changes:**
- No constructor signature changes expected for `GameLauncherService`, so registration stays the same.
- Verify `getIt.registerSingleton<GameLauncher>(getIt<GameLauncherService>())` still compiles after interface changes.

### 8. BLoC Compatibility

**Files that create `Game` objects (no changes required if `launchArguments` defaults to `null`, but verify compilation):**
- `lib/presentation/blocs/add_game/add_game_bloc.dart`
- `lib/presentation/blocs/quick_scan/quick_scan_bloc.dart`
- `lib/presentation/blocs/steam_scanner/steam_scanner_bloc.dart`

These blocs construct `Game` instances without `launchArguments`; since the field is nullable with a default of `null`, they compile unchanged.

### 9. Tests

**Files modified:**
- `test/data/services/game_launcher_service_test.dart`
- `test/data/repositories/game_repository_impl_test.dart`
- `test/presentation/blocs/home/home_bloc_test.dart`

**New tests to add in `game_launcher_service_test.dart`:**
- `isGameRunning returns false when no game is running`
- `isGameRunning returns true after successful launch`
- `stopGame terminates a running process`
- `runningGamesStream emits empty map initially`
- `runningGamesStream emits game info after launch`
- `runningGamesStream emits empty map after process exits naturally`
- `launchGame passes parsed arguments to Process.start`
- `launchGame with null launchArguments passes empty args`

**Updates to `game_repository_impl_test.dart`:**
- Update the inline `CREATE TABLE games` schema in the test setup to include `launch_arguments TEXT`.
- Update all `Game(...)` constructor calls in tests to include `launchArguments: null` where needed (or rely on default).
- Add a CRUD test that round-trips a game with `launchArguments: '-windowed --fullscreen'` and verifies it is persisted and retrieved correctly.

**Updates to `home_bloc_test.dart`:**
- Add mock stubs for the new `GameLauncher` members:
  ```dart
  when(() => gameLauncher.isGameRunning(any())).thenReturn(false);
  when(() => gameLauncher.runningGamesStream).thenAnswer((_) => Stream.value({}));
  ```
- The existing `LaunchStatus` stream subscription behavior is preserved.

---

## Success Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Database schema is version 4 with `launch_arguments` column | Inspect `database_constants.dart`: `databaseVersion == 4`, `createGamesTable` contains `launch_arguments TEXT`. Inspect `database_helper.dart`: `onUpgrade` handles `oldVersion < 4`. |
| 2 | `Game` entity includes `launchArguments` | `lib/domain/entities/game.dart` has nullable `launchArguments` field, updated `copyWith`, updated `props`. |
| 3 | `GameModel` includes `launchArguments` with correct JSON/db mapping | `lib/data/models/game_model.dart` has field, `fromMap`/`toMap` handle it, `game_model.g.dart` regenerated. |
| 4 | `GameRepositoryImpl` round-trips `launchArguments` | Repository test creates game with arguments, persists, fetches, and asserts `launchArguments` matches. |
| 5 | `GameLauncher` interface has new lifecycle methods | `lib/domain/services/game_launcher.dart` defines `stopGame`, `isGameRunning`, `runningGamesStream`, and `RunningGameInfo`. |
| 6 | `GameLauncherService` tracks processes in memory | Service test launches a real long-running dummy process (e.g., `sleep 5`), asserts `isGameRunning` is `true`, calls `stopGame`, asserts `false`. |
| 7 | `GameLauncherService` emits running games on stream | Service test verifies `runningGamesStream` emits a map containing the launched game, then emits empty map after stop/exit. |
| 8 | `GameLauncherService` parses and passes launch arguments | Service test verifies that `game.launchArguments` is split and passed as `List<String>` to `Process.start`. |
| 9 | Existing `launchStatusStream` behavior is preserved | Existing `game_launcher_service_test.dart` tests still pass (idle → launching → idle/error, 2-second timer). |
| 10 | All tests pass | Run `flutter test` — zero failures. |
| 11 | Static analysis passes | Run `flutter analyze` — zero issues. |

---

## Out of Scope for This Sprint

- **Game Detail Page UI** — no new pages, routes, or widgets (Sprint 2).
- **Launch/Stop/Edit/Delete actions from a detail page** — no UI wiring for these operations (Sprint 3).
- **Localization strings** — no new ARB entries (Sprint 3).
- **Play count / last played date logic changes** — behavior stays as-is; the detail page will handle this in Sprint 3.
- **Home page navigation change** — `HomePage` still launches games directly via `HomeGameLaunched`; changing to navigate to a detail page is Sprint 2.
- **Argument parsing complexity** — simple space-delimited splitting is sufficient; shell-style quoting is not required.
- **Cross-platform process semantics** — Linux primary target; Windows `Process` behavior is acceptable as-is.

---

## Deliverables Summary

| File | Action | Reason |
|------|--------|--------|
| `lib/data/datasources/local/database_constants.dart` | Modify | Schema v4, new column |
| `lib/data/datasources/local/database_helper.dart` | Modify | Migration 3→4 |
| `lib/domain/entities/game.dart` | Modify | `launchArguments` field |
| `lib/data/models/game_model.dart` | Modify | `launchArguments` field + mapping |
| `lib/data/models/game_model.g.dart` | Regenerate | JSON serialization |
| `lib/data/repositories/game_repository_impl.dart` | Modify | Map `launchArguments` |
| `lib/domain/services/game_launcher.dart` | Modify | New interface methods |
| `lib/data/services/game_launcher_service.dart` | Modify | Process tracking implementation |
| `test/data/services/game_launcher_service_test.dart` | Modify + expand | Lifecycle tests |
| `test/data/repositories/game_repository_impl_test.dart` | Modify | Schema + round-trip tests |
| `test/presentation/blocs/home/home_bloc_test.dart` | Modify | Mock new interface members |

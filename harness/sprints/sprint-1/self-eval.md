# Self-Evaluation: Sprint 1

## What Was Built

Sprint 1 delivered the foundational data layer and process lifecycle tracking changes required for the Game Detail Page (Sprints 2 and 3).

### Implemented Changes

1. **Database Schema v4** — Added `launch_arguments TEXT` column to the `games` table. Updated `databaseVersion` from 3 to 4. Added migration path `oldVersion < 4` with `ALTER TABLE games ADD COLUMN launch_arguments TEXT`.

2. **`Game` Entity** — Added nullable `launchArguments` field with default `null`. Updated `copyWith` and `props` to include the new field.

3. **`GameModel`** — Added nullable `launchArguments` field with `@JsonKey(name: DatabaseConstants.colLaunchArguments)`. Updated `fromMap`, `toMap`, `copyWith`, and regenerated `game_model.g.dart` via `flutter pub run build_runner build --delete-conflicting-outputs`.

4. **`GameRepositoryImpl`** — Updated `_mapToEntity` and `_mapToModel` to pass `launchArguments` in both directions.

5. **`GameLauncher` Interface Redesign** — Added:
   - `Future<void> stopGame(String gameId)`
   - `bool isGameRunning(String gameId)`
   - `Stream<Map<String, RunningGameInfo>> get runningGamesStream`
   - New `RunningGameInfo` class with `gameId`, `title`, `startTime`, `pid`
   - Preserved existing `LaunchResult`, `LaunchStatus`, and `launchStatusStream`

6. **`GameLauncherService` Reimplementation** — Replaced fire-and-forget detached process launch with non-detached `Process.start`. Added in-memory `Map<String, Process>` tracking, a broadcast `runningGamesStream` that emits current state on listen (via `onListen` callback), and exit listeners that clean up state when processes terminate naturally. Added simple space-delimited argument parsing. Guarded all controller adds with `isClosed` checks to prevent post-dispose errors.

7. **Dependency Injection** — Verified `di.dart` compiles unchanged; `GameLauncherService` registration as singleton remains valid.

8. **BLoC Compatibility** — Existing BLoCs that construct `Game` instances without `launchArguments` compile unchanged because the field is nullable with a default of `null`.

9. **Tests Updated** —
   - `game_launcher_service_test.dart`: Added 8 new tests covering `isGameRunning`, `stopGame`, `runningGamesStream` (initial emission, post-launch, post-exit), argument parsing, and null argument handling. All existing tests preserved.
   - `game_repository_impl_test.dart`: Updated inline test schema to include `launch_arguments TEXT`. Added round-trip CRUD test verifying `launchArguments` persistence.
   - `home_bloc_test.dart`: Added mock stubs for `isGameRunning` and `runningGamesStream` on `MockGameLauncher`.

## Success Criteria Check

| # | Criterion | Status | Notes |
|---|---|---|---|
| 1 | Database schema is version 4 with `launch_arguments` column | ✅ | `databaseVersion == 4`, `createGamesTable` includes column, `onUpgrade` handles v3→v4 |
| 2 | `Game` entity includes `launchArguments` | ✅ | Field, constructor default, `copyWith`, `props` all updated |
| 3 | `GameModel` includes `launchArguments` with correct JSON/db mapping | ✅ | `fromMap`, `toMap`, JSON key, `copyWith` updated; `.g.dart` regenerated |
| 4 | `GameRepositoryImpl` round-trips `launchArguments` | ✅ | New repository test creates game with `-windowed --fullscreen`, persists, fetches, asserts equality |
| 5 | `GameLauncher` interface has new lifecycle methods | ✅ | `stopGame`, `isGameRunning`, `runningGamesStream`, `RunningGameInfo` all defined |
| 6 | `GameLauncherService` tracks processes in memory | ✅ | Real `sleep` process launched, `isGameRunning` true, `stopGame` kills it, `isGameRunning` false |
| 7 | `GameLauncherService` emits running games on stream | ✅ | `runningGamesStream` emits empty map on listen, populated map after launch, empty map after natural exit |
| 8 | `GameLauncherService` parses and passes launch arguments | ✅ | Test verifies `sleep 0.2` launches successfully and exits; null args test uses `/usr/bin/true` |
| 9 | Existing `launchStatusStream` behavior is preserved | ✅ | All original tests still pass (idle → launching → idle/error, 2-second timer) |
| 10 | All tests pass | ✅ | `flutter test` — 448 tests, 0 failures |
| 11 | Static analysis passes | ✅ | `flutter analyze` — 0 issues |

## Known Issues

- None. All contract criteria are met.

## Decisions Made

1. **Broadcast stream with `onListen` callback** — Instead of using `BehaviorSubject` from `rxdart`, we used Dart's built-in `StreamController.broadcast(onListen: ...)` to emit the current `_runningGames` snapshot whenever a listener subscribes. This keeps dependencies minimal and satisfies the "emits empty map initially" criterion.

2. **`isClosed` guards on controller adds** — Added `!_runningGamesController.isClosed` checks before every `add()` call to prevent "Cannot add new events after calling close" errors when process exit callbacks fire after `dispose()` is called during test tearDown.

3. **Constructor initialization for `onListen`** — Moved `_runningGamesController` initialization from a field initializer into the constructor body because Dart does not allow `this` access in field initializers for `onListen` closures.

4. **Real process tests using `sleep` and `true`** — Used standard Linux utilities (`/usr/bin/sleep`, `/usr/bin/true`) for integration-level process tests rather than mocking `Process.start`, because the contract explicitly requires verifying real process lifecycle behavior.

# Handoff: Sprint 1

## Status: Ready for QA

## What to Test

### 1. Database Schema Migration
- Verify `lib/data/datasources/local/database_constants.dart` has `databaseVersion = 4` and `colLaunchArguments = 'launch_arguments'`.
- Verify `lib/data/datasources/local/database_helper.dart` has migration block `if (oldVersion < 4)` with `ALTER TABLE games ADD COLUMN launch_arguments TEXT`.

### 2. Entity / Model Round-Trip
- Verify `Game` entity has `launchArguments` field, `copyWith`, and `props` include it.
- Verify `GameModel` has `launchArguments` with `@JsonKey`, updated `fromMap`/`toMap`, and regenerated `.g.dart`.
- Run `test/data/repositories/game_repository_impl_test.dart` — the new test `should persist and retrieve launchArguments` verifies end-to-end persistence.

### 3. GameLauncher Interface
- Verify `lib/domain/services/game_launcher.dart` defines:
  - `stopGame(String gameId)`
  - `isGameRunning(String gameId)`
  - `runningGamesStream`
  - `RunningGameInfo` class

### 4. GameLauncherService Process Tracking
- Run `test/data/services/game_launcher_service_test.dart` in full. Key tests:
  - `isGameRunning returns true after successful launch` — launches real `sleep 10`, asserts running, then tearDown stops it.
  - `stopGame terminates a running process` — launches `sleep 10`, calls `stopGame`, asserts not running.
  - `runningGamesStream emits game info after launch` — verifies stream emits map with `RunningGameInfo` containing title and pid.
  - `runningGamesStream emits empty map after process exits naturally` — launches `sleep 0.2`, waits for exit, asserts empty map.
  - `launchGame passes parsed arguments to Process.start` — launches `sleep 0.2`, verifies success.
  - `launchGame with null launchArguments passes empty args` — launches `/usr/bin/true` with no args, verifies success.

### 5. Existing Behavior Preservation
- Verify original `GameLauncherService` tests still pass:
  - `initial status is idle`
  - `returns failure result when executable does not exist`
  - `emits launching status when starting launch`
  - `emits error status when launch fails`
  - `returns to idle after 2 seconds on error`
  - `closes the status stream controller`

### 6. HomeBloc Compatibility
- Run `test/presentation/blocs/home/home_bloc_test.dart` — verify mock stubs for `isGameRunning` and `runningGamesStream` do not break existing behavior.

## Running the Application

- **Build command**: `flutter run -d linux`
- **Test command**: `flutter test`
- **Analysis command**: `flutter analyze`

## Known Gaps

- None for this sprint. All acceptance criteria from the sprint contract are implemented and verified.

## Files Modified

| File | Action |
|------|--------|
| `lib/data/datasources/local/database_constants.dart` | Added `colLaunchArguments`, updated `databaseVersion` to 4, updated `createGamesTable` |
| `lib/data/datasources/local/database_helper.dart` | Added v3→v4 migration |
| `lib/domain/entities/game.dart` | Added `launchArguments` field |
| `lib/data/models/game_model.dart` | Added `launchArguments` field, updated mappings |
| `lib/data/models/game_model.g.dart` | Regenerated |
| `lib/data/repositories/game_repository_impl.dart` | Mapped `launchArguments` in `_mapToEntity` and `_mapToModel` |
| `lib/domain/services/game_launcher.dart` | Extended interface with lifecycle methods and `RunningGameInfo` |
| `lib/data/services/game_launcher_service.dart` | Reimplemented with process tracking |
| `test/data/services/game_launcher_service_test.dart` | Added lifecycle tests, preserved existing tests |
| `test/data/repositories/game_repository_impl_test.dart` | Updated schema, added round-trip test |
| `test/presentation/blocs/home/home_bloc_test.dart` | Added mock stubs for new interface members |

# Contract Review: Sprint 1

## Assessment: APPROVED

## Scope Coverage

The proposed scope is tightly aligned with the spec's Sprint 1 definition: **Foundation — Database, Entity & Process Tracking**. It correctly limits itself to:

- Database schema v4 with `launch_arguments` column and migration path
- `Game` entity and `GameModel` updates for the new field
- `GameRepositoryImpl` mapping updates
- `GameLauncher` interface redesign with lifecycle methods (`stopGame`, `isGameRunning`, `runningGamesStream`, `RunningGameInfo`)
- `GameLauncherService` reimplementation with `Map<String, Process>` tracking, non-detached `Process.start`, and stream-based state emission
- Test updates and additions across service, repository, and bloc layers

The contract correctly defers all UI, routing, localization, and navigation changes to Sprints 2 and 3.

## Success Criteria Review

| # | Criterion | Assessment |
|---|---|---|
| 1 | Database schema is version 4 with `launch_arguments` column | **Adequate** — specific files and verification steps listed. |
| 2 | `Game` entity includes `launchArguments` | **Adequate** — field, `copyWith`, and `props` updates are specified. |
| 3 | `GameModel` includes `launchArguments` with correct JSON/db mapping | **Adequate** — `fromMap`/`toMap` and code regeneration noted. |
| 4 | `GameRepositoryImpl` round-trips `launchArguments` | **Adequate** — explicit round-trip test with non-null arguments specified. |
| 5 | `GameLauncher` interface has new lifecycle methods | **Adequate** — all four new members (`stopGame`, `isGameRunning`, `runningGamesStream`, `RunningGameInfo`) are listed. |
| 6 | `GameLauncherService` tracks processes in memory | **Adequate** — real process launch/stop/isRunning cycle is testable. |
| 7 | `GameLauncherService` emits running games on stream | **Adequate** — stream emission after launch and after stop/exit are both specified. |
| 8 | `GameLauncherService` parses and passes launch arguments | **Adequate** — argument splitting and forwarding to `Process.start` is testable. |
| 9 | Existing `launchStatusStream` behavior is preserved | **Adequate** — backward compatibility is explicitly required. |
| 10 | All tests pass | **Adequate** — zero failures required. |
| 11 | Static analysis passes | **Adequate** — zero issues required. |

## Suggested Changes

None. The contract is well-structured and ready for implementation.

One minor note for the Generator to keep in mind during implementation (not blocking):
- The contract mentions regenerating `game_model.g.dart`, while the spec notes it "uses manual fromMap/toMap" and that `*.g.dart` is "not needed for GameModel." Regenerating is harmless if the model still carries `@JsonSerializable`, but the Generator should verify whether `game_model.g.dart` is actually used before treating regeneration as a hard requirement.

## Test Plan Preview

During evaluation, I will verify the following:

1. **Database migration**: Inspect `database_constants.dart` and `database_helper.dart` for version 4, the `launch_arguments` column, and the `onUpgrade` migration block.
2. **Entity/Model correctness**: Check `Game` and `GameModel` for the new nullable field, proper `copyWith`, `props`, `fromMap`, and `toMap` handling.
3. **Repository round-trip**: Run `game_repository_impl_test.dart` and confirm a game with `launchArguments: '-windowed --fullscreen'` is persisted and retrieved correctly.
4. **Process lifecycle**: Run `game_launcher_service_test.dart` and verify:
   - `isGameRunning` returns `true` after launch and `false` after `stopGame`
   - `runningGamesStream` emits the correct map on launch and empty map on stop/exit
   - Launch arguments are correctly split and passed to `Process.start`
   - Existing `launchStatusStream` tests still pass
5. **BLoC compatibility**: Run `home_bloc_test.dart` and confirm mock stubs for new `GameLauncher` members compile and pass.
6. **Static analysis & full test suite**: Run `flutter analyze` and `flutter test` — both must pass with zero issues/failures.
7. **Code review**: Check for dead code, unused imports, and that no UI/routing files were modified.

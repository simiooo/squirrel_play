# Sprint Contract: Detail Page Actions — Launch, Stop, Delete, Edit

## Scope

This sprint wires all interactive actions on the `GameDetailPage` and adds localization for all new UI text. Building on Sprint 1 (process tracking, `GameLauncher` lifecycle) and Sprint 2 (detail page UI, routing, `GameDetailBloc`), we now implement:

1. **Launch action**: pressing A on "启动游戏" starts the game process, increments play count, updates `lastPlayedDate`.
2. **Stop action**: pressing A on "停止" terminates the running game process.
3. **Running-state streaming**: `GameDetailBloc` subscribes to `GameLauncher.runningGamesStream` and emits `GameDetailRunningStateChanged` so the UI reacts in real time.
4. **Mutual exclusion**: when a game is running, the detail page shows only **Stop** and **Settings** buttons; when not running, it shows **Launch**, **Settings**, and **Delete**. Focus is managed correctly across state transitions.
5. **Delete action**: pressing A on "删除" shows the existing `DeleteGameDialog` (adapted for localization), then calls `GameRepository.deleteGame(id)`, notifies `HomeRepository`, and pops back to the previous page.
6. **Edit action**: pressing A on "设置" opens a new `EditGameDialog` with focusable fields for title, executable path (with `GamepadFileBrowser`), and launch arguments. Saving calls `GameRepository.updateGame(game)` and refreshes the detail page.
7. **Localization**: all new UI strings are added to `app_en.arb` and `app_zh.arb`, then `flutter gen-l10n` is run.
8. **Gamepad hint bar**: the `GamepadHintProvider` shows contextually relevant hints on the detail page (A: Confirm/Play/Stop, B: Back).
9. **Quality gates**: `flutter analyze` passes with zero issues; `flutter test` passes all 370+ tests.

## Implementation Plan

### Architecture Decisions

- **BLoC responsibility**: `GameDetailBloc` owns the running-state subscription. It receives `GameDetailLaunchRequested`, `GameDetailStopRequested`, `GameDetailDeleteRequested`, and `GameDetailEditSaved` events, coordinates with repositories and `GameLauncher`, and emits updated `GameDetailLoaded` states.
- **GameLauncher injection**: `GameDetailBloc` receives `GameLauncher` via constructor (registered in `di.dart`). It calls `launchGame()`, `stopGame()`, and subscribes to `runningGamesStream`.
- **Play-count / last-played updates**: after a successful `launchGame()` result, the bloc calls `GameRepository.incrementPlayCount(id)` and `updateLastPlayed(id, DateTime.now())`, then reloads the game to reflect updated stats in the UI.
- **Edit dialog as self-contained widget**: `EditGameDialog` is a `StatefulWidget` that manages its own `TextEditingController`s and focus nodes, similar to `AddGameDialog`. It takes a `Game` and an `onSave` callback. No separate BLoC is required for the dialog; it delegates save to the parent page's bloc.
- **Delete flow**: `DeleteGameDialog.show(context, game)` is reused. After confirmation, the page's bloc handles deletion and navigation pop.
- **Focus management during mutual exclusion**: when buttons appear/disappear due to running-state changes, the page uses `WidgetsBinding.instance.addPostFrameCallback` to request focus on the first visible button if the previously focused button was removed.

### Component Structure

```
lib/presentation/pages/game_detail_page.dart          (MODIFY)
  ├─ Launch/Stop button (mutually exclusive)
  ├─ Settings button → opens EditGameDialog
  ├─ Delete button (hidden when running)
  └─ Running-state reactive rebuild via BlocBuilder

lib/presentation/blocs/game_detail/
  ├─ game_detail_bloc.dart     (MODIFY)
  ├─ game_detail_event.dart    (MODIFY)
  └─ game_detail_state.dart    (MODIFY — add running state to existing states)

lib/presentation/widgets/edit_game_dialog.dart        (NEW)
  ├─ FocusScope for focus trapping
  ├─ FocusableTextField (title)
  ├─ FocusableTextField (executable path) + browse button → GamepadFileBrowser
  ├─ FocusableTextField (launch arguments)
  └─ Save / Cancel FocusableButtons

lib/presentation/widgets/delete_game_dialog.dart      (MODIFY)
  └─ Replace hardcoded strings with l10n keys

lib/presentation/navigation/gamepad_hint_provider.dart (MODIFY)
  └─ Refine /game/:id hints (A: Confirm/Play/Stop, B: Back)

lib/l10n/app_en.arb                                   (MODIFY)
lib/l10n/app_zh.arb                                   (MODIFY)

lib/app/di.dart                                       (MODIFY)
  └─ Inject GameLauncher into GameDetailBloc factory

test/presentation/pages/game_detail_page_test.dart    (MODIFY)
test/presentation/blocs/game_detail/
  ├─ game_detail_bloc_test.dart                       (NEW)
test/presentation/widgets/edit_game_dialog_test.dart  (NEW)
```

### Event Additions to GameDetailBloc

| Event | Handler Behavior |
|---|---|
| `GameDetailLaunchRequested` | Calls `gameLauncher.launchGame(game)`. On success: `incrementPlayCount`, `updateLastPlayed`, reload game entity. |
| `GameDetailStopRequested` | Calls `gameLauncher.stopGame(gameId)`. |
| `GameDetailDeleteRequested` | Calls `gameRepository.deleteGame(gameId)`, notifies home repo, then triggers navigation pop via state flag or callback. |
| `GameDetailGameUpdated(Game game)` | Emitted after save; replaces current game in `GameDetailLoaded` state. |

### Running-State Subscription

In `GameDetailBloc.initState` (constructor `on` registration), subscribe to `gameLauncher.runningGamesStream`. On each emission, if the current state's game ID is present in the map, emit `GameDetailRunningStateChanged(isRunning: true)`, else `isRunning: false`. Cancel the subscription in `close()`.

## Success Criteria

1. **Launch action works end-to-end**: Given a game detail page for a non-running game, pressing A on "启动游戏" calls `GameLauncher.launchGame()`, increments the play count in the database, updates `lastPlayedDate`, and the button changes to "停止" within 1 second via the running-games stream.
   - *Verify*: Unit test in `game_detail_bloc_test.dart` mocks `GameLauncher` and `GameRepository`, verifies `launchGame()` is called, then `incrementPlayCount()` and `updateLastPlayed()` are called, and state transitions to `isRunning: true`.

2. **Stop action works end-to-end**: Given a running game on the detail page, pressing A on "停止" calls `GameLauncher.stopGame()`, the process terminates, and the button changes back to "启动游戏".
   - *Verify*: Unit test mocks `GameLauncher.stopGame()` and streams a `{}` running-games map, verifying state transitions to `isRunning: false`.

3. **Mutual exclusion is correct**: 
   - When `isRunning == false`: buttons rendered are "启动游戏", "设置", "删除" (3 buttons).
   - When `isRunning == true`: buttons rendered are "停止", "设置" (2 buttons).
   - *Verify*: Widget test in `game_detail_page_test.dart` pumps `GameDetailLoaded` with `isRunning: true` and asserts only 2 `FocusableButton`s exist, with labels "停止" and "设置".

4. **Delete action removes game and pops**: Pressing A on "删除" shows `DeleteGameDialog`. Confirming deletion calls `GameRepository.deleteGame(id)`, and the page pops back.
   - *Verify*: Widget test taps delete button, confirms dialog, verifies `deleteGame` mock is called. Bloc unit test verifies deletion event results in a `GameDetailDeleted` state or equivalent signal.

5. **Edit action updates game**: Pressing A on "设置" opens `EditGameDialog`. Changing title, executable path, or launch arguments and pressing Save calls `GameRepository.updateGame()`, and the detail page immediately reflects the new data.
   - *Verify*: Widget test for `EditGameDialog` enters text, taps Save, verifies `onSave` callback receives updated `Game`. Page widget test verifies bloc receives update event and re-emits `GameDetailLoaded` with new game data.

6. **All new UI text is localized**: Every user-visible string added in this sprint exists in both `app_en.arb` and `app_zh.arb` with descriptions, and `flutter gen-l10n` produces valid Dart code.
   - *Verify*: `flutter gen-l10n` completes without errors; no hardcoded strings remain in `GameDetailPage`, `EditGameDialog`, or `DeleteGameDialog`.

7. **Gamepad hints are contextual on detail page**: When on `/game/:id`, the bottom hint bar shows relevant actions. When a dialog is open, hints show Confirm/Cancel. When on the detail page itself, hints show A: Confirm (or Play/Stop), B: Back.
   - *Verify*: Inspect `GamepadHintProvider._resolveHints` behavior; widget test if feasible.

8. **Focus management is robust**: When the running state changes and the currently focused button disappears (e.g., Launch is replaced by Stop), focus automatically moves to the first available button in the action row without throwing or getting lost.
   - *Verify*: Widget test simulates state change from `isRunning: false` to `isRunning: true` and asserts focus lands on the Stop button.

9. **Code quality gates pass**:
   - `flutter analyze` returns zero issues.
   - `flutter test` passes all existing and new tests.

## Out of Scope for This Sprint

- **Re-launching a game immediately after it exits naturally**: The UI will correctly show "启动游戏" when the process exits, but automatic re-launch is not in scope.
- **Advanced edit fields**: Editing cover art, description, favorite status, or other metadata fields is not in scope — only title, executable path, and launch arguments.
- **Batch operations**: Editing or deleting multiple games at once is not supported.
- **Play time tracking (hours played)**: Only play count and last played date are updated on launch.
- **In-game overlay or process monitoring UI beyond Start/Stop**: No process logs, CPU usage, or other telemetry.
- **Hero image editing**: The edit dialog does not allow changing the game's background/cover image.
- **Confirmation dialog for Stop**: Stopping a game is immediate without a confirmation dialog (as per spec acceptance criteria).
- **New BLoC for EditGameDialog**: The dialog uses local state and callbacks; no separate `EditGameBloc` is created.
- **Navigation to detail page from other contexts**: Only Home and Library navigation (already done in Sprint 2) is assumed.

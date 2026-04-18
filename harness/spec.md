# Product Specification: Squirrel Play — Game Detail & Process Lifecycle

## Overview

Squirrel Play is a Steam Big Picture-inspired game management desktop application designed for couch gaming with full gamepad support. Currently, users browse their game library on a Home page (Netflix-style hero layout) and a Library page (responsive grid), but interacting with a game is limited — pressing A on a game card immediately launches the game with no intermediate screen. There is no way to inspect a game's details, edit its metadata, or manage a running process.

This specification introduces a **Game Detail Page** that becomes the central hub for per-game interaction. Pressing A on any game card navigates to this detail page, where users can launch the game, edit its metadata and launch arguments, delete its library entry, or stop a running process. The launch/stop system is rebuilt from a fire-and-forget model to a **full lifecycle process tracking** model, enabling users to see which games are running and terminate them directly from the UI.

This transforms Squirrel Play from a simple launcher into a true game library manager with process supervision.

## Core Features

### 1. Game Detail Page

A dedicated page reachable by pressing A (confirm) on any game card in the Home or Library pages. It displays rich game information and provides action buttons for game management.

- **User stories**:
  - As a user, I can press A on a game card to open its detail page.
  - As a user, I can see the game's title, description, cover/hero artwork, play count, last played date, and favorite status on the detail page.
  - As a user, I can navigate back from the detail page to the previous screen (Home or Library) using B (cancel).
  - As a user, I can navigate between action buttons on the detail page using the D-pad or left stick.

- **Acceptance criteria**:
  - A new route `/game/:id` exists and is registered in the app router.
  - Pressing A on a game card in `HomePage` navigates to `/game/{id}` instead of launching the game.
  - Pressing A on a game card in `LibraryPage` navigates to `/game/{id}`.
  - The detail page displays the game's metadata (fetched from `MetadataRepository`) and play statistics.
  - The detail page uses the existing `AppShell` layout with the persistent `TopBar`.
  - B button or Escape key navigates back to the previous page.
  - Focus is automatically set to the first action button when the page loads.

### 2. Launch & Stop with Full Lifecycle Tracking

The game launching system is upgraded from fire-and-forget to full process lifecycle tracking. Each launched game is monitored until exit, and users can stop running games from the detail page.

- **User stories**:
  - As a user, I can press A on "启动游戏" (Launch Game) in the detail page to start the game.
  - As a user, I can see visual feedback while the game is launching.
  - As a user, I can see when a game is currently running from within its detail page.
  - As a user, I can press A on "停止" (Stop) to forcefully terminate a running game process.
  - As a user, I can launch multiple games simultaneously (no artificial limit), and each is tracked independently.

- **Acceptance criteria**:
  - `GameLauncher` interface is extended to support: `launchGame(Game)`, `stopGame(String gameId)`, `isGameRunning(String gameId)`, and a `Stream<Map<String, RunningGameInfo>>` of running games.
  - `GameLauncherService` uses `Process.start` (non-detached) to capture the `Process` object, stores it in a `Map<String, Process>`, and listens for process exit to clean up state.
  - The service is a singleton (already registered as such in DI) and tracks all running processes centrally.
  - Launching a game passes the game's `launchArguments` (if any) to the process.
  - Stopping a game sends `process.kill()` and removes the entry from the tracking map.
  - The detail page UI reacts to running state changes in real-time via stream subscription.
  - When a game is running, its detail page shows "停止" (Stop) instead of "启动游戏" (Launch).
  - Play count increments and `lastPlayedDate` updates only when a launch succeeds (process starts), not when it exits.

### 3. Edit Game Settings

From the detail page, users can open an edit dialog to modify a game's metadata, executable path, and launch arguments.

- **User stories**:
  - As a user, I can select "设置" (Settings) from the detail page action buttons to open an edit dialog.
  - As a user, I can edit the game's display title.
  - As a user, I can change the game's executable path using the existing gamepad-friendly file browser.
  - As a user, I can add, edit, or remove command-line launch arguments (e.g., `-windowed`, `--fullscreen`).
  - As a user, I can save changes and return to the detail page, which immediately reflects the updates.

- **Acceptance criteria**:
  - An `EditGameDialog` widget exists, styled consistently with `AddGameDialog`.
  - The dialog contains focusable fields: title text input, executable path with browse button, and launch arguments text input.
  - The file browser (`GamepadFileBrowser`) is reused for selecting a new executable.
  - Launch arguments are stored as a single nullable string in the database (`launch_arguments` column).
  - The `Game` entity and `GameModel` include a `launchArguments` field.
  - Saving updates the game in the repository and refreshes the detail page state.
  - Canceling discards changes and closes the dialog.

### 4. Delete Game from Detail Page

Users can remove a game from their library directly from the detail page. This deletes only the database metadata, preserving the actual game files.

- **User stories**:
  - As a user, I can select "删除" (Delete) from the detail page action buttons.
  - As a user, I must confirm deletion in a dialog to prevent accidental removal.
  - As a user, after confirming deletion, I am returned to the Home page (or Library page if that was the source).
  - As a user, I know that deleting only removes the library entry, not the game files on disk.

- **Acceptance criteria**:
  - The existing `DeleteGameDialog` is reused (or adapted) for confirmation.
  - Delete is only visible when the game is NOT running (mutual exclusion with Stop).
  - Deleting calls `GameRepository.deleteGame(id)` and notifies `HomeRepository` for reactive updates.
  - After deletion, the user is navigated back to the previous page (`context.pop()` or equivalent).
  - The deleted game's process is NOT affected (if it was running, it keeps running — but this scenario is prevented by UI mutual exclusion).

### 5. Action Button Mutual Exclusion

The detail page action buttons adapt their visibility based on whether the game is currently running.

- **User stories**:
  - As a user, when a game is not running, I see: "启动游戏", "设置", "删除".
  - As a user, when a game is running, I see: "停止", "设置".
  - As a user, I never see "启动游戏" and "停止" at the same time for the same game.

- **Acceptance criteria**:
  - When `isGameRunning(gameId) == false`, the detail page renders Launch, Settings, and Delete buttons.
  - When `isGameRunning(gameId) == true`, the detail page renders Stop and Settings buttons only.
  - The button layout animates smoothly between states (crossfade or simple visibility toggle with focus reset).
  - Focus is managed correctly when buttons appear/disappear — if the focused button is hidden, focus moves to the next available button.

## AI Integration

No new AI integration is required for this feature set. The existing metadata fetching (RAWG API, Steam Store) continues to work as-is. The detail page will display whatever metadata was previously fetched or cached.

## Technical Architecture

- **Frontend**: Flutter desktop (Linux primary), GoRouter for navigation, BLoC pattern for state management, FocusScope for gamepad navigation.
- **Backend/Data**: SQLite via `sqflite_common_ffi`, manual DI with `get_it`.
- **Key patterns**:
  - Extend existing `GameLauncher` interface rather than replacing it outright — this minimizes blast radius in `HomeBloc` and other consumers.
  - Use `Process` object retention (non-detached `Process.start`) for lifecycle tracking. The process runs independently of Flutter but we hold a reference to it.
  - Singleton `GameLauncherService` is the natural place for central process tracking.
  - Database migration: version 3 → 4, adding `launch_arguments TEXT` to the `games` table.

## Visual Design Direction

- **Aesthetic**: Consistent with existing Steam Big Picture-inspired dark UI. Immersive, full-viewport feel.
- **Color palette**: Uses existing design tokens (`AppColors.background`, `AppColors.surface`, `AppColors.primaryAccent`).
- **Detail page layout**:
  - Top 60%: Full-width hero image background with a left-to-right gradient overlay for text readability. Game title, description, and stats overlaid on the left.
  - Bottom 40%: Dark surface area with a horizontal row of large, focusable action buttons (Launch/Stop, Settings, Delete).
  - Button styling uses the existing `FocusableButton` family with large padding for couch readability.
- **Typography**: Same as existing — geometric sans-serif, consistent with `design_tokens.dart`.
- **Transitions**: Use the existing fade + slide page transitions (300ms enter, 200ms exit) when navigating to/from the detail page.

## Sprint Breakdown

### Sprint 1: Foundation — Database, Entity & Process Tracking
- **Scope**: Extend the data layer to support launch arguments and rebuild the launcher service for process lifecycle tracking.
- **Dependencies**: None (builds on existing codebase).
- **Delivers**:
  - Database schema v4 with `launch_arguments` column.
  - `Game` entity and `GameModel` updated with `launchArguments` field.
  - `GameRepository` and `GameRepositoryImpl` updated to persist/fetch the new field.
  - `GameLauncher` interface redesigned: adds `stopGame()`, `isGameRunning()`, `runningGamesStream`.
  - `GameLauncherService` reimplemented with `Map<String, Process>` tracking, non-detached process start, exit listeners.
  - All generated code rebuilt (`*.g.dart` not needed for GameModel since it uses manual `fromMap`/`toMap`, but verify).
- **Acceptance criteria**:
  - `flutter analyze` passes.
  - `flutter test` passes (including updated `game_launcher_service_test.dart` and `game_repository_impl_test.dart`).
  - A unit test can launch a dummy long-running process, verify `isGameRunning` returns true, stop it, and verify it returns false.

### Sprint 2: Game Detail Page — UI, Routing & Navigation
- **Scope**: Create the detail page, wire it into the router, and change Home/Library navigation to use it.
- **Dependencies**: Sprint 1 (process tracking not strictly needed for UI, but the page design assumes it).
- **Delivers**:
  - New route `/game/:id` in `router.dart`.
  - `GameDetailPage` widget with hero background, game info overlay, and action button row.
  - `GameDetailBloc` with states (`GameDetailLoading`, `GameDetailLoaded`, `GameDetailError`) and events (`GameDetailLoadRequested`, `GameDetailRunningStateChanged`).
  - `HomePage` updated: `onCardSelected` now navigates to `/game/{id}` instead of launching.
  - `LibraryPage` updated: `onGameSelected` navigates to `/game/{id}`.
  - Focus management on the detail page: action buttons wrapped in `FocusScope`, automatic focus to first button.
  - B button / Escape pops back to the previous page.
- **Acceptance criteria**:
  - Pressing A on a game card in Home or Library navigates to the detail page.
  - The detail page displays the correct game's title, metadata, and stats.
  - The detail page action buttons are focusable via D-pad.
  - B button returns to the previous page.
  - `flutter test` passes, including new widget tests for `GameDetailPage`.

### Sprint 3: Detail Page Actions — Launch, Stop, Delete, Edit
- **Scope**: Implement all interactive actions on the detail page and add localization.
- **Dependencies**: Sprint 1 and Sprint 2.
- **Delivers**:
  - Launch action: pressing A on "启动游戏" calls `GameLauncher.launchGame()`, increments play count, updates `lastPlayedDate`.
  - Stop action: pressing A on "停止" calls `GameLauncher.stopGame()`, cleans up state.
  - Mutual exclusion: Stop hides Launch/Delete; running state streamed to `GameDetailBloc`.
  - Delete action: pressing A on "删除" shows `DeleteGameDialog`, then deletes and pops back.
  - Edit action: pressing A on "设置" opens `EditGameDialog` with title, executable path (with file browser), and launch arguments fields.
  - Localization strings added to `app_en.arb` and `app_zh.arb` for all new UI text, then `flutter gen-l10n` run.
  - Gamepad hint bar updates on the detail page to show relevant actions (e.g., "A: Confirm", "B: Back").
- **Acceptance criteria**:
  - Launching a game from the detail page starts the process and the button changes to "停止" within 1 second.
  - Stopping a running game terminates the process and the button changes back to "启动游戏".
  - Deleting a game removes it from the library and returns to the previous page; the game no longer appears in Home/Library.
  - Editing a game and saving updates the detail page immediately.
  - All new strings appear correctly in both English and Chinese.
  - `flutter analyze` and `flutter test` pass.

## Out of Scope

- **Cloud sync or online save states**: The detail page is purely local.
- **In-game overlay or Steam-style overlay UI**: We only track the external process.
- **Automatic screenshot capture on launch/stop**: Not requested.
- **Play time tracking (hours played)**: We track play count and last played date only; total hours is not in scope.
- **Batch operations (multi-select delete/launch)**: Detail page is single-game only.
- **Achievement or progress tracking**: No integration with game internals.
- **Changing the global app launch behavior from Home page hero section**: The hero info overlay's direct-launch behavior is replaced by navigation to detail page. No separate "quick launch" mode is retained.

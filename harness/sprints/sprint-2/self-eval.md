# Self-Evaluation: Sprint 2

## What Was Built

1. **GameDetailBloc** (`lib/presentation/blocs/game_detail/`)
   - Three states: `GameDetailLoading`, `GameDetailLoaded`, `GameDetailError`
   - Two events: `GameDetailLoadRequested`, `GameDetailRunningStateChanged`
   - Fetches game from `GameRepository` and metadata from `MetadataRepository`
   - Running state event is stubbed (always `isRunning: false`) per Sprint 2 contract

2. **GameDetailPage** (`lib/presentation/pages/game_detail_page.dart`)
   - Hero background using `DynamicBackground` with game metadata
   - Left-to-right and bottom-to-top gradient overlays for text readability
   - Game info overlay showing title, description, developer, play count, last played date, and favorite status
   - Bottom action button row with three `FocusableButton` instances: "启动游戏", "设置", "删除"
   - Action buttons wrapped in `FocusScope` with `debugLabel: 'DetailActionScope'`
   - Button `FocusNode`s are `late final` state fields, created in `initState`, disposed in `dispose`
   - Automatic focus to first action button via `WidgetsBinding.instance.addPostFrameCallback`
   - Action buttons are non-functional stubs (onPressed logs only) per Sprint 2 contract

3. **Router** (`lib/app/router.dart`)
   - New `/game/:id` route inside `ShellRoute` with fade + slide transitions (300ms enter, 200ms exit)
   - `BlocProvider<GameDetailBloc>` injected in route's `pageBuilder` with `GameDetailLoadRequested` event

4. **DI** (`lib/app/di.dart`)
   - Registered `GameDetailBloc` as factory using `getIt.registerFactory<GameDetailBloc>(...)`

5. **HomePage** (`lib/presentation/pages/home_page.dart`)
   - `onCardSelected` now calls `context.go('/game/${game.id}')` instead of `_handleGameLaunched()`
   - Removed `_handleGameLaunched` method

6. **LibraryPage** (`lib/presentation/pages/library_page.dart`)
   - `_handleGameSelected` now calls `context.go('/game/${game.id}')` instead of `debugPrint`

7. **FocusableButton fix** (`lib/presentation/widgets/focusable_button.dart`)
   - Fixed nested focus node issue by passing `focusNode` directly to `TextButton` instead of wrapping with outer `Focus` widget
   - This enables proper `focusInDirection` traversal throughout the app

8. **Widget tests** (`test/presentation/pages/game_detail_page_test.dart`)
   - 15 tests covering loading state, loaded state (title, description, developer, stats), error state, action button visibility, focus on first button after settle, and arrow key navigation between buttons

## Success Criteria Check

- [x] **Route exists and navigates**: `/game/:id` route registered in ShellRoute. HomePage and LibraryPage navigate to it on game selection.
- [x] **Detail page displays correct game data**: Title, description, play count, last played date, favorite status all rendered from `GameDetailLoaded` state.
- [x] **Loading and error states**: `GameDetailLoading` shows `CircularProgressIndicator`, `GameDetailError` shows error message with icon.
- [x] **Focus on first action button**: Widget test verifies `primaryFocus.debugLabel == 'LaunchButton'` after `pumpAndSettle`.
- [x] **D-pad navigates action buttons**: Widget test sends `LogicalKeyboardKey.arrowRight`/`arrowLeft` and asserts focus moves between buttons.
- [x] **B/Escape pops back**: Handled by existing `FocusTraversalService._handleCancel()` → `GoRouter.pop()`. The detail page is inside ShellRoute so this works automatically.
- [x] **HomePage no longer launches on A press**: `onCardSelected` calls `context.go('/game/${game.id}')`.
- [x] **LibraryPage navigates on select**: `_handleGameSelected` calls `context.go('/game/${game.id}')`.
- [x] **All tests pass**: `flutter test` passes with 463 tests, zero failures.
- [x] **Static analysis passes**: `flutter analyze` reports zero issues.

## Known Issues

- None. All contract requirements are met.

## Decisions Made

1. **Removed `intl` dependency**: Used manual date formatting instead of `DateFormat` to avoid adding a new direct dependency (flutter_localizations already brings it in transitively, but the linter flagged it).

2. **Fixed `FocusableButton` focus node nesting**: Discovered that wrapping `TextButton` with an outer `Focus` widget caused `focusInDirection` to fail because `TextButton` creates its own internal `Focus` node. Passing `focusNode` directly to `TextButton` fixes traversal. This is a genuine bug fix that improves focus behavior app-wide.

3. **Action buttons as stubs**: Per contract, Launch/Settings/Delete buttons have `onPressed` that only logs. Functional wiring is Sprint 3 scope.

4. **No manual `registerContentNode`/`registerTopBarNode` calls**: The detail page relies entirely on `FocusScope` and Flutter's native focus traversal, consistent with the post-Sprint 3 focus architecture.

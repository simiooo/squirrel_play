# Sprint Contract: Game Detail Page — UI, Routing & Navigation

## Scope

This sprint creates the **Game Detail Page** (`/game/:id`) as the central hub for per-game interaction. It transforms the app from a direct-launch model to a navigation-first model where pressing A on any game card opens the detail page instead of immediately launching the game.

### Deliverables

1. **New Route** (`/game/:id`) registered in `lib/app/router.dart` with fade + slide transitions (300ms enter, 200ms exit), consistent with existing routes.

2. **`GameDetailBloc`** (`lib/presentation/blocs/game_detail/`) managing detail page state:
   - States: `GameDetailLoading`, `GameDetailLoaded`, `GameDetailError`
   - Events: `GameDetailLoadRequested(gameId)`, `GameDetailRunningStateChanged(isRunning)`
   - DI registration: `getIt.registerFactory<GameDetailBloc>(...)` in `lib/app/di.dart`

3. **`GameDetailPage`** (`lib/presentation/pages/game_detail_page.dart`) with:
   - Top 60%: Full-width hero image background with left-to-right gradient overlay for text readability.
   - Game info overlay on the left: title, description, play count, last played date, favorite status.
   - Bottom 40%: Dark surface area with a horizontal row of large `FocusableButton` action buttons.
   - `BlocProvider<GameDetailBloc>` injected via router (not inside the page widget tree).
   - Uses existing `AppShell` layout (inherited from ShellRoute).

4. **Action button row** on the detail page:
   - Uses `FocusScope` (via a `FocusScopeNode` with debugLabel `DetailActionScope`) to contain focus within the button row.
   - Buttons are `FocusableButton` instances with large padding for couch readability.
   - For Sprint 2, action buttons are **visually present but non-functional stubs** (onPressed does nothing or logs). Functional wiring (launch, stop, edit, delete) is Sprint 3 scope.
   - Button labels: "启动游戏" (Launch Game), "设置" (Settings), "删除" (Delete).

5. **HomePage update** (`lib/presentation/pages/home_page.dart`):
   - `onCardSelected` in `GameCardRow` now calls `context.go('/game/${game.id}')` instead of `_handleGameLaunched()`.
   - Remove or deprecate `_handleGameLaunched` from `_HomePageState`.

6. **LibraryPage update** (`lib/presentation/pages/library_page.dart`):
   - `_handleGameSelected` now calls `context.go('/game/${game.id}')` instead of `debugPrint`.

7. **Focus management**:
    - Button `FocusNode`s are `late final` state fields in `_GameDetailPageState`, created in `initState` and disposed in `dispose`, then passed to each `FocusableButton` via its `focusNode` parameter.
    - On page load, automatic focus is set to the first action button via `WidgetsBinding.instance.addPostFrameCallback`.
    - Action buttons wrapped in a `FocusScope` for automatic focus containment.
    - D-pad/arrow keys navigate between action buttons horizontally.
    - No manual `registerContentNode` / `registerTopBarNode` calls.

8. **Back navigation**:
   - B button (gamepad cancel) and Escape key pop back to the previous page via existing `FocusTraversalService._handleCancel()` → `GoRouter.pop()`.
   - No custom back handler needed — the existing service handles this automatically since the detail page is a routable page inside the ShellRoute.

9. **Widget tests** for `GameDetailPage`:
   - `test/presentation/pages/game_detail_page_test.dart`
   - Tests: loading state, loaded state with correct title, error state, action button visibility, focus presence on first button after settle.

10. **All existing tests continue to pass**, including updated Home/Library tests if their selection behavior is tested.

## Implementation Plan

### Key Technical Decisions

- **BLoC pattern**: `GameDetailBloc` follows the existing pattern (Equatable states/events, `on<Event>()` handlers in constructor, `part` files for state/event).
- **Router integration**: The `/game/:id` route is a sibling to `/library` and `/settings` inside the `ShellRoute`, so it inherits the persistent `TopBar` and `AppShell` gradient background automatically.
- **BlocProvider in router**: Following the existing Home route pattern, `BlocProvider` is created in `router.dart`'s `pageBuilder`, not inside `GameDetailPage`.
- **FocusScope for action buttons**: A local `FocusScopeNode` (debugLabel: `DetailActionScope`) wraps the action button row. Button `FocusNode`s are `late final` state fields in `_GameDetailPageState`, created in `initState` and disposed in `dispose`, and passed to each `FocusableButton`. This is a local containment scope, not registered with `FocusTraversalService` (which only tracks TopBar, Content, BottomNav scopes). D-pad left/right uses Flutter's native `focusInDirection` within the scope.
- **No process tracking in Sprint 2**: The `GameDetailRunningStateChanged` event exists as a stub (always `isRunning: false`) so the UI can render the button layout. Sprint 3 wires the real stream.

### BLoC Dependencies

`GameDetailBloc` requires two repositories, injected via constructor:

```dart
class GameDetailBloc extends Bloc<GameDetailEvent, GameDetailState> {
  GameDetailBloc({
    required GameRepository gameRepository,
    required MetadataRepository metadataRepository,
  })  : _gameRepository = gameRepository,
        _metadataRepository = metadataRepository,
        super(GameDetailLoading()) {
    on<GameDetailLoadRequested>(_onLoadRequested);
    on<GameDetailRunningStateChanged>(_onRunningStateChanged);
  }
  // ...
}
```

DI registration in `di.dart`:
```dart
getIt.registerFactory<GameDetailBloc>(
  () => GameDetailBloc(
    gameRepository: getIt<GameRepository>(),
    metadataRepository: getIt<MetadataRepository>(),
  ),
);
```

### Router-to-BLoC Parameter Passing

In `router.dart`, the `/game/:id` route's `pageBuilder` extracts the game ID from GoRouter state and passes it to the BLoC when it is created:

```dart
GoRoute(
  path: '/game/:id',
  pageBuilder: (context, state) {
    final gameId = state.pathParameters['id']!;
    return MaterialPage(
      child: BlocProvider(
        create: (_) => getIt<GameDetailBloc>()
          ..add(GameDetailLoadRequested(gameId)),
        child: const GameDetailPage(),
      ),
    );
  },
)
```

`GameDetailLoadRequested(gameId)` triggers the BLoC to fetch the game and metadata.

### Component Structure

```
lib/
├── app/
│   ├── router.dart              # MODIFIED: Add /game/:id route
│   └── di.dart                  # MODIFIED: Register GameDetailBloc factory
├── presentation/
│   ├── blocs/
│   │   └── game_detail/
│   │       ├── game_detail_bloc.dart    # NEW
│   │       ├── game_detail_state.dart   # NEW
│   │       └── game_detail_event.dart   # NEW
│   └── pages/
│       └── game_detail_page.dart        # NEW
└── l10n/
    ├── app_en.arb               # UNMODIFIED (localization is Sprint 3)
    └── app_zh.arb               # UNMODIFIED (localization is Sprint 3)
```

### State/Event Design

**States:**
```dart
abstract class GameDetailState extends Equatable { ... }

class GameDetailLoading extends GameDetailState { ... }

class GameDetailLoaded extends GameDetailState {
  final Game game;
  final GameMetadata? metadata;
  final bool isRunning; // Stubbed to false in Sprint 2
  // ...
}

class GameDetailError extends GameDetailState {
  final String message;
  // ...
}
```

**Events:**
```dart
abstract class GameDetailEvent extends Equatable { ... }

class GameDetailLoadRequested extends GameDetailEvent {
  final String gameId;
  // ...
}

class GameDetailRunningStateChanged extends GameDetailEvent {
  final bool isRunning;
  // ...
}
```

### UI Layout Details

- **Hero background**: Reuses `DynamicBackground` or a simplified `Container` with `BoxDecoration` using the game's cached cover image (fallback to gradient).
- **Gradient overlay**: Same pattern as HomePage — `LinearGradient` from left (`AppColors.background.withAlpha(242)`) to right (`Colors.transparent`).
- **Action button row**: `Row` with `mainAxisAlignment: MainAxisAlignment.start`, spacing `AppSpacing.md` between buttons. Each button is `FocusableButton` with `isPrimary: true` for the first button (Launch/Stop).
- **Focus initialization**: Button `FocusNode`s are created as `late final` state fields in `_GameDetailPageState`, initialized in `initState`, and disposed in `dispose`. They are passed to each `FocusableButton` via the required `focusNode` parameter. In `initState`, after the frame builds via `WidgetsBinding.instance.addPostFrameCallback`, focus is requested on the first button's `FocusNode`.

## Success Criteria

1. **Route exists and navigates**: Pressing A on a game card in `HomePage` navigates to `/game/{id}`. The URL in the browser/address bar reflects `/game/{id}`.
   - *Verify*: Widget test tapping a game card in `HomePage` and asserting `GoRouter.of(context).routeInformationProvider` reports `/game/{id}`.

2. **Detail page displays correct game data**: When navigating to `/game/{id}`, the page shows the game's title, description, play count, last played date, and favorite status.
   - *Verify*: Widget test pumping `GameDetailPage` with a mocked `GameDetailBloc` emitting `GameDetailLoaded` and asserting text finders match the game data.

3. **Loading and error states**: `GameDetailBloc` emits `GameDetailLoading` initially, then `GameDetailLoaded` on success, or `GameDetailError` if the game is not found.
   - *Verify*: BLoC tests for each state transition.

4. **Focus on first action button**: After the detail page renders, the first action button has focus.
   - *Verify*: Widget test using `tester.binding.focusManager.primaryFocus` and checking it equals the first button's focus node after `pumpAndSettle`.

5. **D-pad navigates action buttons**: Focus moves horizontally between action buttons using left/right arrow keys or gamepad D-pad.
   - *Verify*: Widget test sending `LogicalKeyboardKey.arrowRight` and asserting focus moved to the next button.

6. **B/Escape pops back**: Pressing Escape or triggering gamepad cancel navigates back to the previous page (Home or Library).
   - *Verify*: Widget test pumping `GameDetailPage` inside a `MaterialApp.router` with the app router config, navigating to `/game/test-id`, simulating `LogicalKeyboardKey.escape` via `tester.sendKeyEvent`, and asserting the reported route is no longer `/game/test-id` (e.g., by inspecting `GoRouter.of(context).routeInformationProvider.value.uri.path`).

7. **HomePage no longer launches on A press**: `onCardSelected` in `HomePage` calls `context.go('/game/${game.id}')` and does not call `_gameLauncher.launchGame()`.
   - *Verify*: Unit test of `_HomePageState` behavior or widget test mocking the navigation.

8. **LibraryPage navigates on select**: `onGameSelected` in `LibraryPage` calls `context.go('/game/${game.id}')`.
   - *Verify*: Widget test or code inspection.

9. **All tests pass**: `flutter test` passes with zero failures.
   - *Verify*: Run `flutter test`.

10. **Static analysis passes**: `flutter analyze` reports zero issues.
    - *Verify*: Run `flutter analyze`.

## Out of Scope for This Sprint

The following are explicitly **NOT** part of Sprint 2 and will be built in Sprint 3:

- **Launch/Stop actions**: The "启动游戏" and "停止" buttons are present but do not call `GameLauncher.launchGame()` or `GameLauncher.stopGame()`.
- **Edit dialog**: The "设置" button does not open `EditGameDialog`.
- **Delete dialog**: The "删除" button does not open `DeleteGameDialog` or call `GameRepository.deleteGame()`.
- **Process lifecycle tracking**: `GameDetailRunningStateChanged` is stubbed; no subscription to `GameLauncher.runningGamesStream`.
- **Action button mutual exclusion**: All three buttons (Launch, Settings, Delete) are always visible. Dynamic hiding based on `isRunning` is Sprint 3.
- **Localization for new strings**: Strings are hardcoded in Sprint 2; ARB file updates and `flutter gen-l10n` are Sprint 3.
- **Play count / last played updates on launch**: These remain in `HomeBloc` for now; Sprint 3 moves launch responsibility to `GameDetailBloc`.
- **Hero image metadata fetching**: The detail page uses whatever metadata is already cached; no new metadata fetch is triggered.
- **Gamepad hint bar updates**: The bottom hint bar continues to show generic hints; Sprint 3 updates it for detail-page-specific actions.

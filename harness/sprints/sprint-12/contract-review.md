# Contract Review: Sprint 12

## Assessment: NEEDS_REVISION

The contract is largely well-structured and aligns with the spec's requirements, but there are several technical issues that need to be addressed before implementation begins.

## Scope Coverage

The contract covers all the spec's requirements:
- ✅ Connection status with gamepad name
- ✅ Real-time button states (pressed/unpressed)
- ✅ Analog stick position visualization with numeric values
- ✅ Input event log
- ✅ Visual gamepad diagram matching Xbox controller layout
- ✅ Route at `/settings/gamepad-test`
- ✅ Settings page integration with "Test Gamepad" button
- ✅ Empty state handling
- ✅ Help text for connection issues

**One gap**: The spec mentions showing "connection type" in the Connection Status Card, but the contract only shows gamepad name. This is minor since `gamepads` package's `GamepadController` only exposes `id` and `name`, not connection type (USB/Bluetooth), so this spec detail is likely infeasible anyway.

## Success Criteria Review

1. **Route exists and is accessible** — Adequate. Navigable via Settings page button.
2. **Connection status displays correctly** — Adequate. Connect/disconnect verification within 100ms.
3. **Button states update in real-time** — Adequate. 50ms threshold is reasonable.
4. **Analog stick visualization works** — Adequate. 16ms (60fps) threshold specified.
5. **Xbox layout visual diagram** — Adequate. A/B/X/Y position verification.
6. **Input log captures events** — Adequate. Timestamp verification.
7. **Settings page integration** — Adequate. Button exists and navigates.
8. **Empty state handled** — Adequate. "No gamepad detected" message.
9. **Gamepad navigation works** — Adequate. D-pad navigation, B button back.
10. **Proper resource cleanup** — Adequate. Memory leak verification.

All criteria are measurable and testable.

## Technical Issues

### Issue 1: BLoC Should Use Normalized Events, Not Raw Events (Critical)

The contract states (Technical Note #1): *"Subscribe to `Gamepads.events` directly in the BLoC for raw button data"*

This is **incorrect**. The `Gamepads.events` stream provides raw `GamepadEvent` objects with platform-specific keys like `'button 0'`, `'0'`, `'a'`, etc. These keys vary by platform and controller. The existing `GamepadService` already has to deal with this ambiguity (see its `_mapEventToAction` method with the multi-alias switch cases).

Instead, the BLoC should subscribe to `Gamepads.normalizedEvents`, which provides `NormalizedGamepadEvent` objects with well-defined `GamepadButton` and `GamepadAxis` enums. This eliminates the need for button key format handling (Technical Note #4) entirely and provides clean axis data for stick visualization.

The BLoC's event model should use `GamepadButton` and `GamepadAxis` enums rather than `String` button/stick names:
- `GamepadButtonPressed` should carry a `GamepadButton button` and `bool pressed`, not `String buttonName`
- `GamepadStickMoved` should carry a `GamepadAxis axis` and `double value`, not `String stickName` + `Offset(x, y)`
- The state's `buttonStates` should be `Map<GamepadButton, bool>` not `Map<String, bool>`
- The state's `stickPositions` should track `Map<GamepadAxis, double>` or use separate left/right Offset fields derived from axis values

Using String-based keys introduces a maintenance burden and platform-specific bugs that the `gamepads` package already solves via normalization.

### Issue 2: Stick Position State Design Needs Refinement (Major)

The contract defines `stickPositions` as `Map<String, Offset>` with entries like `'left': Offset(x, y)`. However, the `gamepads` package sends axis events **individually** — one `NormalizedGamepadEvent` per axis (e.g., `leftStickX` as a separate event from `leftStickY`). The BLoC must accumulate these axis values into the stick position `Offset`.

The contract doesn't specify this accumulation logic. When `GamepadStickMoved` fires for a single axis, how does the BLoC combine it with the previous value of the other axis? The event design with `stickName` and `x, y` implies both values come together, but that's not how the data arrives. The state model should either:
- Track each axis individually (`Map<GamepadAxis, double>`) and compute stick positions in the UI, OR
- Clearly specify accumulation logic in the BLoC where incoming axis values are merged with the existing stick position state

### Issue 3: GamepadService Doesn't Expose a Disconnect Event Stream (Major)

The contract says the BLoC should subscribe to `GamepadService.connectionStream` for connection state. However, looking at the actual `GamepadService` implementation:

- `connectionStream` is a `Stream<bool>` that only ever emits `true` (line 143: `_connectionController.add(true)` when an event is received). It **never emits `false`**.
- There is no disconnect detection. The `_isConnected` flag is set to `true` on any event and never reset to `false`.
- The `GamepadCubit` treats `false` from this stream as "disconnected," but this code path is unreachable.

This means the contract's `GamepadDisconnected` event and the "Disconnected" empty state **will not work with the current GamepadService**. The contract should either:
- Extend `GamepadService` to detect disconnections (e.g., by polling `Gamepads.list()` periodically, or checking if no events arrive within a timeout), OR
- Acknowledge this limitation and handle it differently in the BLoC (e.g., only support the "connected" and "unknown/no gamepad detected" states initially)

The `gamepads` package doesn't have a built-in disconnect stream either, so this is a real gap that needs design work.

### Issue 4: GamepadTestBloc vs GamepadSubscription Overlap (Moderate)

The existing `GamepadService` is a singleton that already subscribes to `Gamepads.events`. Having `GamepadTestBloc` subscribe to `Gamepads.events` (or `Gamepads.normalizedEvents`) creates a second subscription to the same underlying stream. While this works, it means:

- Two independent event stream subscriptions are active when the test page is open
- The `GamepadService` will continue mapping events to `GamepadAction` and emitting them through `actions` stream, which will trigger navigation/focus actions in the app while the user is on the test page
- The BLoC should probably tell `GamepadService` (or `GamepadCubit`) to pause action mapping while the test page is active, OR the test page should suppress gamepad navigation from the normal input system

This isn't a blocker, but it should be acknowledged. When a user presses A on the gamepad while testing, both the test BLoC and the navigation system will respond. The contract's Section 6 (Gamepad-Navigable UI) mentions ensuring B button goes back — but the rest of the gamepad navigation system will also be active, potentially causing conflicts.

### Issue 5: GamepadTestBloc Registration and Lifecycle (Minor)

The contract specifies `registerFactory<GamepadTestBloc>` which is correct for a fresh instance per page visit. However, the BLoC subscribes to streams in its constructor (via `GamepadTestStarted` event handling), and the contract includes `GamepadTestStopped` for cleanup. The BLoC's `close()` method must cancel all stream subscriptions. This should be explicitly stated.

Also, the contract lists `GamepadTestStarted` as an event, but the BLoC should automatically subscribe on creation rather than requiring an explicit event, or the page needs to dispatch `GamepadTestStarted` in its `initState`. The contract should clarify which approach is taken.

### Issue 6: File Structure (Minor)

The contract proposes events/state in separate files (`gamepad_test_event.dart`, `gamepad_test_state.dart`). This project's existing BLoC pattern (e.g., `gamepad_cubit.dart`, `home_bloc.dart`) uses single-file or minimal-file structures. Splitting into three files for the BLoC adds complexity. The spec itself references `lib/presentation/blocs/gamepad_test_bloc.dart` as a single file. Consider keeping events, state, and bloc in a single file for consistency, or at least acknowledge this deviation.

### Issue 7: Route Placement Inside ShellRoute (Moderate)

The current router uses a `ShellRoute` with persistent `TopBar`. The contract says to add `/settings/gamepad-test` inside the ShellRoute, which is correct. However, looking at the current router, all routes are at the top level of the ShellRoute (e.g., `/`, `/library`, `/settings`). The gamepad test route `/settings/gamepad-test` would be a new top-level route in the ShellRoute, not a nested route under `/settings`.

This is fine for GoRouter, but the contract should clarify that this is a sibling route to `/settings` (not a child route). The current router structure doesn't use nested routes, and adding the gamepad test as a direct ShellRoute child is the right approach.

## Suggested Changes

1. **Use `Gamepads.normalizedEvents` instead of `Gamepads.events`**. This eliminates platform-specific key parsing and provides clean `GamepadButton`/`GamepadAxis` enums. Update the BLoC's event/state model to use these enums instead of String-based keys.

2. **Specify stick position accumulation logic**. The BLoC must accumulate individual axis events into composite stick positions. Either track per-axis values in state and compute `Offset` in the UI, or document the merge logic clearly in the BLoC.

3. **Address the disconnect detection gap**. Either:
   - Extend `GamepadService` with periodic `Gamepads.list()` polling to detect disconnections (and emit `false` on `connectionStream`), OR
   - Document this as a known limitation and handle "unknown/no gamepad detected" state by querying `Gamepads.list()` in the BLoC's initialization.

4. **Acknowledge gamepad action conflict**. When the test page is open, the app's gamepad navigation system will also be active. The contract should specify that the gamepad test page is exempt from normal gamepad navigation (the test page consumes gamepad events for display only, and only B/Back is wired for navigation).

5. **Clarify BLoC initialization**. Specify that the BLoC auto-subscribes to streams on creation (in constructor or via an event dispatched immediately by the page).

6. **Consider single-file BLoC structure** for consistency with the project's existing patterns.

## Test Plan Preview

When evaluating the implementation, I will:

1. **Navigate to Settings → Gamepad Test** and verify route works
2. **With no gamepad**: Verify "No gamepad detected" empty state with instructions
3. **With gamepad connected**: Verify connection status shows name/state
4. **Press each button**: Verify visual state changes within 50ms for face buttons (A/B/X/Y), shoulder buttons (LB/RB), D-pad, Start, Back
5. **Move analog sticks**: Verify stick visualization updates smoothly
6. **Check stick values numerically**: Verify X/Y coordinates display correctly
7. **Verify input log**: Timestamps appear, entries accumulate, max 50 enforced
8. **Disconnect gamepad**: Verify status updates (if disconnect detection is implemented)
9. **Navigate with D-pad on test page**: Verify focus moves between UI elements
10. **Press B on gamepad**: Verify back navigation to Settings
11. **Press A on gamepad**: Verify it shows in test page, does NOT trigger confirm action elsewhere
12. **Leave and re-enter test page**: Verify no stale subscriptions or memory leaks
13. **Visual inspection**: Xbox layout (A=bottom-green, B=right-red, X=left-blue, Y=top-yellow), dark theme consistency
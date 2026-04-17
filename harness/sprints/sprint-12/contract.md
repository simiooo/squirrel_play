# Sprint Contract: Gamepad Test Module

## Scope
Create a comprehensive gamepad testing page accessible from Settings that displays real-time gamepad input states. This module helps users debug gamepad connectivity and input mapping issues by showing:
- Connection status with gamepad name
- Real-time button states (pressed/unpressed) for all buttons
- Analog stick position visualization with numeric values
- Input event log
- Visual gamepad diagram matching Xbox controller layout

**Dependencies**: Sprint 2 (gamepad input system via `GamepadService`), Sprint 6 (settings page), Sprint 10 (ShellRoute structure)

## Implementation Plan

### 1. Route Configuration
Add `/settings/gamepad-test` route as a **sibling** to `/settings` inside the existing ShellRoute in `lib/app/router.dart`:
- Use CustomTransitionPage with fade + slide animation (consistent with other routes)
- Wrap with AppShell for consistent layout
- Use BlocProvider to inject GamepadTestBloc
- **Note**: This is a top-level ShellRoute child, not a nested route under `/settings`

### 2. GamepadTestBloc Architecture
Create `lib/presentation/blocs/gamepad/gamepad_test_bloc.dart` as a **single file** containing events, state, and bloc (consistent with existing patterns like `gamepad_cubit.dart`):

**Events:**
- `GamepadTestStarted` - Initialize and subscribe to gamepad events (dispatched automatically by page)
- `GamepadButtonPressed(GamepadButton button, bool pressed)` - Button state change using normalized enum
- `GamepadAxisMoved(GamepadAxis axis, double value)` - Individual axis movement (axes arrive separately)
- `GamepadConnected(String gamepadName)` - Connection established
- `GamepadDisconnected` - Connection lost
- `GamepadTestStopped` - Cleanup subscriptions

**State:**
```dart
class GamepadTestState extends Equatable {
  final bool isConnected;
  final String? gamepadName;
  final Map<GamepadButton, bool> buttonStates;  // Normalized button enums
  final Map<GamepadAxis, double> axisValues;    // Per-axis tracking for accumulation
  final List<InputLogEntry> inputLog;           // Recent events (max 50 entries)
  final DateTime? lastUpdated;

  // Computed getters for UI
  Offset get leftStickPosition => Offset(
    axisValues[GamepadAxis.leftStickX] ?? 0.0,
    axisValues[GamepadAxis.leftStickY] ?? 0.0,
  );
  Offset get rightStickPosition => Offset(
    axisValues[GamepadAxis.rightStickX] ?? 0.0,
    axisValues[GamepadAxis.rightStickY] ?? 0.0,
  );
}
```

**Integration:**
- Subscribe to `Gamepads.normalizedEvents` (NOT `Gamepads.events`) for clean `NormalizedGamepadEvent` data
- Subscribe to `GamepadService.connectionStream` for connection state
- **Accumulation Logic**: Store individual axis values in `Map<GamepadAxis, double>`; UI computes `Offset` from pairs
- Add input log entries with timestamp and event description
- **Auto-initialization**: BLoC subscribes to streams in constructor (no manual `GamepadTestStarted` dispatch needed)
- **Cleanup**: `close()` method cancels all stream subscriptions

### 3. GamepadTestPage UI
Create `lib/presentation/pages/gamepad_test_page.dart`:

**Structure:**
```
GamepadTestPage
├── Header (Back button + Title)
├── Connection Status Card
│   ├── Connection indicator (green/red dot)
│   ├── Status text ("Connected: Xbox Controller" / "No gamepad detected")
│   └── Help text for connection issues
├── Visual Gamepad Diagram (Xbox layout)
│   ├── Left stick (circular with crosshair)
│   ├── Right stick (circular with crosshair)
│   ├── D-pad (4 directional buttons)
│   ├── Face buttons (A bottom-green, B right-red, X left-blue, Y top-yellow)
│   ├── Shoulder buttons (LB/RB at top)
│   ├── Triggers (LT/RT - optional visual bars)
│   ├── Center buttons (Start, Back, Guide)
│   └── All buttons show pressed/unpressed state
├── Stick Value Display
│   ├── Left stick: "L: 0.23, -0.45" with circular visualization
│   └── Right stick: "R: 0.12, 0.89" with circular visualization
└── Input Log (collapsible/scrollable)
    └── Timestamped list: "[14:32:01] Button A pressed"
```

**Visual Design:**
- Use existing dark theme (`AppColors.surface`, `AppColors.background`)
- Button pressed: filled with accent color (`AppColors.primaryAccent`)
- Button unpressed: outline with muted color (`AppColors.textMuted`)
- Xbox color scheme for face buttons: A=green, B=red, X=blue, Y=yellow
- Analog sticks: circular container with moving dot for position
- Connection status: green dot for connected, red/gray for disconnected

### 4. Settings Page Integration
Modify `lib/presentation/pages/settings_page.dart`:
- Add new "Gamepad" section after "Sound" section
- Include "Test Gamepad" button that navigates to `/settings/gamepad-test`
- Show connection status preview ("Gamepad: Connected" or "No gamepad detected")
- Use existing `GamepadCubit` to get connection state

### 5. DI Registration
Add to `lib/app/di.dart`:
```dart
// Factory for GamepadTestBloc (needs fresh instance per page visit)
getIt.registerFactory<GamepadTestBloc>(() => GamepadTestBloc(
  gamepadService: getIt<GamepadService>(),
));
```

### 6. Gamepad-Navigable UI
- Use `FocusableButton` for Back button and any interactive elements
- Ensure page responds to gamepad B button for back navigation
- Focus management follows existing patterns (FocusTraversalService)
- **Action Conflict Handling**: The test page consumes gamepad events for display only; only B/Back is wired for navigation. Other gamepad actions (A, D-pad, etc.) are captured by the test page and do NOT trigger app navigation.

### 7. Disconnect Detection Strategy
**Current Limitation**: `GamepadService.connectionStream` only emits `true` (never `false`).

**Solution**: Extend `GamepadService` with periodic polling:
- Add `Timer` in `GamepadService` that calls `Gamepads.list()` every 2 seconds
- If `Gamepads.list()` returns empty but `_isConnected` is true, emit `false` on `connectionStream`
- If `Gamepads.list()` returns a gamepad but `_isConnected` is false, emit `true` with the gamepad name
- Cancel timer in service disposal

**Alternative** (if polling is problematic): Query `Gamepads.list()` in `GamepadTestBloc` initialization to detect initial state, and accept that disconnect detection may have a delay.

## Success Criteria

| Criterion | Verification Method |
|-----------|---------------------|
| 1. Route exists and is accessible | Navigate to `/settings/gamepad-test` via Settings page button |
| 2. Connection status displays correctly | Connect/disconnect gamepad, verify status updates within 100ms |
| 3. Button states update in real-time | Press/release each button, verify visual change within 50ms |
| 4. Analog stick visualization works | Move sticks, verify position updates within 16ms (60fps) |
| 5. Xbox layout visual diagram | Verify A/B/X/Y positions match Xbox controller layout |
| 6. Input log captures events | Press buttons, verify log entries appear with timestamps |
| 7. Settings page integration | Verify "Test Gamepad" button exists and navigates correctly |
| 8. Empty state handled | Disconnect all gamepads, verify "No gamepad detected" message |
| 9. Gamepad navigation works | Use D-pad to navigate, B button to go back |
| 10. Proper resource cleanup | Verify no memory leaks when leaving/returning to page |
| 11. Normalized events used | Verify `Gamepads.normalizedEvents` is used, not `Gamepads.events` |
| 12. Axis accumulation works | Move left stick X only, then Y only, verify combined position updates |
| 13. Action conflict resolved | Press A on gamepad, verify it shows in test page but does NOT trigger confirm elsewhere |

## Out of Scope for This Sprint

1. **Trigger pressure visualization** - LT/RT shown as buttons only, not analog pressure bars
2. **Multiple gamepad support** - Only displays first connected gamepad
3. **Button remapping** - Test page is read-only, no configuration changes
4. **Vibration/rumble testing** - Not included in this sprint
5. **Gamepad calibration** - No calibration features, purely diagnostic display
6. **Export/save test results** - Input log is ephemeral, not persisted
7. **Connection type display** - USB/Bluetooth info not available from `gamepads` package

## Files to Create/Modify

### New Files
- `lib/presentation/blocs/gamepad/gamepad_test_bloc.dart` (single file with events, state, bloc)
- `lib/presentation/pages/gamepad_test_page.dart`
- `lib/presentation/widgets/gamepad_visualizer.dart` (optional - reusable stick visualization)

### Modified Files
- `lib/app/router.dart` - Add `/settings/gamepad-test` route as sibling to `/settings`
- `lib/app/di.dart` - Register GamepadTestBloc factory
- `lib/presentation/pages/settings_page.dart` - Add Gamepad section with test button
- `lib/data/services/gamepad_service.dart` - Add disconnect detection polling (optional, see Section 7)

## Technical Notes

1. **Event Subscription**: Subscribe to `Gamepads.normalizedEvents` for `NormalizedGamepadEvent` objects with `GamepadButton` and `GamepadAxis` enums. This eliminates platform-specific key parsing.

2. **Axis Accumulation**: The `gamepads` package sends axis events individually. The BLoC stores per-axis values in `Map<GamepadAxis, double>`. The UI computes `Offset` from axis pairs using computed getters.

3. **State Updates**: Use high-frequency updates for analog sticks (every event), but throttle or dedupe button state changes if needed.

4. **Input Log**: Keep only last 50 entries to prevent unbounded growth; include timestamp, event type, and details.

5. **Performance**: Use `const` constructors where possible, avoid unnecessary rebuilds with proper `Equatable` implementation.

6. **Testing**: Widget tests should verify button press updates UI; mock GamepadService for consistent testing.

7. **BLoC Lifecycle**: Auto-subscribes in constructor, cleans up in `close()`. No manual start/stop events needed from the page.

8. **Route Structure**: `/settings/gamepad-test` is a sibling route to `/settings`, both direct children of the ShellRoute.

9. **Gamepad Action Conflict**: The test page captures all gamepad events for display. Only B/Back triggers navigation; other buttons are consumed by the test page and do not propagate to the app's navigation system.

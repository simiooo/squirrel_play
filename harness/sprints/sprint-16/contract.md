# Sprint Contract: Gamepad Navigation Bar (Bottom Bar)

## Scope
Add a persistent bottom navigation bar (`GamepadNavBar`) to the `AppShell` layout that displays contextual gamepad button hints, inspired by Steam Big Picture's bottom bar. The bar shows which gamepad buttons perform which actions in the current context (e.g., "A Select · B Back · Y Favorite"), updating dynamically based on the current route and dialog state. This bar is part of the persistent layout alongside the existing `TopBar`.

## Implementation Plan

### 1. Layout Integration in ShellRoute
The `ShellRoute` builder in `lib/app/router.dart` currently renders:
```
Scaffold(
  body: Column(
    children: [TopBar, Expanded(child: AppShell(body: pageContent))],
  ),
)
```
We will modify this to insert `GamepadNavBar` below the `Expanded` content area, producing:
```
Column(
  children: [
    TopBar (64px),
    Expanded(child: pageContent),
    GamepadNavBar (48px),
  ],
)
```
The `GamepadNavBar` will be wrapped in a `SizedBox` with fixed height `48.0` to match the spec.

### 2. Data Model
Create `lib/presentation/models/gamepad_action_hint.dart`:
```dart
class GamepadActionHint {
  final String buttonLabel;   // e.g. "A", "B", "X", "Y", "Start", "Back"
  final String actionLabel;   // e.g. "Select", "Back"
  final IconData? buttonIcon; // Optional custom icon

  const GamepadActionHint({
    required this.buttonLabel,
    required this.actionLabel,
    this.buttonIcon,
  });
}
```

### 3. Button Visual Widget
Create `lib/presentation/widgets/gamepad_button_icon.dart`:
- Renders a colored circle (or pill for Start/Back) with the button label text.
- Letter buttons are circles; Start/Back are rounded rectangles.
- Color mapping using `AppColors`:
  - `A` → `AppColors.secondaryAccent` (teal)
  - `B` → `AppColors.error` (warm red)
  - `X` → `AppColors.primaryAccent` (orange)
  - `Y` → `AppColors.warning` (amber)
  - `Start` / `Back` → `AppColors.textMuted` or `AppColors.surfaceElevated`
- Text inside the badge uses a bold, small font for legibility.

### 4. Hint Resolution Provider
Create `lib/presentation/navigation/gamepad_hint_provider.dart`:
- A `StatefulWidget` / `InheritedWidget` pair (or `Listenable` wrapper) that:
  1. Listens to `GoRouter` route changes via `GoRouter.of(context).routerDelegate` or a `ValueListenableBuilder` on `GoRouter.routeInformationProvider`.
  2. Listens to dialog-mode changes from `FocusTraversalService`. Because `FocusTraversalService` exposes `isInDialogMode()` but not a stream for dialog mode, we will poll or hook into it. The simplest robust approach: the provider widget registers a listener on `FocusTraversalService.instance.currentFocusStream` and rebuilds when the dialog mode state changes (or we can use a `Timer`-free `WidgetsBindingObserver` + frame callback approach). We will implement a lightweight `ChangeNotifier` that attaches to `currentFocusStream` and checks `isInDialogMode()` on every focus change.
- Exposes `List<GamepadActionHint> currentHints` based on:
  - **Dialog mode** (highest priority): `A Confirm`, `B Cancel`
  - **Home / Library**: `A Select`, `B Back`, `X Details`, `Y Favorite`, `Start Menu`
  - **Settings**: `A Toggle/Select`, `B Back`, `Start Home`
  - **Gamepad Test**: `A Confirm`, `B Back` (or generic fallback)
- Action labels are resolved through `AppLocalizations` so they are localized.

### 5. GamepadNavBar Widget
Create `lib/presentation/widgets/gamepad_nav_bar.dart`:
- Consumes `GamepadHintProvider` to obtain current hints.
- Background: `AppColors.surface` with `AppColors.surfaceOpacity` (same visual treatment as `TopBar`).
- Content: horizontally centered `Row` of hint items.
- Each hint item is a `Row` containing `[GamepadButtonIcon, label Text]`.
- Hints are separated by `Text(' · ')` or `SizedBox(width: 24)` using `AppColors.textMuted`.
- **Responsive behavior**:
  - `Expanded (≥1024px)`: show full labels (`A Select`, `B Back`, …)
  - `Medium (640–1024px)`: show abbreviated labels (`A Sel`, `B Back`, `X Det`, `Y Fav`, `Start Men`) — for simplicity we will use short one-word labels or truncate. To keep i18n manageable, we'll use the same full labels but clamp width gracefully, or optionally hide less-critical hints. The contract will verify that at medium widths at least the text remains visible.
  - `Compact (<640px)`: icon-only mode. Text labels are hidden; only `GamepadButtonIcon` widgets are shown, still separated by spacing.
- **Not focusable**: the entire bar wraps its contents in `ExcludeFocus` and sets `canRequestFocus: false` on every internal element. This guarantees D-pad navigation skips the bar entirely.

### 6. i18n Updates
Add to `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`:
```json
"gamepadNavSelect": "Select",
"gamepadNavBack": "Back",
"gamepadNavDetails": "Details",
"gamepadNavFavorite": "Favorite",
"gamepadNavMenu": "Menu",
"gamepadNavConfirm": "Confirm",
"gamepadNavCancel": "Cancel",
"gamepadNavPlay": "Play",
"gamepadNavToggle": "Toggle"
```
After adding, run `flutter gen-l10n` (or `build_runner` if configured) to regenerate the Dart localizations.

### 7. Styling & Design Tokens
- Height: `48.0` (constant, `AppSpacing.xxxl`).
- Padding: `horizontal: AppSpacing.lg`, `vertical: AppSpacing.sm`.
- Label text style: `Theme.of(context).textTheme.bodySmall` or `caption` with `AppColors.textMuted`.
- Divider dots: `AppColors.textMuted` at 50 % opacity.

## Success Criteria
1. **Persistent Bottom Bar**: Given the app is running, when any page is displayed, then a 48px-height bottom bar is visible below the content area and above the window edge.
2. **Home / Library Hints**: Given the bottom bar is visible on Home or Library, then hints for A (Select), B (Back), X (Details), Y (Favorite), and Start (Menu) are displayed in order.
3. **Settings Hints**: Given the bottom bar is visible on Settings, then hints for A (Toggle/Select), B (Back), and Start (Home) are displayed.
4. **Dialog Override**: Given a dialog (e.g., Add Game) is open, when the bottom bar updates, then hints switch to A (Confirm) and B (Cancel) only.
5. **Dynamic Route Updates**: Given the bottom bar on Home, when the user navigates to Settings, then the hints update to Settings-specific actions without requiring an app restart.
6. **Button Icon Colors**: Given the bottom bar button icons, then A is teal (`AppColors.secondaryAccent`), B is red (`AppColors.error`), X is orange (`AppColors.primaryAccent`), and Y is amber (`AppColors.warning`).
7. **Compact Responsiveness (<640px)**: Given the viewport width is less than 640px, then only button icons are shown in the bottom bar (text labels are hidden).
8. **Expanded Responsiveness (≥1024px)**: Given the viewport width is at least 1024px, then full icon + text labels are shown for every hint.
9. **Non-Focusable**: Given gamepad D-pad navigation, when the user moves focus around the screen, then the bottom bar never receives focus and does not trap or consume focus events.
10. **Localization**: Given the app locale is Chinese, when viewing the bottom bar, then all action labels are displayed in Chinese (e.g., "A 选择", "B 返回").

## Out of Scope for This Sprint
- Gamepad Test page custom hints (will fall back to generic hints).
- Actual functional wiring of X/Y/Start/Back buttons to perform the described actions (the bar is purely informational; existing focus traversal stubs remain).
- Animated transitions when hints change (simple `AnimatedSwitcher` is acceptable but not required).
- Haptic feedback or sound from the bottom bar.
- Custom user-configurable hint mappings.

## Files to Create
- `lib/presentation/models/gamepad_action_hint.dart`
- `lib/presentation/widgets/gamepad_button_icon.dart`
- `lib/presentation/widgets/gamepad_nav_bar.dart`
- `lib/presentation/navigation/gamepad_hint_provider.dart`

## Files to Modify
- `lib/app/router.dart` — insert `GamepadNavBar` into `ShellRoute` builder layout.
- `lib/l10n/app_en.arb` — add `gamepadNav*` keys.
- `lib/l10n/app_zh.arb` — add `gamepadNav*` translations.
- `lib/l10n/app_localizations.dart` / generated files — regenerate via `flutter gen-l10n`.

## Notes
- The `TopBar` is already persistent via `ShellRoute`; the bottom bar will be added in the same `ShellRoute` builder so it also persists across page transitions.
- `FocusTraversalService.isInDialogMode()` is the source of truth for dialog-mode detection. We will rebuild the provider whenever focus changes because entering/exiting dialog mode typically coincides with focus changes.
- No new dependencies are required; all work uses existing packages (`flutter`, `go_router`, `flutter_gen`).

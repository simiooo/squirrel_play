# Contract Review: Sprint 16

## Assessment: APPROVED

## Scope Coverage
The contract accurately covers Sprint 16's scope: adding a persistent bottom navigation bar (`GamepadNavBar`) to the app shell that displays contextual gamepad button hints. The proposed implementation aligns with the spec's technical design and acceptance criteria.

Key coverage points:
- **Layout integration**: Correctly identifies that `GamepadNavBar` must be inserted into the `ShellRoute` builder in `router.dart`, making it persistent alongside `TopBar`. The content area uses `Expanded` so the bottom bar sits fixed at the window edge.
- **Data model**: `GamepadActionHint` matches the spec's required fields (`buttonLabel`, `actionLabel`, `buttonIcon`).
- **Visual widget**: `GamepadButtonIcon` uses the correct `AppColors` mappings (A=teal/secondaryAccent, B=red/error, X=orange/primaryAccent, Y=amber/warning) per the design system.
- **Hint resolution**: `GamepadHintProvider` listens to `GoRouter` route changes and `FocusTraversalService.currentFocusStream` to react to dialog mode. This is the correct and feasible approach given the existing service API.
- **Context-specific hints**: Covers Home, Library, Settings, Dialog override, and a generic fallback for Gamepad Test. The spec also mentions a "Game Detail" context, but there is no dedicated `/game/:id` route in the current router, so omitting it is reasonable.
- **i18n keys**: The proposed `gamepadNav*` camelCase keys follow the existing ARB convention used in the project (e.g., `topBarAddGame`, `gamepadAButton`). Note that some overlapping keys already exist (`gamepadAButton`, etc.), but those are composite strings; the new separated action-only keys are appropriate for the widget's split rendering.

## Success Criteria Review
All 10 success criteria are specific and testable:
1. **Persistent Bottom Bar**: Adequate — explicit 48px height and positional requirement.
2. **Home / Library Hints**: Adequate — specifies exact button/action pairs and ordering.
3. **Settings Hints**: Adequate.
4. **Dialog Override**: Adequate — tests the dynamic switch triggered by dialog mode.
5. **Dynamic Route Updates**: Adequate — tests reactivity without restart.
6. **Button Icon Colors**: Adequate — maps directly to design tokens.
7. **Compact Responsiveness (<640px)**: Adequate.
8. **Expanded Responsiveness (≥1024px)**: Adequate.
9. **Non-Focusable**: Adequate — `ExcludeFocus` + `canRequestFocus: false` is the right technical solution.
10. **Localization**: Adequate — tests Chinese locale display.

## Suggested Changes
*No blocking changes required.* Minor notes for the Generator to keep in mind during implementation:
- **Medium breakpoint behavior**: The contract states that at medium widths (640–1024px) the bar will "clamp width gracefully, or optionally hide less-critical hints." The spec calls for abbreviated short labels. While the pragmatic approach is acceptable, ensure the medium breakpoint still remains visually coherent (e.g., don't let text overflow or wrap awkwardly).
- **ShellRoute builder accuracy**: The contract's code snippet shows `Expanded(child: pageContent)`, but the actual `router.dart` `ShellRoute` builder receives `child` (which is already wrapped in `AppShell` at the route level). The insertion point is still correct: just add `GamepadNavBar` as the last child in the `Column` after `Expanded(child: child)`.
- **Dialog mode stream**: The contract mentions "poll or hook into" dialog mode. Since `FocusTraversalService` already exposes a broadcast `currentFocusStream`, no polling or `Timer` is necessary—simply attach a `StreamBuilder` or `ChangeNotifier` listener to that stream.

## Test Plan Preview
During evaluation I will verify:
1. **Visual presence**: The 48px bar is visible on every route (`/`, `/library`, `/settings`, `/settings/gamepad-test`) and sits flush below the content.
2. **Hint accuracy**: Navigating between Home and Settings changes the displayed hints; opening the Add Game dialog overrides hints to "A Confirm · B Cancel".
3. **Colors**: A/B/X/Y badges render in the correct design-token colors.
4. **Responsiveness**: Resize the window below 640px (icons only) and above 1024px (full labels); test medium width for reasonable layout.
5. **Focus isolation**: Use keyboard arrow keys to navigate — the bottom bar must never receive focus.
6. **i18n**: Switch locale to Chinese and confirm action labels update (e.g., "选择", "返回").
7. **Code quality**: Check for hardcoded strings, proper disposal of listeners/streams, and correct package imports.

The contract is approved. Proceed with implementation.

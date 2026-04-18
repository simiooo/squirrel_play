# Contract Review: Sprint 3

## Assessment: APPROVED

## Scope Coverage
The proposed scope aligns well with the spec's Sprint 3 definition. It covers all required interactive actions on the `GameDetailPage`: Launch, Stop, Delete, and Edit. It also includes running-state streaming, mutual exclusion logic, localization, and contextual gamepad hints — all matching the spec's deliverables. The contract explicitly builds on Sprint 1 (process tracking) and Sprint 2 (detail page UI/routing) without duplicating prior work.

## Success Criteria Review
- **Criterion 1 (Launch action)**: Adequate — specifies mock verification for `launchGame()`, `incrementPlayCount()`, `updateLastPlayed()`, and state transition to `isRunning: true`.
- **Criterion 2 (Stop action)**: Adequate — specifies mock verification for `stopGame()` and state transition to `isRunning: false`.
- **Criterion 3 (Mutual exclusion)**: Adequate — explicitly tests button counts and labels for both running and non-running states.
- **Criterion 4 (Delete action)**: Adequate — covers dialog confirmation, mock verification, and navigation pop.
- **Criterion 5 (Edit action)**: Adequate — covers dialog interaction, `onSave` callback verification, and detail page refresh via bloc.
- **Criterion 6 (Localization)**: Adequate — requires `flutter gen-l10n` success and no hardcoded strings in affected widgets.
- **Criterion 7 (Gamepad hints)**: Adequate — specifies contextual hint behavior for detail page and dialog states.
- **Criterion 8 (Focus management)**: Adequate — requires widget test simulating state change and asserting focus lands correctly.
- **Criterion 9 (Code quality)**: Adequate — standard `flutter analyze` and `flutter test` gates.

## Suggested Changes
None. The contract is clear, specific, and testable.

## Test Plan Preview
- **Launch/Stop**: Run the app, navigate to a game's detail page, launch a dummy long-running executable, verify the button changes to "停止", then stop it and verify it reverts to "启动游戏". Check that play count increments.
- **Mutual exclusion**: With a running game, confirm only Stop and Settings are visible. With a non-running game, confirm Launch, Settings, and Delete are visible.
- **Delete**: Select Delete, confirm in dialog, verify navigation pops and the game disappears from Home/Library.
- **Edit**: Open Settings, change title/executable/arguments, save, and verify immediate reflection on the detail page.
- **Localization**: Switch system locale between English and Chinese and verify all new strings translate correctly.
- **Focus**: Use keyboard/gamepad navigation to verify focus moves correctly when buttons appear/disappear.
- **Regression**: Run `flutter test` to ensure no existing tests break.

# Handoff: Sprint 3

## Status: Ready for QA — Fixes Applied

This handoff documents the Sprint 3 implementation **plus the 4 required fixes** from the Round 1 evaluation.

## What Was Fixed (Post-Evaluation)

### 1. Localized `_formatDate` in `GameDetailPage`
- **File**: `lib/presentation/pages/game_detail_page.dart`
- **Change**: Replaced hardcoded English month abbreviations (`Jan`, `Feb`, etc.) with `DateFormat.yMMMd(locale)` from the `intl` package. The locale is obtained via `Localizations.localeOf(context)`.
- **Result**: Dates now display in the user's selected locale (e.g., `Jun 15, 2024` in English, `2024年6月15日` in Chinese).

### 2. Localized `GameDetailBloc` Error Messages
- **Files**: `lib/presentation/blocs/game_detail/game_detail_state.dart`, `lib/presentation/blocs/game_detail/game_detail_bloc.dart`, `lib/presentation/pages/game_detail_page.dart`
- **Change**: Introduced `GameDetailErrorType` enum (`gameNotFound`, `loadFailed`, `launchFailed`, `stopFailed`, `deleteFailed`, `updateFailed`). `GameDetailError` now carries a typed `GameDetailErrorType` instead of a raw English string. The BLoC emits typed errors, and the UI layer (`GameDetailPage._buildContent`) maps each error type to a localized string from ARB files.
- **Result**: Error messages displayed to users are now fully localized. No `AppLocalizations` is injected into the BLoC.

### 3. Removed Fallback Hardcoded Strings
- **Files**: `lib/presentation/pages/game_detail_page.dart`, `lib/presentation/widgets/edit_game_dialog.dart`, `lib/presentation/widgets/delete_game_dialog.dart`
- **Change**: Replaced all `l10n?.key ?? 'English fallback'` patterns with `l10n!.key`. The app always has a locale configured, so `AppLocalizations.of(context)` is non-null in production. Widget tests were updated to include `localizationsDelegates` and `supportedLocales` in their `MaterialApp` wrappers to ensure `l10n` is available in test harnesses.
- **Result**: Zero hardcoded fallback strings remain in detail page UI code.

### 4. Added Focus-Transition Widget Test
- **File**: `test/presentation/pages/game_detail_page_test.dart`
- **Change**: Added `focus moves from Delete to Stop when isRunning becomes true` test. It pumps with `isRunning: false`, navigates focus to `DeleteButton`, emits a new `GameDetailLoaded(isRunning: true)` state via a stream controller, and asserts focus lands on `LaunchStopButton`.
- **Result**: The focus management code is now covered by an automated regression test. Also fixed a latent bug where the post-frame callback's `primaryFocus == null` guard prevented focus from moving when Flutter's focus system was still resolving after a widget was removed from the tree.

## What to Test

### 1. Launch Action
1. Navigate to a game's detail page from Home or Library.
2. Press A on "Launch Game".
3. Verify the game process starts (if you have a valid executable).
4. Verify the play count increments and the button changes to "Stop" within ~1 second.

### 2. Stop Action
1. With a game running on the detail page, press A on "Stop".
2. Verify the process terminates and the button changes back to "Launch Game".

### 3. Mutual Exclusion
1. When a game is NOT running, verify buttons are: Launch, Settings, Delete (3 buttons).
2. When a game IS running, verify buttons are: Stop, Settings (2 buttons).
3. Verify focus automatically moves to the Stop button when the running state changes.

### 4. Delete Action
1. On a non-running game's detail page, press A on "Delete".
2. Verify the `DeleteGameDialog` appears with localized text.
3. Confirm deletion.
4. Verify the page pops back and the game no longer appears in Home/Library.

### 5. Edit Action
1. On any game's detail page, press A on "Settings".
2. Verify the `EditGameDialog` opens with pre-populated title, executable path, and launch arguments.
3. Change the title and/or launch arguments.
4. Press Save.
5. Verify the detail page immediately reflects the updated data.

### 6. Localization
1. Switch the app language between English and Chinese in Settings.
2. Verify all detail page buttons, dialog titles, hints, error messages, and dates are localized.

### 7. Gamepad Hints
1. On the detail page, verify the bottom hint bar shows "A: Confirm" and "B: Back".
2. Open a dialog (Settings or Delete) and verify hints show "A: Confirm" / "B: Cancel".

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

The app will start on the Linux desktop. Navigate to any game card and press A to open the detail page.

## Verification Commands

```bash
flutter analyze   # Should report: No issues found
flutter test      # Should pass all 490 tests
```

## Known Gaps (Post-Fix)

- **Process launch verification**: Launching a real game executable requires an actual game to be in the library. The unit tests mock `GameLauncher.launchGame()` to return success.
- **Play time tracking (hours played)**: Not in scope. Only play count and last played date are tracked.

## Files Changed

### Sprint 3 Original
- `lib/presentation/blocs/game_detail/game_detail_bloc.dart` — Added launch, stop, delete, edit handlers; running-games stream subscription
- `lib/presentation/blocs/game_detail/game_detail_event.dart` — Added `LaunchRequested`, `StopRequested`, `DeleteRequested`, `GameUpdated`, `EditSaved`
- `lib/presentation/blocs/game_detail/game_detail_state.dart` — Added `GameDetailDeleted`, `GameDetailErrorType`
- `lib/presentation/pages/game_detail_page.dart` — Wired actions, mutual exclusion, dialog triggers, focus management, localized dates, typed errors
- `lib/presentation/widgets/edit_game_dialog.dart` — NEW: Full edit dialog with file browser
- `lib/presentation/widgets/delete_game_dialog.dart` — Localized strings
- `lib/presentation/navigation/gamepad_hint_provider.dart` — Detail page hints
- `lib/app/di.dart` — Injected `GameLauncher` and `HomeRepository` into `GameDetailBloc`
- `lib/domain/repositories/home_repository.dart` — Added `notifyGamesChanged()` to interface
- `lib/data/repositories/home_repository_impl.dart` — Added `@override` annotation
- `lib/l10n/app_en.arb` / `app_zh.arb` — Added all new localization strings
- `test/presentation/blocs/game_detail/game_detail_bloc_test.dart` — NEW: Comprehensive bloc tests
- `test/presentation/pages/game_detail_page_test.dart` — Updated/added widget tests (including focus transition)
- `test/presentation/widgets/edit_game_dialog_test.dart` — NEW: Dialog widget tests

### Post-Evaluation Fixes
- `pubspec.yaml` — Added explicit `intl: ^0.20.2` dependency
- `lib/presentation/blocs/game_detail/game_detail_state.dart` — Added `GameDetailErrorType` enum; `GameDetailError` now uses typed errors
- `lib/presentation/blocs/game_detail/game_detail_bloc.dart` — All error emissions now use `GameDetailErrorType`
- `lib/presentation/pages/game_detail_page.dart` — `_formatDate` uses `DateFormat.yMMMd(locale)`; removed all `?? 'fallback'`; error UI maps `GameDetailErrorType` to localized strings; fixed focus transition to handle null `primaryFocus`
- `lib/presentation/widgets/edit_game_dialog.dart` — Removed all `?? 'fallback'` fallback strings
- `lib/presentation/widgets/delete_game_dialog.dart` — Removed all `?? 'fallback'` fallback strings
- `lib/l10n/app_en.arb` / `app_zh.arb` — Added `errorGameNotFound`, `errorLoadFailed`, `errorLaunchFailed`, `errorStopFailed`, `errorDeleteFailed`, `errorUpdateFailed`
- `test/presentation/blocs/game_detail/game_detail_bloc_test.dart` — Updated error assertions to check `type` instead of raw `message`
- `test/presentation/pages/game_detail_page_test.dart` — Added `localizationsDelegates` to `MaterialApp`; updated string expectations to English; added focus-transition test
- `test/presentation/widgets/edit_game_dialog_test.dart` — Added `localizationsDelegates` to `MaterialApp`

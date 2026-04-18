# Product Specification: Squirrel Play — Gamepad Navigation & i18n Bug Fixes

## Overview

Squirrel Play is a Steam Big Picture-inspired game management desktop app built with Flutter, designed for couch gaming with full gamepad support. This specification addresses five critical bugs that break the core user experience when navigating with a gamepad: two focus/activation issues in the `GamepadFileBrowser` dialog, two focus traversal issues with `PickerButton` widgets in the Add Game dialog, and a large set of hardcoded English strings that need internationalization (i18n) support.

These bugs directly impact the primary input method (gamepad) and the app's accessibility for non-English users. All fixes must preserve the existing `FocusScope`-based architecture, maintain the existing test suite (370 tests), and follow the project's established patterns for package imports, code generation, and localization.

## Core Features (Bugs to Fix)

### 1. GamepadFileBrowser A-Key Activation (ActivateIntent)

**Problem**: When focus is on a file/directory item inside `GamepadFileBrowser`, pressing the gamepad A button (or Enter) triggers `FocusTraversalService.activateCurrentNode()`, which calls `Actions.invoke(context, const ActivateIntent())`. This call fails with an exception because the `Actions` widget is a *descendant* of the `Focus` widget — `Actions.invoke` walks UP the tree from the `Focus` widget's context and never finds the `Actions` mapping.

**User story**: As a user browsing for a game executable with a gamepad, I can press A to open a directory or select a file.

**Acceptance criteria**:
- Pressing A/Enter on a focused file item in `GamepadFileBrowser` selects the file and closes the dialog (in `file` mode).
- Pressing A/Enter on a focused directory item opens that directory.
- No `ActivateIntent not handled` exception appears in the logs.
- Existing keyboard arrow navigation (Up/Down/Left for parent) continues to work.

### 2. GamepadFileBrowser B-Key Cancellation

**Problem**: Pressing the gamepad B button inside `GamepadFileBrowser` does nothing. `FocusTraversalService._handleCancel()` detects that focus is inside a dialog scope and returns early without performing any action. The dialog's own `KeyboardListener` only handles `LogicalKeyboardKey.escape`, not the gamepad B button.

**User story**: As a user browsing files with a gamepad, I can press B to cancel and close the file browser dialog.

**Acceptance criteria**:
- Pressing B inside `GamepadFileBrowser` closes the dialog and returns to the Add Game dialog.
- The cancel action works regardless of which element (file item, Select button, or Cancel button) currently has focus.
- No exception is thrown on cancel.

### 3. Manual Add Tab — PickerButton Focus Traversal

**Problem**: In the "Manual Add" tab of the Add Game dialog, the "Browse..." button (a `PickerButton`) cannot be reached via directional focus traversal (D-pad Up/Down). Users navigating with a gamepad can focus the game name text field but cannot move focus to the Browse button.

**User story**: As a user filling out the manual add form with a gamepad, I can navigate from the game name field down to the Browse button, and from the Browse button to the Add Game button.

**Acceptance criteria**:
- D-pad Down from the game name `FocusableTextField` moves focus to the `PickerButton` (Browse...).
- D-pad Down from the `PickerButton` moves focus to the `FocusableButton` (Add Game).
- D-pad Up from the `FocusableButton` moves focus back to the `PickerButton`.
- D-pad Up from the `PickerButton` moves focus back to the `FocusableTextField`.
- Pressing A on the focused `PickerButton` opens the `GamepadFileBrowser` dialog.

### 4. Scan Directory Tab — PickerButton Focus Traversal

**Problem**: In the "Scan Directory" tab, the "Add Directory" button (a `PickerButton`) cannot be reached via directional focus traversal. This prevents users from adding directories without switching to mouse/keyboard.

**User story**: As a user on the Scan Directory tab with a gamepad, I can navigate to and activate the Add Directory button.

**Acceptance criteria**:
- D-pad Down from the top of the tab content moves focus to the "Add Directory" `PickerButton`.
- D-pad Down from the `PickerButton` moves focus into the `ManageDirectoriesSection` list (if directories exist) or to the "Start Scan" button.
- D-pad Up from below returns focus to the `PickerButton`.
- Pressing A on the focused `PickerButton` opens the directory browser dialog.

### 5. Internationalization (i18n) of Hardcoded Strings

**Problem**: The following files contain numerous hardcoded English UI strings that are not extracted to the ARB localization files, making the app partially untranslated for Chinese users:
- `lib/presentation/widgets/manual_add_tab.dart`
- `lib/presentation/widgets/scan_directory_tab.dart`
- `lib/presentation/widgets/steam_games_tab.dart`
- `lib/presentation/widgets/gamepad_file_browser.dart`

**User story**: As a Chinese-language user, all visible text in the Add Game dialog and file browser appears in Chinese.

**Acceptance criteria**:
- All user-visible strings in the four listed files are replaced with `AppLocalizations.of(context)!.<key>` lookups (with null-safe fallback patterns where appropriate).
- Every new English string is added to `lib/l10n/app_en.arb` with a `@description` metadata entry.
- Every new English string has a corresponding Chinese translation in `lib/l10n/app_zh.arb`.
- `flutter gen-l10n` runs successfully and generates updated localization code.
- The app displays Chinese text when the system locale is set to Chinese.

## Technical Architecture

- **Frontend**: Flutter desktop (Linux primary, Windows/macOS secondary)
- **State Management**: BLoC pattern with `flutter_bloc`
- **Navigation**: GoRouter with `FocusScopeNode` containers for TopBar, Content, and BottomNav
- **Focus System**: Flutter native `FocusScope` architecture with `FocusTraversalService` handling cross-scope wrapping and row/grid navigation
- **Localization**: Flutter `gen-l10n` with ARB files (`app_en.arb`, `app_zh.arb`)
- **DI**: `get_it` with manual registration in `lib/app/di.dart`

### Key Patterns to Preserve
- `always_use_package_imports` — no relative imports
- `require_trailing_commas` enforced
- Focus widgets must use state-level `FocusNode` fields with proper `dispose()`
- Dialog content wrapped in `FocusScope` for automatic focus trapping
- All interactive widgets use `Focus` or `FocusableButton`/`FocusableTextField`/`PickerButton`
- Sound effects via `SoundService.instance` on focus changes and selections

## Sprint Breakdown

### Sprint 1: Fix GamepadFileBrowser A-Key and B-Key Actions
- **Scope**: Fix activation and cancellation inside `GamepadFileBrowser`
- **Dependencies**: None
- **Delivers**: A working file browser dialog that can be fully operated with gamepad A and B buttons
- **Files to modify**:
  - `lib/presentation/widgets/gamepad_file_browser.dart` (primary)
  - `lib/presentation/navigation/focus_traversal.dart` (may need cancel handling adjustment)
- **Acceptance criteria**:
  1. Gamepad A/Enter on a file item selects the file and invokes `onSelected`.
  2. Gamepad A/Enter on a directory item opens that directory.
  3. Gamepad B/Escape closes the `GamepadFileBrowser` dialog from any focused element.
  4. No `ActivateIntent not handled` exceptions in debug logs during file browser usage.
  5. All existing tests pass (`flutter test`).

### Sprint 2: Fix Focus Traversal for PickerButton Widgets
- **Scope**: Fix directional focus traversal to `PickerButton` widgets in Manual Add and Scan Directory tabs
- **Dependencies**: Sprint 1 (to verify browser opens from the fixed buttons)
- **Delivers**: Gamepad-navigable Add Game dialog with full traversal through all interactive elements
- **Files to modify**:
  - `lib/presentation/widgets/picker_button.dart` (primary — fix focus node architecture)
  - `lib/presentation/widgets/manual_add_tab.dart` (verify traversal order)
  - `lib/presentation/widgets/scan_directory_tab.dart` (verify traversal order)
- **Acceptance criteria**:
  1. In Manual Add tab: D-pad Up/Down navigates between Name input → Browse button → Add Game button.
  2. In Scan Directory tab: D-pad Up/Down navigates between Add Directory button → directory list → Start Scan button.
  3. Pressing A on a focused `PickerButton` opens the appropriate file browser.
  4. Focus visual feedback (border/background) correctly appears on `PickerButton` when focused.
  5. All existing tests pass.

### Sprint 3: Extract and Localize All Hardcoded Strings
- **Scope**: Extract every hardcoded English string from the four target files into ARB files with English and Chinese translations
- **Dependencies**: Sprint 1 and Sprint 2 (strings in those files may shift slightly)
- **Delivers**: Fully bilingual Add Game dialog and file browser
- **Files to modify**:
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_zh.arb`
  - `lib/presentation/widgets/manual_add_tab.dart`
  - `lib/presentation/widgets/scan_directory_tab.dart`
  - `lib/presentation/widgets/steam_games_tab.dart`
  - `lib/presentation/widgets/gamepad_file_browser.dart`
- **Acceptance criteria**:
  1. Zero hardcoded English user-facing strings remain in the four widget files.
  2. `app_en.arb` contains all new keys with proper `@description` metadata.
  3. `app_zh.arb` contains accurate Chinese translations for all new keys.
  4. `flutter gen-l10n` completes without errors.
  5. Running the app in Chinese locale (`zh`) displays all text in Chinese.
  6. Running the app in English locale (`en`) displays all text in English.
  7. All existing tests pass.

## Out of Scope

- Adding new languages beyond English and Chinese.
- Refactoring the broader focus architecture beyond the specific bugs listed.
- Adding new UI features, animations, or pages.
- Changing the gamepad input mapping (A/B/X/Y assignments).
- Modifying the `FocusTraversalService` API surface beyond minimal fixes needed for the B-key cancel behavior.
- Rewriting existing tests or adding comprehensive new test suites (existing 370 tests must pass, but new tests are optional).

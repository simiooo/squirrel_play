# Product Specification: Squirrel Play — Gamepad & Focus UI Bug Fixes

## Overview

Squirrel Play is a Steam Big Picture-inspired game management Flutter app built for couch gaming with full gamepad support. This specification addresses **5 critical gamepad and focus-traversal bugs** that degrade the controller-driven UX across the bottom navigation hints, modal dialogs, routing behavior, and vertical focus movement between the top bar and content areas.

All fixes are interrelated to the **gamepad navigation and focus system**, so they are bundled into a single sprint. The goal is to make the app feel fully navigable by controller without focus getting lost, escaping modals, or leaving ugly/uninformative UI on screen.

---

## Core Features

### Fix 1: Redesign Bottom Gamepad Hint Bar
**Problem:** The bottom hint bar is visually unappealing, button icons are not properly circular, colors clash with the dark theme, and it displays too many buttons (A, B, X, Y, Start). The user wants a minimal, right-aligned bar showing only the two essential actions: **Select (A)** and **Back (B)**.

**Requirements:**
- Reduce displayed hints to **only A (Select) and B (Back)** for all non-dialog contexts.
- Align the hint bar content to the **right** instead of center.
- Ensure the `GamepadButtonIcon` renders as a **perfect circle** for A/B buttons with a clean, subtle color treatment that matches the dark theme (avoid jarring default colors).
- Keep the bar excluded from focus traversal.

**Relevant files:**
- `lib/presentation/widgets/gamepad_nav_bar.dart` — layout and alignment
- `lib/presentation/widgets/gamepad_button_icon.dart` — button icon shape/colors
- `lib/presentation/navigation/gamepad_hint_provider.dart` — filter hints to A+B only

**Acceptance criteria:**
- [ ] Only A and B hints appear in the bottom bar on home, library, settings, and game-detail pages.
- [ ] Hint bar content is right-aligned with proper padding.
- [ ] A/B button icons are circular, sized consistently, and use colors that harmonize with `AppColors`.
- [ ] Dialog contexts still show Confirm/Cancel hints as before.

---

### Fix 2: Trap & Auto-Focus Gamepad Inside Modals
**Problem:** When a modal/dialog is open, the gamepad can move focus to elements *outside* the dialog (e.g., top bar buttons or page content behind the modal). Additionally, some dialogs do not automatically focus their first focusable element, and internal dialog focus traversal is broken.

**Requirements:**
- When **any** dialog opens, immediately enter `FocusTraversalService` dialog mode with the complete list of focusable nodes inside that dialog.
- When the dialog closes, always exit dialog mode and restore focus to the trigger node.
- Ensure that `FocusTraversalService._moveFocusInDialog` works correctly for up/down/left/right within the dialog node list.
- Wrap dialogs with a `FocusScope` or equivalent mechanism so that Flutter's built-in focus system also prevents escaping the modal.
- Ensure dialogs that currently **do not** call `enterDialogMode` are updated.

**Relevant files:**
- `lib/presentation/navigation/focus_traversal.dart` — dialog mode logic, `_moveFocusInDialog`, `_handleCancel`
- `lib/presentation/widgets/add_game_dialog.dart` — already enters dialog mode; verify it covers tab content focus nodes
- `lib/presentation/widgets/delete_game_dialog.dart` — already enters dialog mode; verify behavior
- `lib/presentation/widgets/api_key_dialog.dart` — **missing** dialog mode entry/exit
- `lib/presentation/widgets/metadata_search_dialog.dart` — **missing** dialog mode entry/exit
- `lib/presentation/widgets/focusable_text_field.dart` — may need focus registration awareness if used inside dialogs

**Acceptance criteria:**
- [ ] Opening any dialog (Add Game, Delete Game, API Key, Metadata Search) auto-focuses the first interactive element inside it.
- [ ] Gamepad D-pad/stick navigation cannot move focus outside the dialog while it is open.
- [ ] Pressing B (Cancel) or Escape closes the dialog and returns focus to the element that opened it.
- [ ] Dialog focus history does not leak into the main page focus history.

---

### Fix 3: Map Gamepad B Button to Router Back (with Guard on Top Route)
**Problem:** Currently, the B button calls `FocusTraversalService.goBack()`, which pops focus history rather than the navigation stack. The user expects B to act like a **router back button**, and it should do **nothing** if already on the top-level route (`/`).

**Requirements:**
- Change `_handleCancel` in `FocusTraversalService` so that when **not** in dialog mode, it attempts a **GoRouter pop/back** instead of focus-history back.
- Use `GoRouter.of(context).canPop()` (or equivalent GoRouter API) to check if back navigation is possible.
- If the current route is `/` (or any route where `canPop` is false), the B button should be a no-op (do not navigate).
- If in dialog mode, B should continue to close the dialog (existing behavior).

**Relevant files:**
- `lib/presentation/navigation/focus_traversal.dart` — `_handleCancel` and `_onGamepadAction`
- `lib/app/router.dart` — may need helper or navigator key access for pop checks

**Acceptance criteria:**
- [ ] Pressing B on `/library` or `/settings` navigates back to the previous route.
- [ ] Pressing B on `/` does nothing (no crash, no navigation, no focus loss).
- [ ] Pressing B inside a dialog closes the dialog.
- [ ] Keyboard Escape mirrors the same behavior.

---

### Fix 4: Preserve Focus in Empty Library / Empty Home State
**Problem:** On the home page (or library page) when the game library is empty, pressing down on the D-pad/ stick to move from the top bar into the content area causes the focus highlight to **disappear completely** because there are no registered content focus nodes to land on.

**Requirements:**
- Ensure that empty-state widgets register their CTA button(s) as **content nodes** with `FocusTraversalService`.
- When focus moves down from the top bar and the content area is empty, it should land on the first available empty-state button.
- Conversely, moving up from an empty-state button should return focus to the top bar (handled by existing wrap logic if nodes are registered).

**Relevant files:**
- `lib/presentation/widgets/home/empty_home_state.dart` — register `_addGameFocusNode` and `_scanDirectoryFocusNode` as content nodes
- `lib/presentation/widgets/empty_state_widget.dart` — register `_buttonFocusNode` as content node
- `lib/presentation/widgets/enhanced_empty_state.dart` — register primary/secondary focus nodes as content nodes
- `lib/presentation/pages/library_page.dart` — verify EmptyStateWidget usage
- `lib/presentation/navigation/focus_traversal.dart` — verify `_focusFirstAvailableNode` and wrapping behavior

**Acceptance criteria:**
- [ ] On an empty home page, pressing down from the top bar focuses the "Add your first game" button.
- [ ] On an empty library page, pressing down from the top bar focuses the "Add your first game" button in the empty state.
- [ ] Focus style (border/background) is visible on the empty-state buttons when focused via gamepad.

---

### Fix 5: Enable Vertical Focus Return from Content Area to Top Bar
**Problem:** When the user navigates down from the top bar into the content area (e.g., a game grid or card row), pressing **up** does **not** return focus to the top bar. This breaks bidirectional Y-axis navigation.

**Root cause:** In `FocusTraversalService.moveFocus()`, grid and row navigation handles arrow keys and returns early. When the user is in the first row of a grid and presses "up", the grid logic does nothing (bounds check fails), but the function has already returned, so the fallback `wrapToTopBar()` code never executes.

**Requirements:**
- Modify `moveFocus` so that when the current node is inside a **grid** and direction is `up`, if there is no row above, it calls `wrapToTopBar()` instead of silently doing nothing.
- Similarly, when inside a **row** (horizontal card row) and direction is `up`, wrap to top bar.
- Ensure `wrapToTopBar()` focuses the most recently focused top-bar node, or falls back to the first top-bar node.
- Verify the inverse: moving down from the top bar correctly wraps to content (this is already implemented but should be regression-tested).

**Relevant files:**
- `lib/presentation/navigation/focus_traversal.dart` — `moveFocus()`, `_moveFocusInGrid()`, `wrapToTopBar()`
- `lib/presentation/widgets/top_bar.dart` — ensure top bar nodes are registered
- `lib/presentation/widgets/app_shell.dart` — ensure content container is registered
- `lib/presentation/widgets/game_grid.dart` — grid focus node registration
- `lib/presentation/widgets/home/game_card_row.dart` — row focus node registration

**Acceptance criteria:**
- [ ] On the library page with games, pressing down from the top bar focuses the first game in the grid.
- [ ] Pressing up from the first row of the game grid returns focus to the top bar.
- [ ] On the home page with games, pressing down from the top bar focuses the first card row header or card.
- [ ] Pressing up from a card row returns focus to the top bar.
- [ ] Sound effect (`playFocusMove`) plays during both wrap-to-content and wrap-to-top-bar transitions.

---

## AI Integration
*Not applicable for this bug-fix sprint.*

---

## Technical Architecture

- **Frontend:** Flutter (desktop Linux target)
- **State Management:** BLoC pattern with `flutter_bloc`
- **Navigation:** `go_router` with `ShellRoute` for persistent shell UI
- **Focus System:** Custom `FocusTraversalService` singleton that bridges gamepad events (`gamepads` package) with Flutter `FocusNode`s
- **Key Patterns:**
  - All interactive widgets register/unregister `FocusNode`s with `FocusTraversalService`
  - Dialogs use `enterDialogMode` / `exitDialogMode` to trap focus
  - `FocusTraversalService` is initialized in `main.dart` or app startup

---

## Visual Design Direction

- Maintain the existing **dark, Big Picture-style aesthetic** (`AppColors.background`, `AppColors.surface`, `AppColors.primaryAccent`)
- Bottom bar should feel like a **subtle, right-aligned HUD** rather than a heavy footer
- Button hints should use **small, circular badges** with clean typography
- No new color palette introductions; reuse existing design tokens

---

## Sprint Breakdown

### Sprint 1: Gamepad & Focus UI Fixes
- **Scope:** Address all 5 reported bugs in a cohesive pass over the focus traversal and gamepad hint systems.
- **Dependencies:** None (all code exists; this is refinement).
- **Delivers:** A fully controller-navigable app where modals trap focus, the bottom bar is minimal and right-aligned, B button navigates back correctly, and vertical focus movement between top bar and content works bidirectionally including in empty states.
- **Acceptance criteria:**
  1. [ ] Bottom bar shows **only A and B hints**, right-aligned, with circular button icons.
  2. [ ] All dialogs trap focus; gamepad cannot escape modals; B closes dialogs.
  3. [ ] B button performs router back navigation; does nothing on `/`.
  4. [ ] Empty home/library states receive focus when moving down from the top bar.
  5. [ ] Moving up from content grids/card rows returns focus to the top bar.
  6. [ ] All existing tests pass (`flutter test`).
  7. [ ] No analyzer warnings (`flutter analyze`).
  8. [ ] Code generation is up to date (`flutter pub run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n` if localization keys are added).

---

## Out of Scope

- New pages or features (e.g., new settings, new game details page)
- Changing the underlying gamepad detection/library (`gamepads` package)
- Redesigning the top bar, game cards, or page layouts beyond focus behavior
- Adding haptic feedback or new sound effects
- Internationalization of *new* strings (if any new keys are needed, they should be added to both ARB files and code-generated)

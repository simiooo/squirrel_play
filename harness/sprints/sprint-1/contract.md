# Sprint Contract: Sprint 1 — Gamepad & Focus UI Fixes

## Sprint Goal
Fix 5 critical gamepad navigation and focus-traversal bugs so the app is fully controller-navigable: bottom hint bar is minimal and right-aligned, modals trap focus, B button performs router back navigation, empty states receive focus, and vertical focus movement between top bar and content works bidirectionally.

## Deliverables & Success Criteria

### 1. Redesign Bottom Gamepad Hint Bar
- Only **A (Select)** and **B (Back)** hints appear in the bottom bar on home, library, settings, and game-detail pages.
- Hint bar content is **right-aligned** with proper padding.
- A/B button icons are **perfect circles**, sized consistently, and use colors that harmonize with `AppColors`.
- Dialog contexts still show Confirm/Cancel hints as before.

### 2. Trap & Auto-Focus Gamepad Inside Modals
- Opening any dialog (Add Game, Delete Game, API Key, Metadata Search) **auto-focuses the first interactive element** inside it.
- Gamepad D-pad/stick navigation **cannot move focus outside** the dialog while it is open.
- Pressing **B (Cancel)** or **Escape** closes the dialog and returns focus to the element that opened it.
- Dialog focus history does not leak into the main page focus history.

### 3. Map Gamepad B Button to Router Back (with Guard on Top Route)
- Pressing B on `/library` or `/settings` **navigates back** to the previous route.
- Pressing B on `/` **does nothing** (no crash, no navigation, no focus loss).
- Pressing B inside a dialog **closes the dialog**.
- Keyboard **Escape** mirrors the same behavior.

### 4. Preserve Focus in Empty Library / Empty Home State
- On an empty home page, pressing **down** from the top bar focuses the "Add your first game" button.
- On an empty library page, pressing **down** from the top bar focuses the "Add your first game" button in the empty state.
- Focus style (border/background) is **visible** on the empty-state buttons when focused via gamepad.

### 5. Enable Vertical Focus Return from Content Area to Top Bar
- On the library page with games, pressing **down** from the top bar focuses the first game in the grid; pressing **up** from the first row of the game grid returns focus to the top bar.
- On the home page with games, pressing **down** from the top bar focuses the first card row header or card; pressing **up** from a card row returns focus to the top bar.
- **Sound effect** (`playFocusMove`) plays during both wrap-to-content and wrap-to-top-bar transitions.

## Testing & Verification Approach

1. **Automated tests:** Run `flutter test` — all existing tests must pass.
2. **Static analysis:** Run `flutter analyze` — zero warnings.
3. **Code generation:** Run `flutter pub run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n` if localization keys are added; build must succeed with no stale generated files.
4. **Manual testing (evaluator):**
   - Launch app on desktop (`flutter run -d linux`) and navigate with a connected controller or keyboard arrow keys.
   - Verify each of the 5 deliverables' success criteria on home, library, settings, and game-detail pages, as well as inside each dialog type.
   - Confirm the bottom hint bar updates correctly across page transitions and dialog open/close.

## Risks & Dependencies

- **Risk:** Changes to `FocusTraversalService` core logic (`moveFocus`, `_handleCancel`) can regress existing focus behavior on other pages. Mitigation: run full test suite and manually test all major pages.
- **Risk:** Dialogs share a common pattern but are implemented in separate widgets; one may be missed. Mitigation: explicit checklist covers Add Game, Delete Game, API Key, and Metadata Search dialogs.
- **Dependencies:** None. All code exists; this is a refinement sprint.

# Contract Review: Sprint 1

## Assessment: APPROVED

## Scope Coverage

The contract is well-aligned with **Sprint 1: Core Cleanup — Remove Legacy Dialog Mode** from the spec. It covers:

- Removing all `enterDialogMode()` / `exitDialogMode()` calls from dialogs and file browser ✅
- Stripping redundant dialog mode state from `FocusTraversalService` ✅
- Replacing explicit dialog mode tracking with focus-tree inspection ✅
- Preserving dialog focus trapping and Escape-key behavior ✅
- Maintaining test/analyzer hygiene (370 tests, no warnings) ✅

The contract correctly does **not** include Sprint 2 items (Settings button cross-scope navigation, file browser polish), keeping the scope tightly bounded.

## Success Criteria Review

- **SC1** (No `enterDialogMode`/`exitDialogMode` calls): Specific and measurable via grep. ✅ Adequate.
- **SC2** (No dialog mode state fields in `FocusTraversalService`): Measurable via code inspection. ✅ Adequate.
- **SC3** (Focus-tree inspection for dialog detection): Specific implementation guidance provided; measurable via code review and functional testing. ✅ Adequate.
- **SC4** (Dialogs still trap focus): Requires manual/UI testing; reasonable for focus behavior. ✅ Adequate.
- **SC5** (Escape key closes dialogs): Testable per-dialog. ✅ Adequate.
- **SC6** (Focus restoration on dialog close): Good addition not explicitly listed in the spec's success criteria, but covers a real risk area. ✅ Adequate.
- **SC7** (`gamepad_hint_provider.dart` updated): Excellent catch — this file calls `isInDialogMode()` and would break without explicit handling. ✅ Adequate.
- **SC8** (370 tests pass, analyzer clean): Unambiguous. ✅ Adequate.

## Suggested Changes

None blocking. Two minor observations for the Generator to be aware of during implementation:

1. **`MetadataSearchDialog` is dead code**: It has no static `show()` method and is never instantiated anywhere in the codebase. SC6's claim that "Each dialog's `show()` static method (or equivalent) already captures... focus" is technically inaccurate for this file. However, since it's dead code and `showDialog` itself restores focus automatically, this has no runtime impact. The contract's instructions for this file are still correct.

2. **`debugLabel` heuristic fragility**: The proposed `_isFocusInsideDialog()` relies on `debugLabel` strings (`ModalScope`, `Dialog`). These are Flutter internals that could change between framework versions. That said, this is consistent with the existing `_isOnNonInteractiveScope` pattern already in the codebase, so it's acceptable for this refactoring.

## Test Plan Preview

I will verify this sprint by:

1. Running `grep -rn "enterDialogMode\|exitDialogMode" lib/` — must return zero matches.
2. Inspecting `FocusTraversalService` to confirm `_isInDialogMode`, `_dialogTriggerNode`, `_dialogCancelCallback`, and the public `isInDialogMode()` method are gone.
3. Confirming `_isFocusInsideDialog()` (or equivalent) exists and is used in `_handleKeyEvent`, `_handleCancel`, `_addToHistory`, and `moveFocus`.
4. Verifying `gamepad_hint_provider.dart` no longer references `isInDialogMode()`.
5. Running `flutter analyze` — must produce no warnings/errors.
6. Running `flutter test` — all 370 tests must pass.
7. If UI access is available, manually opening each dialog to confirm arrow-key trapping and Escape-to-close behavior.

---

The contract is clear, measurable, achievable, and aligned with the spec. Approved for implementation.

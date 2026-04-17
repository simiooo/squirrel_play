# Handoff: Sprint 8

## Status: Ready for QA

## What to Test

### 1. Manual Add Tab File Picker
1. Open the Add Game dialog (click "Add Game" in top bar or press A on focused Add Game button)
2. Ensure you're on the "Manual Add" tab
3. **Verify**: The "Browse..." button with a file icon is visible immediately (without focusing it)
4. **Verify**: The button has a visible background (not transparent) - should be slightly lighter than the file path display container next to it
5. Navigate to the button using D-pad/arrow keys
6. **Verify**: A full border highlight (orange) appears around the button when focused
7. Press A or Enter while focused
8. **Verify**: The system file picker dialog opens

### 2. Scan Directory Tab Directory Picker
1. Open the Add Game dialog
2. Switch to the "Scan Directory" tab
3. **Verify**: The "Add Directory" button with a folder icon is visible immediately
4. **Verify**: The button has a visible background with border definition
5. Navigate to the button using D-pad/arrow keys
6. **Verify**: A full border highlight (orange) appears around the button when focused
7. Press A or Enter while focused
8. **Verify**: The system directory picker dialog opens

### 3. Visual Consistency
1. **Verify**: Both picker buttons use the same visual styling (background color, border, icon size)
2. **Verify**: Both buttons show the same focus indicator style (full border, not just bottom accent)
3. **Verify**: The unfocused state provides clear contrast against the dialog background

### 4. Gamepad Navigation
1. **Verify**: Both buttons are reachable via D-pad navigation
2. **Verify**: Focus moves smoothly between the picker button and other elements in the tab
3. **Verify**: Sound effects play on focus (if sound files are configured)

### 5. Accessibility
1. Enable screen reader (if testing on supported platform)
2. **Verify**: Button labels are announced correctly ("Browse..." and "Add Directory")

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

The app will start on Linux desktop. Navigate to the Add Game dialog to test the picker buttons.

## Files Modified

1. `lib/presentation/widgets/picker_button.dart` (new file)
2. `lib/presentation/widgets/manual_add_tab.dart` (updated to use PickerButton)
3. `lib/presentation/widgets/scan_directory_tab.dart` (updated to use PickerButton)

## Known Gaps

None. All contract requirements and review feedback have been implemented.

## Notes for Evaluator

- The PickerButton uses `AppColors.surfaceElevated` (#2A2A30) for the unfocused background, which is slightly lighter than the `AppColors.surface` (#1A1A1E) used by the file path display container. This provides the contrast hierarchy requested in the review.
- The focus indicator is a full 2px border using `AppColors.primaryAccent` (orange), which is more prominent than the bottom-only accent used by FocusableButton.
- Both picker buttons maintain their existing focus nodes, so gamepad navigation behavior should be unchanged from before.

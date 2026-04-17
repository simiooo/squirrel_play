# Sprint Contract: Fix File/Folder Picker Visibility in Add Game Dialog

## Scope
Investigate and fix the file picker button in ManualAddTab and directory picker button in ScanDirectoryTab that are not clearly visible when unfocused. Ensure the buttons are prominently styled, properly accessible via gamepad navigation, and provide clear visual feedback.

## Investigation Findings

### ManualAddTab File Picker Button (lines 162-166)
**Issues identified:**
1. **Invisible when unfocused**: Uses `FocusableButton` without `isPrimary: true`, resulting in `Colors.transparent` background when unfocused
2. **No icon**: Only text label "Select .exe" - not immediately recognizable as a picker action
3. **Blends with background**: Transparent background + `AppColors.textSecondary` text makes it nearly invisible against the dark dialog background
4. **Small visual footprint**: Compact button next to the file path display lacks prominence

### ScanDirectoryTab Directory Picker Button (lines 278-283)
**Issues identified:**
1. **No icon**: Uses `isPrimary: true` so it's visible, but lacks an icon for quick recognition
2. **Could be more prominent**: Button is functional but could benefit from enhanced visual styling

### FocusableButton Design Issue
**Root cause**: When `isPrimary: false` (default), the button has:
- `backgroundColor: Colors.transparent` when unfocused
- `textColor: AppColors.textSecondary` when unfocused
- No border or outline to indicate interactivity

This design pattern makes non-primary buttons essentially invisible until focused.

## Implementation Plan

### 1. Create PickerButton Widget
Create a new reusable `PickerButton` widget in `lib/presentation/widgets/picker_button.dart`:
- Always visible with `AppColors.surface` background (not transparent)
- Border outline using `AppColors.surfaceElevated` for definition
- Icon + text label pattern (folder icon for directory, file icon for executable)
- Minimum 48x48px touch target
- Clear focus indicator with `AppColors.primaryAccent` glow/border
- Semantic labels for accessibility

### 2. Update ManualAddTab
Replace the file picker `FocusableButton` with new `PickerButton`:
- Use `Icons.file_open` or similar file icon
- Label: "Browse..." or "Select File" (clearer than "Select .exe")
- Keep existing `_filePickerFocusNode` for gamepad navigation
- Add visual feedback when file is selected (already partially implemented via path display)

### 3. Update ScanDirectoryTab
Replace the directory picker `FocusableButton` with new `PickerButton`:
- Use `Icons.folder_open` icon
- Label: "Add Directory" (keep existing label)
- Keep existing `_addDirectoryFocusNode` for gamepad navigation
- Ensure button is prominent at top of tab

### 4. Consistency Improvements
- Both picker buttons should use consistent styling via `PickerButton`
- Both should have icons for quick visual recognition
- Both should maintain proper focus traversal order

## Success Criteria

| Criterion | Verification Method |
|-----------|---------------------|
| File picker button visible in ManualAddTab | Open Add Game dialog → Manual tab → verify button is visible without focusing it |
| Directory picker button visible in ScanDirectoryTab | Open Add Game dialog → Scan Directory tab → verify button is visible without focusing it |
| File picker has clear icon | Verify `Icons.file_open` or similar icon appears left of label |
| Directory picker has clear icon | Verify `Icons.folder_open` icon appears left of label |
| File picker shows focus indicator | Navigate to button with gamepad/keyboard → verify glow/border appears |
| Directory picker shows focus indicator | Navigate to button with gamepad/keyboard → verify glow/border appears |
| File picker opens system dialog on A/Enter press | Press A/Enter while focused → verify file picker dialog opens |
| Directory picker opens system dialog on A/Enter press | Press A/Enter while focused → verify directory picker dialog opens |
| Minimum touch target 48x48px | Verify button constraints meet minimum size |
| Consistent styling between both pickers | Both use `PickerButton` with same visual treatment |
| Semantic labels for accessibility | Verify `Semantics` widget with proper labels |

## Out of Scope for This Sprint
- Changing the file picker library or dialog behavior
- Adding drag-and-drop file selection
- Modifying the actual file scanning logic
- Changing the form validation behavior
- Adding keyboard shortcuts (Ctrl+O, etc.)
- Modifying other buttons in the Add Game dialog (Confirm, Cancel, etc.)

## Files to Modify
1. `lib/presentation/widgets/picker_button.dart` (new file)
2. `lib/presentation/widgets/manual_add_tab.dart`
3. `lib/presentation/widgets/scan_directory_tab.dart`

## Files to Reference (No Changes)
- `lib/presentation/widgets/focusable_button.dart` (reference for focus handling)
- `lib/core/theme/design_tokens.dart` (color tokens)

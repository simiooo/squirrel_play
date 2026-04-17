# Handoff: Sprint 13

## Status: Ready for QA

## What to Test on the Settings Page

### Navigation Flow
1. Navigate to Settings page from Home
2. Use D-pad/arrow keys to navigate through all 10 controls in order:
   - Back button → English → Chinese → API Key → Save → Clear → Volume → Mute → Test Sound → Test Gamepad
3. Verify focus moves smoothly between controls
4. Press B button or Escape to go back (should work from any focused control)

### FocusableListTile (Language Options)
**What to verify:**
- Focus English or Chinese option
- **Visual**: 2px orange (#FF6B2B) bottom border appears
- **Visual**: Background changes to surfaceElevated (#2A2A30)
- **Animation**: Focus indicator appears within 200ms
- **Sound**: Focus move sound plays (if not muted)
- **Action**: Press A/Enter to select - checkmark appears, language changes
- **Sound**: Select sound plays on selection
- **Animation**: Focus indicator fades out in 150ms when moving away

### FocusableSwitch (Mute Toggle)
**What to verify:**
- Focus the Mute switch
- **Visual**: 2px orange border on ALL 4 sides appears
- **Visual**: Background changes to surfaceElevated
- **Visual**: Switch scales to 1.02x
- **Animation**: All effects happen within 200ms
- **Sound**: Focus move sound plays
- **Action**: Press A/Enter to toggle - switch animates
- **Sound**: Select sound plays on toggle
- **Function**: Sound is muted/unmuted immediately

### FocusableSlider (Volume Control)
**What to verify:**
- Focus the Volume slider
- **Visual**: 2px orange border on all 4 sides appears
- **Visual**: Background changes to surfaceElevated
- **Visual**: Percentage text becomes larger and brighter
- **Animation**: All effects within 200ms
- **Sound**: Focus move sound plays
- **Gamepad**: Press D-pad Left - volume decreases by 10%
- **Gamepad**: Press D-pad Right - volume increases by 10%
- **Gamepad**: Press D-pad Up/Down - focus moves to adjacent control (not trapped)
- **Function**: Volume changes immediately, affects all sounds

### FocusableTextField (API Key Input)
**What to verify:**
- Focus the API Key input field
- **Visual**: 2px orange border appears around the entire field
- **Visual**: Background changes to surfaceElevated when focused
- **Animation**: Border appears within 200ms, fades in 150ms
- **Sound**: Focus move sound plays when focus enters the field
- **Function**: Can type, save, and clear API key as before
- **Lifecycle**: Focus node is automatically registered/unregistered with FocusTraversalService by the widget

### Existing Controls (Regression Test)
**Verify these still work:**
- Back button: Returns to home page
- Save/Clear buttons: Save and clear API key
- Test Sound button: Plays select sound
- Test Gamepad button: Navigates to gamepad test page

## Running the Application

```bash
export PATH="/home/simooo/flutter/bin:$PATH"
flutter run -d linux
```

The app will start on the Home page. Navigate to Settings using:
- Mouse: Click "Settings" in top bar
- Gamepad: Navigate to Settings button and press A

## Specific Focus Indicators to Verify

| Widget | Focus Indicator | Animation Duration |
|--------|-----------------|------------------|
| FocusableListTile | 2px bottom border (primaryAccent) + surfaceElevated background | 200ms in, 150ms out |
| FocusableSwitch | 2px full border (primaryAccent) + surfaceElevated background + 1.02 scale | 200ms in, 150ms out |
| FocusableSlider | 2px full border (primaryAccent) + surfaceElevated background + larger value text | 200ms in, 150ms out |
| FocusableTextField | 2px full border (primaryAccent) + surfaceElevated background around container | 200ms in, 150ms out |

## Known Gaps

None. All success criteria from the contract have been implemented.

## Files Modified/Created

### New Files
- `lib/presentation/widgets/focusable_list_tile.dart`
- `lib/presentation/widgets/focusable_switch.dart`
- `lib/presentation/widgets/focusable_slider.dart`
- `lib/presentation/widgets/focusable_text_field.dart`

### Modified Files
- `lib/presentation/pages/settings_page.dart` - Major refactor with new widgets and focus node registration
- `lib/l10n/app_en.arb` - Added 4 accessibility labels
- `lib/l10n/app_zh.arb` - Added 4 Chinese translations
- `lib/l10n/app_localizations.dart` - Auto-generated
- `lib/l10n/app_localizations_en.dart` - Auto-generated
- `lib/l10n/app_localizations_zh.dart` - Auto-generated

# Sprint 13 Contract: Focus Styles for Interactive Controls

## Summary
This sprint adds visible focus states to all interactive controls on the Settings page that currently lack gamepad-visible focus indicators. Specifically, we will create three new reusable focusable widgets (`FocusableListTile`, `FocusableSwitch`, `FocusableSlider`) that wrap standard Flutter Material controls with focus-aware styling using the existing design system tokens. The Settings page will be refactored to use these new widgets, making all controls fully navigable and visually identifiable when using a gamepad.

## Scope
- Create `FocusableListTile` widget with focus ring, background animation, and sound hooks
- Create `FocusableSwitch` widget with focus border, scale animation, and sound hooks
- Create `FocusableSlider` widget with focus border, enhanced value display, and gamepad value adjustment
- Refactor Settings page to use all three new focusable widgets
- Register **all 10** focus nodes with `FocusTraversalService` for D-pad navigation (4 new + 6 existing)
- Add visible focus styling to API key TextField
- Add i18n accessibility labels for new focusable controls
- Ensure all focus animations use existing design tokens (durations, curves, colors)

## Out of Scope
- Changes to other pages (Home, Library, Add Game dialog) - only Settings page is in scope
- New sound effect files - using existing SoundService hooks only
- Changes to FocusTraversalService core logic - only registration of nodes
- Gamepad button mapping changes
- Visual redesign of controls - only adding focus indicators to existing designs

## Success Criteria
1. **FocusableListTile Focus Indicator**: Given a focused `FocusableListTile` (language option), when focused, then a 2px `primaryAccent` bottom border and `surfaceElevated` background are visible within 200ms
2. **FocusableSwitch Focus Indicator**: Given a focused `FocusableSwitch` (mute toggle), when focused, then a `primaryAccent` border and `surfaceElevated` background appear within 200ms
3. **FocusableSwitch Toggle**: Given a focused `FocusableSwitch`, when the user presses A (or Enter), then the switch toggles and `playFocusSelect()` sound plays
4. **FocusableSlider Focus Indicator**: Given a focused `FocusableSlider`, when focused, then a 2px `primaryAccent` border around the slider perimeter appears within 200ms
5. **FocusableSlider Gamepad Adjustment**: Given a focused `FocusableSlider`, when the user presses D-pad left/right, then the slider value adjusts by one division step (0.1 for volume slider). D-pad up/down moves focus away from the slider.
6. **Focus Move Sound**: Given any settings control gaining focus, when the transition occurs, then `playFocusMove()` sound plays (if sound is not muted)
7. **Focus Select Sound**: Given any settings control being activated, when the user presses A, then `playFocusSelect()` sound plays (if sound is not muted)
8. **D-pad Navigation Order**: Given the Settings page, when navigating via gamepad D-pad, then all 10 controls are reachable in order: Back → English → Chinese → API Key Input → Save → Clear → Volume Slider → Mute Switch → Test Sound → Test Gamepad (top-to-bottom, left-to-right)
9. **Focus Out Animation**: Given all focusable settings widgets, when focus is lost, then the focus indicator fades out within 150ms
10. **No Regressions**: Given the existing Settings page functionality, when the refactor is complete, then all existing features (language switching, API key save/clear, volume adjustment, mute toggle, sound test, gamepad test navigation) continue to work correctly

## Technical Approach

### New Widgets (in `lib/presentation/widgets/`)

#### 1. FocusableListTile
Wraps `ListTile` with focus-aware styling:
- Constructor accepts `FocusNode`, `title`, `subtitle`, `leading`, `trailing`, `onTap`
- Uses `AnimatedContainer` for background color transition (`transparent` → `surfaceElevated`)
- Adds 2px bottom border in `primaryAccent` when focused (matches `FocusableButton` pattern)
- **Animation**: Uses `AppAnimationDurations.focusIn` (200ms) on focus in, `AppAnimationDurations.focusOut` (150ms) on focus out
- Calls `SoundService.instance.playFocusMove()` on focus gain
- Calls `SoundService.instance.playFocusSelect()` on tap
- Minimum 48px height for touch target
- **Border rationale**: Uses bottom-only border because ListTile is a wide horizontal element where a bottom underline provides clear focus indication without excessive visual weight

#### 2. FocusableSwitch
Wraps `Switch` with focus-aware styling:
- Constructor accepts `FocusNode`, `value`, `onChanged`, `title`, `subtitle`
- Uses `AnimatedContainer` for container styling with border
- Border: 2px `primaryAccent` on all 4 sides when focused, transparent when unfocused
- Background: `surfaceElevated` when focused, transparent when unfocused
- Scale animation: 1.0 → 1.02 on focus (200ms ease-out)
- Calls `SoundService.instance.playFocusMove()` on focus gain
- Calls `SoundService.instance.playFocusSelect()` when switch is toggled
- Row layout: title + switch aligned horizontally
- **Border rationale**: Uses full 4-sided border because switches are compact elements that benefit from a complete focus ring for visibility at 10-foot distance

#### 3. FocusableSlider
Wraps `Slider` with focus-aware styling and gamepad control:
- Constructor accepts `FocusNode`, `value`, `onChanged`, `min`, `max`, `divisions`, `label`, and optional `step` parameter
- `step` parameter: explicit step value for gamepad adjustment; defaults to `(max - min) / divisions` if not provided
- Container wrapper with focus border styling (2px `primaryAccent` on all 4 sides when focused)
- Value label styling changes on focus (larger, brighter text)
- Calls `SoundService.instance.playFocusMove()` on focus gain
- **Gamepad interaction**: 
  - D-pad **left/right** adjusts slider value by one step when focused
  - D-pad **up/down** moves focus away from the slider (standard vertical navigation)
  - Uses `Focus` widget with `onKeyEvent` handler that returns `KeyEventResult.handled` for left/right keys when focused, preventing `FocusTraversalService` from also processing them
- **Border rationale**: Uses full 4-sided border for consistency with FocusableSwitch and to clearly indicate the interactive region

### Settings Page Refactor (`lib/presentation/pages/settings_page.dart`)

#### State Management Changes
Add new `FocusNode` fields to `_SettingsPageContentState`:
- `_englishLanguageFocusNode` (new)
- `_chineseLanguageFocusNode` (new)
- `_muteSwitchFocusNode` (new)
- `_volumeSliderFocusNode` (new)

Existing FocusNodes that must also be registered:
- `_backButtonFocusNode` (existing)
- `_apiKeyFocusNode` (existing)
- `_saveKeyFocusNode` (existing)
- `_clearKeyFocusNode` (existing)
- `_testSoundFocusNode` (existing)
- `_testGamepadFocusNode` (existing)

#### Widget Replacements
1. **Language Selection**: Replace stock `ListTile` widgets in `_buildLanguageOption()` with `FocusableListTile`
2. **Mute Toggle**: Replace stock `ListTile` with embedded `Switch` in `_buildSoundSection()` with `FocusableSwitch`
3. **Volume Slider**: Replace stock `Slider` in `_buildSoundSection()` with `FocusableSlider`
4. **API Key TextField**: Add visible focus styling to the existing API key input - wrap with `Container` that shows 2px `primaryAccent` border when focused

#### Focus Traversal Integration
- Register **all 10** focus nodes with `FocusTraversalService.instance.registerContentNode()` in `initState`
- Unregister **all 10** focus nodes in `dispose`
- Ensure proper disposal order: unregister before dispose
- Expected registration order (matches visual top-to-bottom layout):
  1. `_backButtonFocusNode`
  2. `_englishLanguageFocusNode`
  3. `_chineseLanguageFocusNode`
  4. `_apiKeyFocusNode`
  5. `_saveKeyFocusNode`
  6. `_clearKeyFocusNode`
  7. `_volumeSliderFocusNode`
  8. `_muteSwitchFocusNode`
  9. `_testSoundFocusNode`
  10. `_testGamepadFocusNode`

### Design Token References
All widgets must use existing design tokens:
- Focus border color: `AppColors.primaryAccent` (#FF6B2B)
- Focus background: `AppColors.surfaceElevated` (#2A2A30)
- Focus-in duration: `AppAnimationDurations.focusIn` (200ms)
- Focus-out duration: `AppAnimationDurations.focusOut` (150ms)
- Focus-in curve: `AppAnimationCurves.focusIn` (easeOut)
- Focus-out curve: `AppAnimationCurves.focusOut` (easeIn)
- Spacing: `AppSpacing` constants
- Border radius: `AppRadii.medium` (8px)

### Sound Integration
All widgets use `SoundService.instance`:
- `playFocusMove()` on focus gain (debounced by SoundService)
- `playFocusSelect()` on activation/toggle

### i18n Keys Required
Complete list of new accessibility labels to add:
- `settings.sound.volumeHint` — Volume slider accessibility label
- `settings.sound.muteHint` — Mute switch accessibility label
- `settings.language.englishLabel` — English language option accessibility label
- `settings.language.chineseLabel` — Chinese language option accessibility label

## Files to Create

| File | Description |
|------|-------------|
| `lib/presentation/widgets/focusable_list_tile.dart` | Focus-aware ListTile wrapper with border animation and sound hooks |
| `lib/presentation/widgets/focusable_switch.dart` | Focus-aware Switch wrapper with border, scale animation, and sound hooks |
| `lib/presentation/widgets/focusable_slider.dart` | Focus-aware Slider wrapper with border, gamepad control, step parameter, and sound hooks |

## Files to Modify

| File | Changes |
|------|-------------|
| `lib/presentation/pages/settings_page.dart` | Replace stock ListTile/Switch/Slider with new focusable widgets; add 4 new FocusNode fields; register **all 10** focus nodes with FocusTraversalService; add focus styling to API key TextField |
| `lib/l10n/app_en.arb` | Add 4 accessibility hint strings for new controls |
| `lib/l10n/app_zh.arb` | Add Chinese translations for the 4 new accessibility strings |

## Dependencies

### Internal Dependencies
- `lib/core/theme/design_tokens.dart` - AppColors, AppAnimationDurations, AppAnimationCurves, AppSpacing, AppRadii
- `lib/data/services/sound_service.dart` - SoundService for audio feedback
- `lib/presentation/navigation/focus_traversal.dart` - FocusTraversalService for D-pad navigation registration
- `lib/presentation/widgets/focusable_button.dart` - Reference pattern for focus styling consistency

### External Dependencies
- `flutter/material.dart` - Core Material widgets (ListTile, Switch, Slider)
- `flutter/services.dart` - For keyboard/gamepad event handling in FocusableSlider
- `flutter_bloc/flutter_bloc.dart` - Already used in Settings page (no new dependency)

## Risk Areas

1. **Focus Traversal Order**: Adding new focus nodes may change the natural focus traversal order. Must verify D-pad navigation flows logically through all 10 controls after refactor.

2. **Slider Gamepad Control**: D-pad left/right adjusts slider value while up/down moves focus away. The slider's `onKeyEvent` must return `KeyEventResult.handled` for horizontal keys to prevent `FocusTraversalService` from also processing them.

3. **Animation Performance**: Three simultaneous animated properties (border, background, scale) on multiple widgets could impact performance on lower-end hardware. Keep animations simple and use `AnimatedContainer` for efficiency.

4. **Sound Debouncing**: Multiple rapid focus changes could queue many sounds. The SoundService already has debouncing for `playFocusMove()`, but verify it works correctly with the new widgets.

5. **Existing FocusNode Lifecycle**: The Settings page already has 6 FocusNodes. Adding 4 more increases the risk of memory leaks if not properly disposed. Must ensure all 10 nodes are unregistered from FocusTraversalService and disposed.

6. **i18n String Extraction**: New accessibility labels must be extracted to ARB files. Missing translations will cause runtime errors if the l10n delegate can't find the key.

7. **Visual Consistency**: The new widgets must match the existing `FocusableButton` visual language. Any deviation will create a jarring user experience. Note: `FocusableButton` currently uses hardcoded 150ms/100ms timings; this sprint uses design token values (200ms/150ms) which may differ slightly.

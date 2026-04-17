# Sound Design Specification

This document defines the sound design requirements for Squirrel Play. Sound effects enhance the gaming console feel and provide audio feedback for navigation and actions.

---

## File Format Requirements

### Required Format
- **Format**: FLAC or WAV
- **Sample Rate**: 44.1 kHz (CD quality)
- **Bit Depth**: 16-bit
- **Channels**: Mono or Stereo (Mono preferred for UI sounds)
- **Maximum Duration**: See per-sound specifications below

### Rationale
- FLAC provides lossless compression with instant playback
- WAV ensures instant playback without decoding overhead
- 44.1 kHz provides high-quality audio without excessive file size
- 16-bit is sufficient for UI sounds and widely compatible
- Mono reduces file size for positional sounds

---

## Naming Convention

Sound files use descriptive names based on their source/purpose:

```
assets/sounds/
├── jump-retro-video-game-sfx-jump-c-sound.flac  # Focus move (navigation)
├── select-sound.flac                            # Focus select/back (confirm/cancel)
└── transition-transition-whoosh-sound-sound.flac # Page transition
```

### Current Sound Mapping
| Sound Event | File | Purpose |
|-------------|------|---------|
| Focus Move | `jump-retro-video-game-sfx-jump-c-sound.flac` | Navigation between items |
| Focus Select | `select-sound.flac` | Confirm/activate action |
| Focus Back | `select-sound.flac` | Cancel/back action |
| Page Transition | `transition-transition-whoosh-sound-sound.flac` | Page/route change |
| Error | `select-sound.flac` | Fallback (no dedicated error sound yet) |

---

## Sound Events

### Focus Move
- **Filename**: `jump-retro-video-game-sfx-jump-c-sound.flac`
- **Max Duration**: 100ms
- **Description**: Retro-style jump sound
- **Trigger**: When focus moves between interactive elements (D-pad navigation)
- **Character**: Light, non-intrusive, mechanical feel
- **Volume**: Low (20-30% of max)
- **Fallback**: Silent (no error if file missing)

### Focus Select
- **Filename**: `select-sound.flac`
- **Max Duration**: 200ms
- **Description**: Satisfying confirmation sound
- **Trigger**: When user confirms/activates a focused element (A button, Enter)
- **Character**: Positive, rewarding tone
- **Volume**: Medium (40-50% of max)
- **Fallback**: Silent (no error if file missing)

### Focus Back
- **Filename**: `select-sound.flac`
- **Max Duration**: 150ms
- **Description**: Same as select (no dedicated back sound)
- **Trigger**: When user cancels or navigates back (B button, Escape)
- **Character**: Same as select
- **Volume**: Medium (40-50% of max)
- **Fallback**: Silent (no error if file missing)

### Page Transition
- **Filename**: `transition-transition-whoosh-sound-sound.flac`
- **Max Duration**: 300ms
- **Description**: Whoosh or sweep sound
- **Trigger**: When navigating between pages/routes
- **Character**: Airy, sweeping motion sound
- **Volume**: Low-Medium (30-40% of max)
- **Fallback**: Silent (no error if file missing)

### Error
- **Filename**: `select-sound.flac` (fallback)
- **Max Duration**: 300ms
- **Description**: Fallback to select sound (no dedicated error sound yet)
- **Trigger**: When an error occurs or invalid action attempted
- **Character**: Same as select
- **Volume**: Medium (40-50% of max)
- **Fallback**: Silent (no error if file missing)

---

## Directory Structure

```
assets/
└── sounds/
    ├── jump-retro-video-game-sfx-jump-c-sound.flac
    ├── select-sound.flac
    └── transition-transition-whoosh-sound-sound.flac
```

### pubspec.yaml Configuration

```yaml
flutter:
  assets:
    - assets/sounds/
```

The directory is registered as an asset folder, allowing all contained sound files to be loaded.

---

## Fallback Behavior

### Critical Requirement
The application **must function identically** with or without sound files present. Sound is purely additive and never required for core functionality.

### Implementation Pattern

```dart
class SoundService {
  Future<void> playFocusMove() async {
    try {
      // Attempt to play sound file
      // If file missing or error, silently continue
    } catch (_) {
      // Silent fallback - no error thrown
    }
  }
}
```

### Missing File Scenarios
1. **File not found**: Continue silently, log debug message
2. **Corrupted file**: Skip playback, log warning
3. **Permission denied**: Skip playback, log warning
4. **Audio system unavailable**: Skip all sound operations

---

## Volume Guidelines

### Master Volume
- Default: 50% of system volume
- User configurable in settings (Sprint 6)
- Range: 0% (mute) to 100%

### Per-Sound Volume Levels
These are relative to master volume:

| Sound | Relative Volume | Rationale |
|-------|-----------------|-----------|
| focus_move | 30% | Subtle, frequent |
| focus_select | 50% | Important feedback |
| focus_back | 50% | Important feedback |
| page_transition | 40% | Context change |
| error | 60% | Needs attention |

### Ducking
- No ducking required for UI sounds
- All sounds are short and non-overlapping
- If multiple sounds trigger simultaneously, prioritize:
  1. Error sounds
  2. Select/Back sounds
  3. Page transition sounds
  4. Focus move sounds

---

## Integration Notes

### Current Status (All Sprints Complete)
- Sound service fully implemented with `audioplayers` package
- Actual FLAC file playback working
- Volume control available in settings
- Error handling for missing files implemented

### Sound Files
- **focus_move** → `jump-retro-video-game-sfx-jump-c-sound.flac`
- **focus_select** → `select-sound.flac`
- **focus_back** → `select-sound.flac` (shared)
- **page_transition** → `transition-transition-whoosh-sound-sound.flac`
- **error** → `select-sound.flac` (fallback)

### Code Integration

```dart
// Example usage in a widget
void onFocusChanged(bool hasFocus) {
  if (hasFocus) {
    SoundService.instance.playFocusMove();
  }
}

void onActivate() {
  SoundService.instance.playFocusSelect();
}

void onCancel() {
  SoundService.instance.playFocusBack();
}
```

---

## Testing Without Sound Files

Since sound files are optional, testing should verify:

1. **App launches successfully** without any sound files present
2. **No exceptions thrown** when sound methods are called
3. **Debug logs printed** indicating sound would have played (Sprint 1)
4. **UI remains responsive** during sound operations

---

## Future Considerations

### Potential Additions (Post-v1)
- Game launch sound
- Scan complete sound
- Favorite toggle sound
- Background ambient audio
- Custom sound pack support

### Platform Differences
- Windows: Direct WAV playback via audioplayers
- Future platforms: May require format conversion

---

## Summary

| Aspect | Specification |
|--------|---------------|
| Format | FLAC/WAV, 44.1kHz, 16-bit |
| Location | `assets/sounds/` |
| Count | 3 sound files |
| Total Max Duration | ~600ms (all sounds) |
| Required | No - app works without sounds |
| Fallback | Silent operation |
| Integration Sprint | 2 (playback), 1 (interface) |

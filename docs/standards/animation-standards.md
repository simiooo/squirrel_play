# Animation Standards

This document defines all animation specifications for Squirrel Play. Consistent, polished animations are critical to the premium gaming console feel.

---

## Animation Philosophy

- **Purposeful**: Every animation guides the user's attention or provides feedback
- **Fast**: Animations should feel responsive, never sluggish
- **Consistent**: Same types of interactions use the same timing and curves
- **Smooth**: 60fps target on all supported hardware

---

## Focus Animations

### Card Focus In
Triggered when a game card receives focus.

| Property | Value |
|----------|-------|
| Duration | 200ms |
| Curve | easeOutCubic (`Curves.easeOutCubic`) |
| Scale | 1.0 → 1.08 |
| Elevation | Rest → Elevated |
| Border | Accent glow appears (2px, primaryAccent) |
| Shadow | Increases in size and opacity |

### Card Focus Out
Triggered when a game card loses focus.

| Property | Value |
|----------|-------|
| Duration | 150ms |
| Curve | easeInCubic (`Curves.easeInCubic`) |
| Scale | 1.08 → 1.0 |
| Elevation | Elevated → Rest |
| Border | Glow fades out |
| Shadow | Decreases to rest state |

### Button Focus In
Triggered when a button receives focus.

| Property | Value |
|----------|-------|
| Duration | 150ms |
| Curve | easeOut (`Curves.easeOut`) |
| Background | surface → surfaceElevated |
| Underline | 2px accent line appears at bottom |
| Scale | 1.0 → 1.02 (subtle) |

### Button Focus Out
Triggered when a button loses focus.

| Property | Value |
|----------|-------|
| Duration | 100ms |
| Curve | easeIn (`Curves.easeIn`) |
| Background | surfaceElevated → surface |
| Underline | Fades out |
| Scale | 1.02 → 1.0 |

---

## Page Transitions

### Page Enter
Triggered when a new page/route is pushed.

| Property | Value |
|----------|-------|
| Duration | 300ms |
| Curve | easeOutCubic (`Curves.easeOutCubic`) |
| Opacity | 0 → 1 |
| Offset Y | 16px → 0 (slight upward slide) |

### Page Exit
Triggered when a page/route is popped.

| Property | Value |
|----------|-------|
| Duration | 200ms |
| Curve | easeInCubic (`Curves.easeInCubic`) |
| Opacity | 1 → 0 |
| Offset Y | 0 → 16px (slight downward slide) |

---

## Background Crossfade

Triggered when the focused game changes and the background image updates.

| Property | Value |
|----------|-------|
| Duration | 500ms |
| Curve | easeInOut (`Curves.easeInOut`) |
| Effect | Crossfade between previous and new hero image |
| Fallback | Gradient placeholder if no hero image available |

---

## Micro-interactions

### Card Scroll
Triggered when a card row scrolls to reveal more cards.

| Property | Value |
|----------|-------|
| Duration | 250ms |
| Curve | easeOutCubic (`Curves.easeOutCubic`) |
| Token | `AppAnimationDurations.cardScroll` |
| Curve Token | `AppAnimationCurves.cardScroll` |
| Effect | Smooth horizontal scroll with subtle parallax |

### Loading Shimmer
Triggered while content is loading.

| Property | Value |
|----------|-------|
| Duration | 1500ms |
| Curve | linear (repeating) |
| Effect | Left-to-right gradient shimmer across skeleton cards |
| Repeat | Infinite until content loads |

### Dialog Open
Triggered when a dialog appears.

| Property | Value |
|----------|-------|
| Duration | 200ms |
| Curve | easeOutBack (`Curves.easeOutBack`) |
| Scale | 0.95 → 1.0 |
| Opacity | 0 → 1 |
| Overlay | Fades in simultaneously |

### Dialog Close
Triggered when a dialog is dismissed.

| Property | Value |
|----------|-------|
| Duration | 150ms |
| Curve | easeIn (`Curves.easeIn`) |
| Scale | 1.0 → 0.95 |
| Opacity | 1 → 0 |
| Overlay | Fades out simultaneously |

### Progress Bar
Triggered when scan progress updates.

| Property | Value |
|----------|-------|
| Duration | 300ms |
| Curve | easeInOut (`Curves.easeInOut`) |
| Token | `AppAnimationDurations.progressBar` |
| Curve Token | `AppAnimationCurves.progressBar` |
| Effect | Smooth width animation reflecting progress |

---

## Animation Curves Reference

| Curve Name | Flutter Constant | Usage |
|------------|------------------|-------|
| easeOut | `Curves.easeOut` | Button focus animations |
| easeIn | `Curves.easeIn` | Button unfocus, dialog close |
| easeOutCubic | `Curves.easeOutCubic` | Card focus in, page enter, card scroll |
| easeInCubic | `Curves.easeInCubic` | Card focus out, page exit |
| easeInOut | `Curves.easeInOut` | Background crossfade, progress bar |
| easeOutBack | `Curves.easeOutBack` | Dialog open (subtle bounce) |
| linear | `Curves.linear` | Shimmer animation |

---

## Animation Durations Reference

| Animation | Duration | Token |
|-----------|----------|-------|
| Card Focus In | 200ms | `AppAnimationDurations.focusIn` |
| Card Focus Out | 150ms | `AppAnimationDurations.focusOut` |
| Button Focus In | 150ms | `AppAnimationDurations.focusIn` |
| Button Focus Out | 100ms | `AppAnimationDurations.focusOut` |
| Page Enter | 300ms | `AppAnimationDurations.pageEnter` |
| Page Exit | 200ms | `AppAnimationDurations.pageExit` |
| Background Crossfade | 500ms | `AppAnimationDurations.crossfade` |
| Card Scroll | 250ms | `AppAnimationDurations.cardScroll` |
| Shimmer | 1500ms | `AppAnimationDurations.shimmer` |
| Dialog Open | 200ms | `AppAnimationDurations.dialogOpen` |
| Dialog Close | 150ms | `AppAnimationDurations.dialogClose` |
| Progress Bar | 300ms | `AppAnimationDurations.progressBar` |

---

## Implementation Guidelines

### Using Animation Tokens

```dart
// Always use tokens from AppAnimationDurations and AppAnimationCurves
AnimatedContainer(
  duration: AppAnimationDurations.focusIn,
  curve: AppAnimationCurves.focusIn,
  // ...
)
```

### Focus Animation Pattern

```dart
// Card focus animation
AnimatedScale(
  scale: isFocused ? 1.08 : 1.0,
  duration: AppAnimationDurations.focusIn,
  curve: AppAnimationCurves.focusIn,
  child: GameCard(...),
)
```

### Page Transition Pattern

Use Flutter's built-in page transitions with custom duration/curve:

```dart
PageRouteBuilder(
  transitionDuration: AppAnimationDurations.pageEnter,
  pageBuilder: (context, animation, secondaryAnimation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimationCurves.pageEnter,
        )),
        child: child,
      ),
    );
  },
)
```

### Performance Considerations

- Use `AnimatedContainer`, `AnimatedScale`, `AnimatedOpacity` for simple animations
- Use `AnimationController` only for complex, coordinated animations
- Always dispose of AnimationControllers in `dispose()`
- Prefer const constructors for animation curves and durations
- Test animations at 60fps on target hardware

---

## Accessibility

- Respect `prefers-reduced-motion` when Flutter supports it
- Ensure focus animations are visible but not distracting
- Animation durations should not delay user interaction
- Users should be able to interact immediately even during animations

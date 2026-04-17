# Design Standards

This document defines the visual design language for Squirrel Play. All UI implementations must follow these specifications to ensure consistency across the application.

---

## Color Palette

### Background Colors
| Token | Hex Value | Usage |
|-------|-----------|-------|
| `AppColors.background` | #0D0D0F | Primary background, base layer |
| `AppColors.backgroundDeep` | #08080A | Deep background for gradient effects |

### Surface Colors
| Token | Hex Value | Usage |
|-------|-----------|-------|
| `AppColors.surface` | #1A1A1E | Cards, panels, elevated surfaces |
| `AppColors.surfaceOpacity` | 0.85 | Opacity value for layered transparency effect |
| `AppColors.surfaceElevated` | #2A2A30 | Hover/focus states on surfaces |

### Accent Colors
| Token | Hex Value | Usage |
|-------|-----------|-------|
| `AppColors.primaryAccent` | #FF6B2B | Primary actions, focus rings, CTAs |
| `AppColors.primaryAccentHover` | #FF8A50 | Pressed states, hover on primary accent |
| `AppColors.secondaryAccent` | #00C9A7 | Success states, secondary actions, metadata badges |

### Text Colors
| Token | Hex Value | Usage |
|-------|-----------|-------|
| `AppColors.textPrimary` | #FFFFFF | Headings, focused elements, primary text |
| `AppColors.textSecondary` | #B0B0B8 | Descriptions, metadata, secondary text |
| `AppColors.textMuted` | #6B6B75 | Timestamps, disabled states, hints |

### Utility Colors
| Token | Hex Value | Usage |
|-------|-----------|-------|
| `AppColors.error` | #FF4757 | Error states, destructive actions |
| `AppColors.overlay` | 60% opacity black | Modal backgrounds, overlays |

### Gradient Background
The application uses a subtle gradient from `background` (#0D0D0F) to `backgroundDeep` (#08080A) to create depth and an OLED-like infinite depth effect.

---

## Typography

### Font Family
- **Primary**: Inter (via `google_fonts` package)
- **Monospace**: System monospace font for technical information

### Type Scale
All sizes follow a 4px base grid. Line heights are multiples of 4.

| Level | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| Heading | 32px | w700 (Bold) | 40px | Page titles, game names |
| Body | 16px | w400 (Regular) | 24px | Descriptions, metadata |
| Caption | 12px | w300 (Light) | 16px | Genres, ratings, timestamps |
| Monospace | 14px | w400 (Regular) | 20px | File paths, technical info |

### Font Weights
- `w300`: Light - captions, metadata
- `w400`: Regular - body text, descriptions
- `w700`: Bold - headings, game titles

---

## Spacing Scale

All spacing values are multiples of 4px to maintain visual rhythm.

| Token | Value | Usage |
|-------|-------|-------|
| `AppSpacing.xs` | 4px | Tight spacing, icon padding |
| `AppSpacing.sm` | 8px | Small gaps, inline spacing |
| `AppSpacing.md` | 12px | Medium gaps, card padding |
| `AppSpacing.lg` | 16px | Standard spacing, section gaps |
| `AppSpacing.xl` | 24px | Large gaps, between cards |
| `AppSpacing.xxl` | 32px | Section margins |
| `AppSpacing.xxxl` | 48px | Major section separations |
| `AppSpacing.xxxxl` | 64px | Page margins, top bar height |

---

## Component Specifications

### Game Cards
- **Aspect Ratio**: 2:3 (movie poster style)
- **Dimensions by Breakpoint**:
  - Compact (<640px): 140×210px
  - Medium (640-1024px): 170×255px
  - Expanded (1024-1440px): 200×300px
  - Large (>1440px): 240×360px
- **Border Radius**: 8px (`AppRadii.medium`)
- **Spacing Between Cards**: 16px (`AppSpacing.lg`)
- **Focus Animation**: Scale 1.0 → 1.08, 200ms easeOutCubic

### Buttons
- **Minimum Hit Area**: 48×48px (accessibility requirement)
- **Standard Height**: 48px
- **Border Radius**: 8px (`AppRadii.medium`)
- **Focus Indicator**: 2px accent underline or background color shift
- **Focus Animation**: 150ms easeOut

### Top Bar
- **Height**: 64px (`AppSpacing.xxxxl`)
- **Background**: `AppColors.surface` with 85% opacity
- **Layout**: 
  - Left: System time display
  - Center: App logo/title
  - Right: Action buttons (Add Game, Game Library, Rescan)
- **Position**: Fixed at top of viewport

### Dialogs
- **Background**: `AppColors.surface` with 85% opacity
- **Border Radius**: 12px (`AppRadii.large`)
- **Padding**: 24px (`AppSpacing.xl`)
- **Overlay**: 60% black opacity behind dialog

---

## Layout Principles

### Full-Viewport Canvas
- Background image fills entire screen
- Dark gradient overlay ensures text readability
- Content sits on semi-transparent panels over background

### Horizontal-First Navigation
- Card rows scroll horizontally (TV/couch paradigm)
- D-pad left/right navigates within rows
- D-pad up/down navigates between rows

### Generous Spacing
- 16-24px between cards
- 32-48px margins from screen edges
- This is a 10-foot UI, not desktop UI

### Oversized Touch Targets
- All interactive elements ≥48px minimum
- Critical for gamepad navigation accuracy

### Layered Depth
- Background layer: gradient + optional hero image
- Surface layer: cards, panels at 85% opacity
- Elevated layer: focused elements with increased elevation

---

## Responsive Breakpoints

| Breakpoint | Width Range | Layout Adaptation |
|------------|-------------|-------------------|
| Compact | < 640px | Single column, smaller cards (140×210), vertical scrolling |
| Medium | 640px - 1024px | 2-column grid, medium cards (170×255), horizontal rows |
| Expanded | 1024px - 1440px | 3-column grid, standard cards (200×300), full layout |
| Large | ≥ 1440px | 4-5 column grid, larger cards (240×360), extra spacing |

### Breakpoint Semantics
Thresholds represent inclusive lower bounds:
- `compact`: width < 640px
- `medium`: width >= 640px && width < 1024px
- `expanded`: width >= 1024px && width < 1440px
- `large`: width >= 1440px

### Visible Card Count Targets
- Compact: 2-3 cards visible
- Medium: 3-4 cards visible
- Expanded: 4-5 cards visible
- Large: 5-7 cards visible

---

## Implementation Notes

### Color Application
- Use `AppColors` tokens directly in widgets
- Apply `surfaceOpacity` (0.85) when creating layered transparency effects
- Background gradient uses `background` → `backgroundDeep`

### Typography Application
- Import Inter font via `google_fonts` package
- Use `AppTypography` text styles for consistency
- All text styles specify Inter font family explicitly

### Spacing Application
- Use `AppSpacing` tokens for all padding and margins
- Maintain 4px grid alignment
- Never use arbitrary spacing values

### Dark Theme Only
- This application does not implement a light theme
- All design tokens are optimized for dark backgrounds
- Focus on OLED-friendly deep blacks for power efficiency

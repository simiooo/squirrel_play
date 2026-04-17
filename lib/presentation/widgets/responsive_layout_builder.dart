import 'package:flutter/material.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';

/// A responsive layout builder widget that builds different layouts
/// based on the current breakpoint.
///
/// Usage:
/// ```dart
/// ResponsiveLayoutBuilder(
///   builders: {
///     ResponsiveLayout.compact: (context) => CompactLayout(),
///     ResponsiveLayout.medium: (context) => MediumLayout(),
///     ResponsiveLayout.expanded: (context) => ExpandedLayout(),
///     ResponsiveLayout.large: (context) => LargeLayout(),
///   },
///   fallback: ResponsiveLayout.expanded,
/// )
/// ```
class ResponsiveLayoutBuilder extends StatelessWidget {
  /// Map of breakpoint to builder function.
  final Map<ResponsiveLayout, WidgetBuilder> builders;

  /// Fallback breakpoint to use if the current breakpoint is not in builders.
  final ResponsiveLayout fallback;

  /// Creates a ResponsiveLayoutBuilder.
  const ResponsiveLayoutBuilder({
    super.key,
    required this.builders,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);

    // Use the builder for the current breakpoint, or fallback if not found
    final builder = builders[breakpoint] ?? builders[fallback];

    if (builder == null) {
      throw FlutterError(
        'ResponsiveLayoutBuilder: No builder found for breakpoint $breakpoint '
        'and fallback $fallback is also not in builders.',
      );
    }

    return builder(context);
  }
}

/// Extension methods for ResponsiveLayout to get responsive values.
extension ResponsiveLayoutExtension on ResponsiveLayout {
  /// Gets the card width for this breakpoint.
  double get cardWidth => CardDimensions.getWidth(this);

  /// Gets the card height for this breakpoint.
  double get cardHeight => CardDimensions.getHeight(this);

  /// Gets the card size for this breakpoint.
  Size get cardSize => CardDimensions.getSize(this);

  /// Gets the recommended visible card count for this breakpoint.
  int get visibleCardCount => VisibleCardCount.getCount(this);

  /// Whether this is a compact layout (mobile-like).
  bool get isCompact => this == ResponsiveLayout.compact;

  /// Whether this is a medium layout (tablet-like).
  bool get isMedium => this == ResponsiveLayout.medium;

  /// Whether this is an expanded layout (desktop).
  bool get isExpanded => this == ResponsiveLayout.expanded;

  /// Whether this is a large layout (large desktop).
  bool get isLarge => this == ResponsiveLayout.large;

  /// Whether this layout should use horizontal scrolling for card rows.
  bool get useHorizontalScroll => !isCompact;

  /// Whether this layout should collapse the top bar to hamburger menu.
  bool get collapseTopBar => isCompact;

  /// Gets the appropriate padding for this layout.
  EdgeInsets get contentPadding {
    switch (this) {
      case ResponsiveLayout.compact:
        return const EdgeInsets.all(16);
      case ResponsiveLayout.medium:
        return const EdgeInsets.all(24);
      case ResponsiveLayout.expanded:
        return const EdgeInsets.all(32);
      case ResponsiveLayout.large:
        return const EdgeInsets.all(48);
    }
  }

  /// Gets the appropriate spacing between cards for this layout.
  double get cardSpacing {
    switch (this) {
      case ResponsiveLayout.compact:
        return 8;
      case ResponsiveLayout.medium:
        return 12;
      case ResponsiveLayout.expanded:
        return 16;
      case ResponsiveLayout.large:
        return 24;
    }
  }

  /// Gets the appropriate row spacing for this layout.
  double get rowSpacing {
    switch (this) {
      case ResponsiveLayout.compact:
        return 16;
      case ResponsiveLayout.medium:
        return 20;
      case ResponsiveLayout.expanded:
        return 24;
      case ResponsiveLayout.large:
        return 32;
    }
  }
}

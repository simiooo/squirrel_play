import 'package:flutter/material.dart';

/// Responsive layout breakpoints.
///
/// Defines the width thresholds for different layout adaptations.
/// Thresholds represent inclusive lower bounds.
class Breakpoints {
  Breakpoints._();

  /// Compact breakpoint threshold - less than 640px.
  static const double compact = 640.0;

  /// Medium breakpoint threshold - 640px to 1024px.
  static const double medium = 1024.0;

  /// Expanded breakpoint threshold - 1024px to 1440px.
  static const double expanded = 1440.0;

  /// Large breakpoint threshold - 1440px and above.
  static const double large = 1440.0;

  /// Gets the current breakpoint based on screen width.
  ///
  /// Uses inclusive lower bound semantics:
  /// - width < 640 → compact
  /// - 640 ≤ width < 1024 → medium
  /// - 1024 ≤ width < 1440 → expanded
  /// - width ≥ 1440 → large
  static ResponsiveLayout getBreakpoint(double width) {
    if (width < compact) {
      return ResponsiveLayout.compact;
    } else if (width < medium) {
      return ResponsiveLayout.medium;
    } else if (width < expanded) {
      return ResponsiveLayout.expanded;
    } else {
      return ResponsiveLayout.large;
    }
  }

  /// Gets the current breakpoint from a BuildContext.
  static ResponsiveLayout getBreakpointFromContext(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return getBreakpoint(width);
  }
}

/// Enum representing the responsive layout breakpoints.
enum ResponsiveLayout {
  /// Compact layout - single column, smaller cards.
  compact,

  /// Medium layout - 2-column grid, medium cards.
  medium,

  /// Expanded layout - 3-column grid, standard cards.
  expanded,

  /// Large layout - 4-5 column grid, larger cards.
  large,
}

/// Card dimensions for each breakpoint.
///
/// Game cards use a 2:3 aspect ratio (movie poster style).
class CardDimensions {
  CardDimensions._();

  /// Card width for compact layout - 140px.
  static const double compactWidth = 140.0;

  /// Card height for compact layout - 210px (2:3 ratio).
  static const double compactHeight = 210.0;

  /// Card width for medium layout - 170px.
  static const double mediumWidth = 170.0;

  /// Card height for medium layout - 255px (2:3 ratio).
  static const double mediumHeight = 255.0;

  /// Card width for expanded layout - 200px.
  static const double expandedWidth = 200.0;

  /// Card height for expanded layout - 300px (2:3 ratio).
  static const double expandedHeight = 300.0;

  /// Card width for large layout - 240px.
  static const double largeWidth = 240.0;

  /// Card height for large layout - 360px (2:3 ratio).
  static const double largeHeight = 360.0;

  /// Gets the card width for the given breakpoint.
  static double getWidth(ResponsiveLayout breakpoint) {
    switch (breakpoint) {
      case ResponsiveLayout.compact:
        return compactWidth;
      case ResponsiveLayout.medium:
        return mediumWidth;
      case ResponsiveLayout.expanded:
        return expandedWidth;
      case ResponsiveLayout.large:
        return largeWidth;
    }
  }

  /// Gets the card height for the given breakpoint.
  static double getHeight(ResponsiveLayout breakpoint) {
    switch (breakpoint) {
      case ResponsiveLayout.compact:
        return compactHeight;
      case ResponsiveLayout.medium:
        return mediumHeight;
      case ResponsiveLayout.expanded:
        return expandedHeight;
      case ResponsiveLayout.large:
        return largeHeight;
    }
  }

  /// Gets the card size as a Size object for the given breakpoint.
  static Size getSize(ResponsiveLayout breakpoint) {
    return Size(getWidth(breakpoint), getHeight(breakpoint));
  }
}

/// Visible card count targets for each breakpoint.
class VisibleCardCount {
  VisibleCardCount._();

  /// Visible cards for compact layout - 2-3 cards.
  static const int compact = 2;

  /// Visible cards for medium layout - 3-4 cards.
  static const int medium = 3;

  /// Visible cards for expanded layout - 4-5 cards.
  static const int expanded = 4;

  /// Visible cards for large layout - 5-7 cards.
  static const int large = 5;

  /// Gets the recommended visible card count for the given breakpoint.
  static int getCount(ResponsiveLayout breakpoint) {
    switch (breakpoint) {
      case ResponsiveLayout.compact:
        return compact;
      case ResponsiveLayout.medium:
        return medium;
      case ResponsiveLayout.expanded:
        return expanded;
      case ResponsiveLayout.large:
        return large;
    }
  }
}

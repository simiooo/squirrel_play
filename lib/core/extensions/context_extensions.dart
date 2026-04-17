import 'package:flutter/material.dart';

import 'package:squirrel_play/core/utils/breakpoints.dart';

/// Extension methods on BuildContext for responsive utilities.
extension ContextExtensions on BuildContext {
  /// Gets the current responsive breakpoint based on screen width.
  ResponsiveLayout get currentBreakpoint {
    return Breakpoints.getBreakpointFromContext(this);
  }

  /// Gets the card dimensions for the current breakpoint.
  Size get cardDimensions {
    return CardDimensions.getSize(currentBreakpoint);
  }

  /// Returns true if the current layout is compact.
  bool get isCompact => currentBreakpoint == ResponsiveLayout.compact;

  /// Returns true if the current layout is medium.
  bool get isMedium => currentBreakpoint == ResponsiveLayout.medium;

  /// Returns true if the current layout is expanded.
  bool get isExpanded => currentBreakpoint == ResponsiveLayout.expanded;

  /// Returns true if the current layout is large.
  bool get isLarge => currentBreakpoint == ResponsiveLayout.large;

  /// Returns true if the screen width is at least the compact breakpoint.
  bool get isAtLeastCompact {
    final width = MediaQuery.of(this).size.width;
    return width >= Breakpoints.compact;
  }

  /// Returns true if the screen width is at least the medium breakpoint.
  bool get isAtLeastMedium {
    final width = MediaQuery.of(this).size.width;
    return width >= Breakpoints.medium;
  }

  /// Returns true if the screen width is at least the expanded breakpoint.
  bool get isAtLeastExpanded {
    final width = MediaQuery.of(this).size.width;
    return width >= Breakpoints.expanded;
  }

  /// Returns true if the screen width is at least the large breakpoint.
  bool get isAtLeastLarge {
    final width = MediaQuery.of(this).size.width;
    return width >= Breakpoints.large;
  }
}

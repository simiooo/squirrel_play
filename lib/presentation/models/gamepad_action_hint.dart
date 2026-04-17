import 'package:flutter/material.dart';

/// Model representing a gamepad action hint displayed in the navigation bar.
///
/// Contains the button label (e.g. "A", "B", "X", "Y", "Start", "Back"),
/// the action label (e.g. "Select", "Back"), and an optional custom icon.
class GamepadActionHint {
  /// The button label text (e.g. "A", "B", "Start").
  final String buttonLabel;

  /// The action label text (e.g. "Select", "Back").
  final String actionLabel;

  /// Optional custom icon for the button.
  final IconData? buttonIcon;

  /// Creates a gamepad action hint.
  const GamepadActionHint({
    required this.buttonLabel,
    required this.actionLabel,
    this.buttonIcon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamepadActionHint &&
          runtimeType == other.runtimeType &&
          buttonLabel == other.buttonLabel &&
          actionLabel == other.actionLabel &&
          buttonIcon == other.buttonIcon;

  @override
  int get hashCode => Object.hash(buttonLabel, actionLabel, buttonIcon);
}

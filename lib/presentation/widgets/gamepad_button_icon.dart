import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';

/// Renders a colored visual representation of a gamepad button.
///
/// Letter buttons (A, B, X, Y) are rendered as circles.
/// Start and Back buttons are rendered as rounded rectangles (pills).
/// Colors are mapped according to the design tokens.
class GamepadButtonIcon extends StatelessWidget {
  /// Creates a gamepad button icon.
  const GamepadButtonIcon({
    required this.label,
    super.key,
  });

  /// The button label (e.g. "A", "B", "X", "Y", "Start", "Back").
  final String label;

  Color _resolveColor() {
    switch (label.toUpperCase()) {
      case 'A':
        return AppColors.secondaryAccent;
      case 'B':
        // Use a softer, more harmonious color instead of jarring error red
        return AppColors.textSecondary;
      case 'X':
        return AppColors.primaryAccent;
      case 'Y':
        return AppColors.warning;
      case 'START':
      case 'BACK':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  bool get _isPill =>
      label.toUpperCase() == 'START' || label.toUpperCase() == 'BACK';

  bool get _isCircular =>
      label.toUpperCase() == 'A' || label.toUpperCase() == 'B';

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final isPill = _isPill;
    final isCircular = _isCircular;

    // For circular buttons (A/B), use fixed size to ensure perfect circle
    if (isCircular) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 12,
              fontWeight: AppTypography.bold,
              height: 1,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPill ? AppSpacing.sm : AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isPill ? AppRadii.small : 100),
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.background,
            fontSize: 10,
            fontWeight: AppTypography.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}

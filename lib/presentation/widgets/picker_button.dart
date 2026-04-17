import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// A specialized button widget for file and directory picker actions.
///
/// Unlike [FocusableButton], this button is always visible with a persistent
/// background color, making it suitable for picker actions that need to be
/// immediately recognizable as interactive elements.
///
/// Features:
/// - Always visible with [AppColors.surfaceElevated] background (not transparent)
/// - Border outline using [AppColors.surfaceElevated] for definition when unfocused
/// - Full border focus indicator with [AppColors.primaryAccent] for high prominence
/// - Icon + text label pattern for quick visual recognition
/// - Minimum 48×48px touch target
/// - Semantic labels for accessibility
/// - Sound hooks (playFocusMove on focus, playFocusSelect on press)
class PickerButton extends StatefulWidget {
  /// Creates a picker button.
  const PickerButton({
    super.key,
    required this.focusNode,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.hint,
  });

  /// The focus node for this button.
  final FocusNode focusNode;

  /// The button label text.
  final String label;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Icon to display before the label (required for picker buttons).
  final IconData icon;

  /// Optional semantic hint for accessibility.
  final String? hint;

  @override
  State<PickerButton> createState() => _PickerButtonState();
}

class _PickerButtonState extends State<PickerButton> {
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(PickerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    final isFocused = widget.focusNode.hasFocus;

    // Play sound when gaining focus (debounced by SoundService)
    if (isFocused && !_wasFocused) {
      SoundService.instance.playFocusMove();
    }

    setState(() {
      _wasFocused = isFocused;
    });
  }

  void _handlePress() {
    // Play select sound immediately
    SoundService.instance.playFocusSelect();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    // PickerButton always has a visible background
    // Use surfaceElevated for unfocused to provide contrast against surface containers
    final backgroundColor = isFocused
        ? AppColors.surface
        : AppColors.surfaceElevated;

    // Text color changes based on focus state
    final textColor = isFocused
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    // Full border for focus indicator (not just bottom accent)
    // This provides higher visual prominence for picker buttons
    final border = isFocused
        ? Border.all(
            color: AppColors.primaryAccent,
            width: 2,
          )
        : Border.all(
            color: AppColors.surfaceElevated,
            width: 1,
          );

    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.hint,
      child: Focus(
        focusNode: widget.focusNode,
        child: AnimatedContainer(
          duration: isFocused
              ? const Duration(milliseconds: 150)
              : const Duration(milliseconds: 100),
          curve: isFocused
              ? AppAnimationCurves.focusIn
              : AppAnimationCurves.focusOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: border,
          ),
          child: TextButton(
            onPressed: _handlePress,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: textColor,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

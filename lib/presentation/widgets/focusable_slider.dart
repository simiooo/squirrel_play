import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// A focus-aware Slider widget with visual focus indicators, gamepad control,
/// and sound hooks.
///
/// Features:
/// - 2px full border in primaryAccent when focused
/// - Enhanced value label styling on focus
/// - Gamepad D-pad left/right adjusts value by step
/// - D-pad up/down moves focus away (returns KeyEventResult.ignored)
/// - Animated transitions (200ms in, 150ms out)
/// - Sound hooks (playFocusMove on focus gain)
/// - Optional explicit step parameter for gamepad adjustment
/// - Semantic labels for accessibility
class FocusableSlider extends StatefulWidget {
  /// Creates a focusable slider.
  const FocusableSlider({
    super.key,
    required this.focusNode,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.step,
    this.semanticLabel,
    this.activeColor,
    this.inactiveColor,
  });

  /// The focus node for this slider.
  final FocusNode focusNode;

  /// The current value of the slider.
  final double value;

  /// Callback when the value changes.
  final ValueChanged<double> onChanged;

  /// The minimum value of the slider.
  final double min;

  /// The maximum value of the slider.
  final double max;

  /// The number of discrete divisions.
  final int? divisions;

  /// The label to display above the slider when focused.
  final String? label;

  /// Optional explicit step value for gamepad adjustment.
  /// Defaults to (max - min) / divisions if divisions is provided.
  final double? step;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// The color to use for the active portion of the slider.
  final Color? activeColor;

  /// The color to use for the inactive portion of the slider.
  final Color? inactiveColor;

  @override
  State<FocusableSlider> createState() => _FocusableSliderState();
}

class _FocusableSliderState extends State<FocusableSlider> {
  bool _wasFocused = false;

  /// Calculates the step value for gamepad adjustment.
  double get _stepValue {
    if (widget.step != null) {
      return widget.step!;
    }
    if (widget.divisions != null && widget.divisions! > 0) {
      return (widget.max - widget.min) / widget.divisions!;
    }
    // Default step of 0.1 if no divisions or step specified
    return 0.1;
  }

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FocusableSlider oldWidget) {
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

  /// Handles keyboard/gamepad events for the slider.
  ///
  /// - Left/right arrows adjust the value by one step
  /// - Up/down arrows are ignored (allow focus traversal)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final step = _stepValue;

    // Handle left arrow (keyboard and gamepad D-pad left)
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      // Decrease value by one step
      final newValue = (widget.value - step).clamp(widget.min, widget.max);
      if (newValue != widget.value) {
        widget.onChanged(newValue);
      }
      return KeyEventResult.handled;
    }

    // Handle right arrow (keyboard and gamepad D-pad right)
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      // Increase value by one step
      final newValue = (widget.value + step).clamp(widget.min, widget.max);
      if (newValue != widget.value) {
        widget.onChanged(newValue);
      }
      return KeyEventResult.handled;
    }

    // Allow focus traversal to handle up/down
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    // Background color changes based on focus state
    final backgroundColor = isFocused
        ? AppColors.surfaceElevated
        : Colors.transparent;

    // Value label styling changes on focus
    final valueLabelColor = isFocused
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final valueLabelSize = isFocused ? 18.0 : 16.0;

    return Semantics(
      slider: true,
      value: widget.label ?? '${(widget.value * 100).round()}%',
      label: widget.semanticLabel,
      child: Focus(
        focusNode: widget.focusNode,
        onKeyEvent: _handleKeyEvent,
        child: AnimatedContainer(
          duration: isFocused
              ? AppAnimationDurations.focusIn
              : AppAnimationDurations.focusOut,
          curve: isFocused
              ? AppAnimationCurves.focusIn
              : AppAnimationCurves.focusOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: isFocused
                ? Border.all(
                    color: AppColors.primaryAccent,
                    width: 2,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Slider
              Expanded(
                child: Slider(
                  value: widget.value,
                  onChanged: widget.onChanged,
                  min: widget.min,
                  max: widget.max,
                  divisions: widget.divisions,
                  label: widget.label,
                  activeColor: widget.activeColor ?? AppColors.primaryAccent,
                  inactiveColor: widget.inactiveColor,
                ),
              ),
              // Value display
              AnimatedDefaultTextStyle(
                duration: isFocused
                    ? AppAnimationDurations.focusIn
                    : AppAnimationDurations.focusOut,
                curve: isFocused
                    ? AppAnimationCurves.focusIn
                    : AppAnimationCurves.focusOut,
                style: TextStyle(
                  color: valueLabelColor,
                  fontSize: valueLabelSize,
                  fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                ),
                child: Text(
                  '${(widget.value * 100).round()}%',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

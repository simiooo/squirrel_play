import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// A focus-aware Switch widget with visual focus indicators and sound hooks.
///
/// Features:
/// - 2px full border in primaryAccent when focused
/// - surfaceElevated background when focused
/// - Scale animation (1.0 → 1.02) on focus
/// - Animated transitions (200ms in, 150ms out)
/// - Sound hooks (playFocusMove on focus gain, playFocusSelect on toggle)
/// - Row layout with title and switch
/// - Semantic labels for accessibility
class FocusableSwitch extends StatefulWidget {
  /// Creates a focusable switch.
  const FocusableSwitch({
    super.key,
    required this.focusNode,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.semanticLabel,
  });

  /// The focus node for this switch.
  final FocusNode focusNode;

  /// Whether the switch is on or off.
  final bool value;

  /// Callback when the switch is toggled.
  final ValueChanged<bool> onChanged;

  /// The title widget to display.
  final Widget? title;

  /// The subtitle widget to display below the title.
  final Widget? subtitle;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  State<FocusableSwitch> createState() => _FocusableSwitchState();
}

class _FocusableSwitchState extends State<FocusableSwitch> {
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FocusableSwitch oldWidget) {
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

  void _handleToggle() {
    final newValue = !widget.value;
    // Play select sound immediately
    SoundService.instance.playFocusSelect();
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    // Background color changes based on focus state
    final backgroundColor = isFocused
        ? AppColors.surfaceElevated
        : Colors.transparent;

    // Scale animation: 1.0 → 1.02 on focus
    final scale = isFocused ? 1.02 : 1.0;

    return Semantics(
      toggled: widget.value,
      label: widget.semanticLabel,
      child: Focus(
        focusNode: widget.focusNode,
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
          child: AnimatedScale(
            scale: scale,
            duration: isFocused
                ? AppAnimationDurations.focusIn
                : AppAnimationDurations.focusOut,
            curve: isFocused
                ? AppAnimationCurves.focusIn
                : AppAnimationCurves.focusOut,
            child: ListTile(
              title: widget.title ?? const SizedBox.shrink(),
              subtitle: widget.subtitle,
              trailing: Switch(
                value: widget.value,
                onChanged: (_) => _handleToggle(),
                activeThumbColor: AppColors.primaryAccent,
              ),
              onTap: _handleToggle,
              minTileHeight: 48,
            ),
          ),
        ),
      ),
    );
  }
}

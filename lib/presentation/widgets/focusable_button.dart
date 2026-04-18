import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// A reusable button widget with focus animations and sound hooks.
///
/// Features:
/// - Focus animations (background shift, accent underline)
/// - Sound hooks (playFocusMove on focus, playFocusSelect on press)
/// - Primary/secondary styling variants
/// - Minimum 48×48px touch target
/// - Semantic labels for accessibility
class FocusableButton extends StatefulWidget {
  /// Creates a focusable button.
  const FocusableButton({
    super.key,
    required this.focusNode,
    required this.label,
    required this.onPressed,
    this.icon,
    this.hint,
    this.isPrimary = false,
    this.isActive = false,
  });

  /// The focus node for this button.
  final FocusNode focusNode;

  /// The button label text.
  final String label;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Optional semantic hint for accessibility.
  final String? hint;

  /// Whether this is a primary (accent) button.
  ///
  /// When true:
  /// - Focused: background uses [AppColors.primaryAccent]
  /// - Unfocused: text uses [AppColors.textPrimary]
  final bool isPrimary;

  /// Whether this button represents the currently active route.
  ///
  /// When true and not focused:
  /// - Background uses a subtle [AppColors.primaryAccent] tint
  /// - Text is bold
  ///
  /// When focused, the focus styling takes precedence.
  final bool isActive;

  @override
  State<FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FocusableButton oldWidget) {
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

    // Play sound and scroll into view when gaining focus
    if (isFocused && !_wasFocused) {
      SoundService.instance.playFocusMove();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      });
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

    // Determine colors based on focus state, isPrimary, and isActive
    final backgroundColor = isFocused
        ? (widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceElevated)
        : (widget.isActive ? AppColors.primaryAccent.withAlpha(77) : Colors.transparent);

    final textColor = isFocused
        ? AppColors.textPrimary
        : (widget.isPrimary || widget.isActive ? AppColors.textPrimary : AppColors.textSecondary);

    final fontWeight = (widget.isActive || isFocused) ? FontWeight.bold : FontWeight.normal;

    return Semantics(
      button: true,
      label: widget.label,
      hint: widget.hint,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.gameButtonA ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select) {
              _handlePress();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
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
            border: isFocused
                ? const Border(
                    bottom: BorderSide(
                      color: AppColors.primaryAccent,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: TextButton(
            focusNode: widget.focusNode,
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
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: textColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: fontWeight,
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

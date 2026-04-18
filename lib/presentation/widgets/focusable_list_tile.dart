import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// A focus-aware ListTile widget with visual focus indicators and sound hooks.
///
/// Features:
/// - 2px bottom border in primaryAccent when focused
/// - surfaceElevated background when focused
/// - Animated transitions (200ms in, 150ms out)
/// - Sound hooks (playFocusMove on focus gain, playFocusSelect on tap)
/// - Minimum 48px height for touch target
/// - Semantic labels for accessibility
class FocusableListTile extends StatefulWidget {
  /// Creates a focusable list tile.
  const FocusableListTile({
    super.key,
    required this.focusNode,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  /// The focus node for this tile.
  final FocusNode focusNode;

  /// The primary text to display.
  final Widget title;

  /// The secondary text to display below the title.
  final Widget? subtitle;

  /// A widget to display before the title.
  final Widget? leading;

  /// A widget to display after the title.
  final Widget? trailing;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  @override
  State<FocusableListTile> createState() => _FocusableListTileState();
}

class _FocusableListTileState extends State<FocusableListTile> {
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FocusableListTile oldWidget) {
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

  void _handleTap() {
    // Play select sound immediately
    SoundService.instance.playFocusSelect();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    // Background color changes based on focus state
    final backgroundColor = isFocused
        ? AppColors.surfaceElevated
        : Colors.transparent;

    return Semantics(
      button: widget.onTap != null,
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
                ? const Border(
                    bottom: BorderSide(
                      color: AppColors.primaryAccent,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: ListTile(
            leading: widget.leading,
            title: widget.title,
            subtitle: widget.subtitle,
            trailing: widget.trailing,
            onTap: widget.onTap != null ? _handleTap : null,
            minTileHeight: 48,
          ),
        ),
      ),
    );
  }
}

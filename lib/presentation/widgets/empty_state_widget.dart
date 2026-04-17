import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// A reusable empty state widget with CTA button.
///
/// Features:
/// - Empty state icon
/// - Title and message
/// - CTA button (gamepad-focusable)
class EmptyStateWidget extends StatefulWidget {
  /// Creates the empty state widget.
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onButtonPressed,
    this.icon = Icons.inbox_outlined,
  });

  /// The title to display.
  final String title;

  /// The message to display.
  final String message;

  /// Label for the CTA button.
  final String buttonLabel;

  /// Callback when CTA button is pressed.
  final VoidCallback onButtonPressed;

  /// Icon to display.
  final IconData icon;

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget> {
  late final FocusNode _buttonFocusNode;

  @override
  void initState() {
    super.initState();
    _buttonFocusNode = FocusNode(debugLabel: 'EmptyStateButton');

    // Register empty-state button as content node for focus traversal
    FocusTraversalService.instance.registerContentNode(_buttonFocusNode);
  }

  @override
  void dispose() {
    FocusTraversalService.instance.unregisterContentNode(_buttonFocusNode);
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: 64,
            color: AppColors.textMuted.withAlpha(128),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FocusableButton(
            focusNode: _buttonFocusNode,
            label: widget.buttonLabel,
            isPrimary: true,
            onPressed: widget.onButtonPressed,
          ),
        ],
      ),
    );
  }
}

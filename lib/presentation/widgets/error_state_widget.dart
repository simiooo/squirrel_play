import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// A reusable error state widget with retry button.
///
/// Features:
/// - Error icon
/// - Error message
/// - Retry button (gamepad-focusable)
class ErrorStateWidget extends StatefulWidget {
  /// Creates the error state widget.
  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
  });

  /// The error message to display.
  final String message;

  /// Callback when retry button is pressed.
  final VoidCallback onRetry;

  /// Label for the retry button.
  final String retryLabel;

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget> {
  late final FocusNode _retryFocusNode;

  @override
  void initState() {
    super.initState();
    _retryFocusNode = FocusNode(debugLabel: 'RetryButton');
  }

  @override
  void dispose() {
    _retryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error.withAlpha(128),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Something went wrong',
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
            focusNode: _retryFocusNode,
            label: widget.retryLabel,
            isPrimary: true,
            onPressed: widget.onRetry,
          ),
        ],
      ),
    );
  }
}

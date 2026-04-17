import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// Error state widget for the home page.
///
/// Shows when loading games fails.
/// Features:
/// - Error message with icon
/// - Retry button
class ErrorHomeState extends StatefulWidget {
  /// The error message to display.
  final String message;

  /// Callback when retry button is pressed.
  final VoidCallback onRetry;

  /// Creates an ErrorHomeState widget.
  const ErrorHomeState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  State<ErrorHomeState> createState() => _ErrorHomeStateState();
}

class _ErrorHomeStateState extends State<ErrorHomeState> {
  late FocusNode _retryFocusNode;

  @override
  void initState() {
    super.initState();
    _retryFocusNode = FocusNode(debugLabel: 'ErrorStateRetry');
  }

  @override
  void dispose() {
    _retryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(26),
                borderRadius: BorderRadius.circular(AppRadii.large),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Error title
            Text(
              l10n?.errorLoadGames ?? 'Failed to load games',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Error message
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Retry button
            FocusableButton(
              focusNode: _retryFocusNode,
              label: l10n?.buttonRetry ?? 'Retry',
              isPrimary: true,
              onPressed: () {
                SoundService.instance.playFocusSelect();
                widget.onRetry();
              },
            ),
          ],
        ),
      ),
    );
  }
}

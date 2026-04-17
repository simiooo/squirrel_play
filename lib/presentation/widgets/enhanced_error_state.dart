import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// Enhanced error state widget with specific error types.
///
/// Supports:
/// - Database errors
/// - API errors
/// - Missing executable errors
/// - Generic errors
class EnhancedErrorState extends StatefulWidget {
  /// The type of error.
  final ErrorType errorType;

  /// The error message to display.
  final String? message;

  /// Callback when retry button is pressed.
  final VoidCallback? onRetry;

  /// Callback when browse button is pressed (for missing executable).
  final VoidCallback? onBrowse;

  /// Callback when remove button is pressed (for missing executable).
  final VoidCallback? onRemove;

  /// Creates an EnhancedErrorState widget.
  const EnhancedErrorState({
    super.key,
    this.errorType = ErrorType.generic,
    this.message,
    this.onRetry,
    this.onBrowse,
    this.onRemove,
  });

  /// Creates a database error state.
  const EnhancedErrorState.database({
    super.key,
    this.message,
    this.onRetry,
  })  : errorType = ErrorType.database,
        onBrowse = null,
        onRemove = null;

  /// Creates an API error state.
  const EnhancedErrorState.api({
    super.key,
    this.message,
    this.onRetry,
  })  : errorType = ErrorType.api,
        onBrowse = null,
        onRemove = null;

  /// Creates a missing executable error state.
  const EnhancedErrorState.missingExecutable({
    super.key,
    this.message,
    this.onBrowse,
    this.onRemove,
  })  : errorType = ErrorType.missingExecutable,
        onRetry = null;

  @override
  State<EnhancedErrorState> createState() => _EnhancedErrorStateState();
}

/// Enum representing different error types.
enum ErrorType {
  /// Database failure.
  database,

  /// API/connection failure.
  api,

  /// Missing executable file.
  missingExecutable,

  /// Generic error.
  generic,
}

class _EnhancedErrorStateState extends State<EnhancedErrorState> {
  late FocusNode _primaryFocusNode;
  late FocusNode? _secondaryFocusNode;

  @override
  void initState() {
    super.initState();
    _primaryFocusNode = FocusNode(debugLabel: 'ErrorStatePrimary');
    if (widget.errorType == ErrorType.missingExecutable) {
      _secondaryFocusNode = FocusNode(debugLabel: 'ErrorStateSecondary');
    } else {
      _secondaryFocusNode = null;
    }
  }

  @override
  void dispose() {
    _primaryFocusNode.dispose();
    _secondaryFocusNode?.dispose();
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
            _buildIcon(),
            const SizedBox(height: AppSpacing.xl),

            // Error title
            Text(
              _getTitle(l10n),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _getTitleColor(),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Error message
            Text(
              widget.message ?? _getDefaultMessage(l10n),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action buttons
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _getIconData();
    final iconColor = _getIconColor();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(26),
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Icon(
        iconData,
        size: 48,
        color: iconColor,
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations? l10n) {
    if (widget.errorType == ErrorType.missingExecutable) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.onBrowse != null)
            FocusableButton(
              focusNode: _primaryFocusNode,
              label: l10n?.buttonConfirm ?? 'Browse',
              isPrimary: true,
              onPressed: widget.onBrowse!,
            ),
          if (widget.onBrowse != null && widget.onRemove != null)
            const SizedBox(width: AppSpacing.md),
          if (widget.onRemove != null)
            FocusableButton(
              focusNode: _secondaryFocusNode!,
              label: l10n?.buttonCancel ?? 'Remove',
              onPressed: widget.onRemove!,
            ),
        ],
      );
    }

    // Retry button for other error types
    if (widget.onRetry != null) {
      return FocusableButton(
        focusNode: _primaryFocusNode,
        label: l10n?.buttonRetry ?? 'Retry',
        isPrimary: true,
        onPressed: widget.onRetry!,
      );
    }

    return const SizedBox.shrink();
  }

  IconData _getIconData() {
    switch (widget.errorType) {
      case ErrorType.database:
        return Icons.storage_outlined;
      case ErrorType.api:
        return Icons.cloud_off_outlined;
      case ErrorType.missingExecutable:
        return Icons.insert_drive_file_outlined;
      case ErrorType.generic:
        return Icons.error_outline;
    }
  }

  Color _getIconColor() {
    switch (widget.errorType) {
      case ErrorType.database:
        return AppColors.error;
      case ErrorType.api:
        return AppColors.primaryAccent;
      case ErrorType.missingExecutable:
        return AppColors.secondaryAccent;
      case ErrorType.generic:
        return AppColors.error;
    }
  }

  Color _getTitleColor() {
    switch (widget.errorType) {
      case ErrorType.database:
        return AppColors.error;
      case ErrorType.api:
        return AppColors.primaryAccent;
      case ErrorType.missingExecutable:
        return AppColors.secondaryAccent;
      case ErrorType.generic:
        return AppColors.error;
    }
  }

  String _getTitle(AppLocalizations? l10n) {
    switch (widget.errorType) {
      case ErrorType.database:
        return l10n?.errorDatabaseTitle ?? 'Database Error';
      case ErrorType.api:
        return l10n?.errorApiTitle ?? 'Connection Error';
      case ErrorType.missingExecutable:
        return l10n?.errorMissingExecutableTitle ?? 'Missing Executable';
      case ErrorType.generic:
        return l10n?.errorGenericTitle ?? 'Something Went Wrong';
    }
  }

  String _getDefaultMessage(AppLocalizations? l10n) {
    switch (widget.errorType) {
      case ErrorType.database:
        return l10n?.errorDatabaseMessage ??
            'Failed to access the game database. Please restart the application.';
      case ErrorType.api:
        return l10n?.errorApiMessage ??
            'Could not connect to game database. You can still play your games.';
      case ErrorType.missingExecutable:
        return l10n?.errorMissingExecutableMessage ??
            'The game executable is missing. Please browse for a new location.';
      case ErrorType.generic:
        return l10n?.errorGenericMessage ??
            'An unexpected error occurred. Please try again.';
    }
  }
}

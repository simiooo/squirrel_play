import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// Enhanced empty state widget with specific variants and illustrations.
///
/// Supports:
/// - No games state
/// - No search results state
/// - API unreachable state
class EnhancedEmptyState extends StatefulWidget {
  /// The type of empty state.
  final EmptyStateType type;

  /// Callback when CTA button is pressed.
  final VoidCallback? onPrimaryAction;

  /// Callback when secondary button is pressed.
  final VoidCallback? onSecondaryAction;

  /// Creates an EnhancedEmptyState widget.
  const EnhancedEmptyState({
    super.key,
    this.type = EmptyStateType.noGames,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  /// Creates a no games empty state.
  const EnhancedEmptyState.noGames({
    super.key,
    this.onPrimaryAction,
    this.onSecondaryAction,
  }) : type = EmptyStateType.noGames;

  /// Creates a no search results empty state.
  const EnhancedEmptyState.noSearchResults({
    super.key,
    this.onPrimaryAction,
    this.onSecondaryAction,
  }) : type = EmptyStateType.noSearchResults;

  /// Creates an API unreachable empty state.
  const EnhancedEmptyState.apiUnreachable({
    super.key,
    this.onPrimaryAction,
  })  : type = EmptyStateType.apiUnreachable,
        onSecondaryAction = null;

  @override
  State<EnhancedEmptyState> createState() => _EnhancedEmptyStateState();
}

/// Enum representing different empty state types.
enum EmptyStateType {
  /// No games in library.
  noGames,

  /// No search results.
  noSearchResults,

  /// API unreachable.
  apiUnreachable,
}

class _EnhancedEmptyStateState extends State<EnhancedEmptyState> {
  late FocusNode _primaryFocusNode;
  late FocusNode? _secondaryFocusNode;

  @override
  void initState() {
    super.initState();
    _primaryFocusNode = FocusNode(debugLabel: 'EmptyStatePrimary');
    if (widget.type == EmptyStateType.noGames) {
      _secondaryFocusNode = FocusNode(debugLabel: 'EmptyStateSecondary');
    } else {
      _secondaryFocusNode = null;
    }

    // Register empty-state buttons as content nodes for focus traversal
    if (widget.onPrimaryAction != null) {
      FocusTraversalService.instance.registerContentNode(_primaryFocusNode);
    }
    if (widget.type == EmptyStateType.noGames &&
        widget.onSecondaryAction != null) {
      FocusTraversalService.instance
          .registerContentNode(_secondaryFocusNode!);
    }
  }

  @override
  void dispose() {
    FocusTraversalService.instance.unregisterContentNode(_primaryFocusNode);
    if (_secondaryFocusNode != null) {
      FocusTraversalService.instance
          .unregisterContentNode(_secondaryFocusNode!);
    }
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
            // Illustration
            _buildIllustration(),
            const SizedBox(height: AppSpacing.xxl),

            // Title
            Text(
              _getTitle(l10n),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Message
            Text(
              _getMessage(l10n),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // CTA buttons
            _buildActionButtons(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    // Use placeholder icons until SVG assets are available
    final iconData = _getIconData();
    final iconColor = _getIconColor();

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withAlpha(77),
            iconColor.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Icon(
        iconData,
        size: 64,
        color: iconColor,
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations? l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
        // Primary button
        if (widget.onPrimaryAction != null)
          FocusableButton(
            focusNode: _primaryFocusNode,
            label: _getPrimaryButtonLabel(l10n),
            isPrimary: true,
            onPressed: widget.onPrimaryAction!,
          ),

        // Secondary button (only for no games state)
        if (widget.type == EmptyStateType.noGames &&
            widget.onSecondaryAction != null)
          FocusableButton(
            focusNode: _secondaryFocusNode!,
            label: l10n?.buttonScanDirectory ?? 'Scan Directory',
            onPressed: widget.onSecondaryAction!,
          ),
      ],
    );
  }

  IconData _getIconData() {
    switch (widget.type) {
      case EmptyStateType.noGames:
        return Icons.videogame_asset_outlined;
      case EmptyStateType.noSearchResults:
        return Icons.search_off_outlined;
      case EmptyStateType.apiUnreachable:
        return Icons.cloud_off_outlined;
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case EmptyStateType.noGames:
        return AppColors.primaryAccent;
      case EmptyStateType.noSearchResults:
        return AppColors.textSecondary;
      case EmptyStateType.apiUnreachable:
        return AppColors.error;
    }
  }

  String _getTitle(AppLocalizations? l10n) {
    switch (widget.type) {
      case EmptyStateType.noGames:
        return l10n?.emptyStateNoGamesTitle ?? 'No Games Yet';
      case EmptyStateType.noSearchResults:
        return l10n?.emptyStateNoSearchResultsTitle ?? 'No Results';
      case EmptyStateType.apiUnreachable:
        return l10n?.emptyStateApiUnreachableTitle ?? "Can't Connect";
    }
  }

  String _getMessage(AppLocalizations? l10n) {
    switch (widget.type) {
      case EmptyStateType.noGames:
        return l10n?.emptyStateNoGamesMessage ??
            'Add your first game to get started';
      case EmptyStateType.noSearchResults:
        return l10n?.emptyStateNoSearchResultsMessage ??
            'Try a different search term';
      case EmptyStateType.apiUnreachable:
        return l10n?.emptyStateApiUnreachableMessage ??
            'Game info unavailable. You can still play your games.';
    }
  }

  String _getPrimaryButtonLabel(AppLocalizations? l10n) {
    switch (widget.type) {
      case EmptyStateType.noGames:
        return l10n?.emptyStateAddGame ?? 'Add your first game';
      case EmptyStateType.noSearchResults:
        return l10n?.buttonBack ?? 'Clear Search';
      case EmptyStateType.apiUnreachable:
        return l10n?.buttonRetry ?? 'Retry';
    }
  }
}

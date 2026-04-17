import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// Empty state widget for the home page.
///
/// Shows when no games exist in the library.
/// Features:
/// - Large icon/illustration
/// - Welcoming message
/// - "Add Game" CTA button
/// - "Scan Directory" secondary button
class EmptyHomeState extends StatefulWidget {
  /// Callback when "Add Game" button is pressed.
  final VoidCallback onAddGame;

  /// Callback when "Scan Directory" button is pressed.
  final VoidCallback? onScanDirectory;

  /// Whether scan directories exist (for contextual messaging).
  final bool hasScanDirectories;

  /// Creates an EmptyHomeState widget.
  const EmptyHomeState({
    super.key,
    required this.onAddGame,
    this.onScanDirectory,
    this.hasScanDirectories = false,
  });

  @override
  State<EmptyHomeState> createState() => _EmptyHomeStateState();
}

class _EmptyHomeStateState extends State<EmptyHomeState> {
  late FocusNode _addGameFocusNode;
  late FocusNode _scanDirectoryFocusNode;

  @override
  void initState() {
    super.initState();
    _addGameFocusNode = FocusNode(debugLabel: 'EmptyStateAddGame');
    _scanDirectoryFocusNode = FocusNode(debugLabel: 'EmptyStateScanDirectory');

    // Register empty-state buttons as content nodes for focus traversal
    FocusTraversalService.instance.registerContentNode(_addGameFocusNode);
    if (widget.onScanDirectory != null) {
      FocusTraversalService.instance.registerContentNode(_scanDirectoryFocusNode);
    }
  }

  @override
  void dispose() {
    FocusTraversalService.instance.unregisterContentNode(_addGameFocusNode);
    FocusTraversalService.instance.unregisterContentNode(_scanDirectoryFocusNode);
    _addGameFocusNode.dispose();
    _scanDirectoryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon/illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent.withAlpha(77),
                    AppColors.primaryAccent.withAlpha(26),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadii.large),
              ),
              child: const Icon(
                Icons.videogame_asset_outlined,
                size: 64,
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Title
            Text(
              l10n?.libraryEmptyState ?? 'Your game library is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle
            Text(
              l10n?.emptyStateSubtitle ?? 'Add your first game to get started',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // CTA buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add Game button
                FocusableButton(
                  focusNode: _addGameFocusNode,
                  label: l10n?.emptyStateAddGame ?? 'Add your first game',
                  isPrimary: true,
                  onPressed: () {
                    SoundService.instance.playFocusSelect();
                    widget.onAddGame();
                  },
                ),
                const SizedBox(width: AppSpacing.lg),

                // Scan Directory button (if callback provided)
                if (widget.onScanDirectory != null)
                  FocusableButton(
                    focusNode: _scanDirectoryFocusNode,
                    label: l10n?.buttonScanDirectory ?? 'Scan Directory',
                    isPrimary: false,
                    onPressed: () {
                      SoundService.instance.playFocusSelect();
                      widget.onScanDirectory!();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

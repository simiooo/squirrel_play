import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/quick_scan/quick_scan_bloc.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/add_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/scan_notification.dart';

/// The top navigation bar for the application.
///
/// A fixed 64px height bar containing:
/// - Left: System time display (updates every minute)
/// - Center: App logo/title
/// - Right: Action buttons (Home, Add Game, Game Library, Refresh, Settings)
///
/// Each button uses [FocusableButton] for gamepad navigation with
/// focus animations and sound hooks.
class TopBar extends StatefulWidget {
  /// Creates a top bar.
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  late final List<FocusNode> _buttonFocusNodes;
  late final FocusNode _refreshFocusNode;
  late final Timer _timeTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Create focus nodes for the four buttons (Home is index 0)
    _buttonFocusNodes = [
      FocusNode(debugLabel: 'HomeButton'),
      FocusNode(debugLabel: 'AddGameButton'),
      FocusNode(debugLabel: 'GameLibraryButton'),
      FocusNode(debugLabel: 'SettingsButton'),
    ];

    // Separate focus node for refresh icon
    _refreshFocusNode = FocusNode(debugLabel: 'RefreshButton');

    // Register focus nodes with the traversal service
    for (final node in _buttonFocusNodes) {
      FocusTraversalService.instance.registerTopBarNode(node);
    }
    FocusTraversalService.instance.registerTopBarNode(_refreshFocusNode);

    // Update time every minute
    _timeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _currentTime = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timeTimer.cancel();

    // Unregister focus nodes
    for (final node in _buttonFocusNodes) {
      FocusTraversalService.instance.unregisterTopBarNode(node);
      node.dispose();
    }
    FocusTraversalService.instance.unregisterTopBarNode(_refreshFocusNode);
    _refreshFocusNode.dispose();

    super.dispose();
  }

  void _handleHome(BuildContext context) {
    // Play page transition sound first
    SoundService.instance.playPageTransition();
    // Navigate to home page
    context.go('/');
  }

  void _handleAddGame(BuildContext context) {
    // Play page transition sound first
    SoundService.instance.playPageTransition();
    // Open Add Game dialog
    AddGameDialog.show(context);
  }

  void _handleGameLibrary(BuildContext context) {
    // Play page transition sound first
    SoundService.instance.playPageTransition();
    // Navigate to library page
    context.go('/library');
  }

  void _handleRefresh(BuildContext context) {
    // Play select sound
    SoundService.instance.playFocusSelect();
    // Dispatch quick scan request
    context.read<QuickScanBloc>().add(const QuickScanRequested());
  }

  void _handleSettings(BuildContext context) {
    // Play page transition sound first
    SoundService.instance.playPageTransition();
    // Navigate to settings page
    context.go('/settings');
  }

  void _handleDismissNotification(BuildContext context) {
    context.read<QuickScanBloc>().add(const QuickScanCancelled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<QuickScanBloc, QuickScanState>(
      builder: (context, scanState) {
        final isScanning = scanState is QuickScanScanning;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main TopBar
            Container(
              height: AppSpacing.xxxxl,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(
                  (AppColors.surfaceOpacity * 255).round(),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.backgroundDeep.withAlpha(128),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left: System time
                  _buildTimeDisplay(),

                  // Center: App title
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n?.appTitle ?? 'Squirrel Play',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Right: Action buttons
                  Row(
                    children: [
                      // Home button (index 0)
                      FocusableButton(
                        focusNode: _buttonFocusNodes[0],
                        label: l10n?.topBarHome ?? 'Home',
                        hint: l10n?.focusHomeHint ?? 'Return to home page',
                        onPressed: () => _handleHome(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Add Game button (index 1)
                      FocusableButton(
                        focusNode: _buttonFocusNodes[1],
                        label: l10n?.topBarAddGame ?? 'Add Game',
                        hint: l10n?.focusAddGameHint ??
                            'Add a new game to your library',
                        onPressed: () => _handleAddGame(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Game Library button (index 2)
                      FocusableButton(
                        focusNode: _buttonFocusNodes[2],
                        label: l10n?.topBarGameLibrary ?? 'Game Library',
                        hint: l10n?.focusGameLibraryHint ??
                            'View all games in your library',
                        onPressed: () => _handleGameLibrary(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Refresh icon button
                      _buildRefreshButton(context, isScanning),
                      const SizedBox(width: AppSpacing.sm),
                      // Settings button (index 3)
                      FocusableButton(
                        focusNode: _buttonFocusNodes[3],
                        label: l10n?.topBarSettings ?? 'Settings',
                        hint: l10n?.focusSettingsHint ??
                            'Open application settings',
                        onPressed: () => _handleSettings(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Scan notification overlay
            _buildScanNotification(scanState),
          ],
        );
      },
    );
  }

  Widget _buildRefreshButton(BuildContext context, bool isScanning) {
    final l10n = AppLocalizations.of(context);

    return FocusableActionDetector(
      focusNode: _refreshFocusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          SoundService.instance.playFocusMove();
        }
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            _handleRefresh(context);
            return null;
          },
        ),
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;

          return GestureDetector(
            onTap: () => _handleRefresh(context),
            child: AnimatedContainer(
              duration: AppAnimationDurations.focusIn,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.medium),
                border: hasFocus
                    ? Border.all(
                        color: AppColors.primaryAccent,
                        width: 2,
                      )
                    : null,
                color: hasFocus
                    ? AppColors.surfaceElevated
                    : Colors.transparent,
              ),
              child: Tooltip(
                message: l10n?.topBarRefreshHint ?? 'Refresh game library',
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: isScanning
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryAccent,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: hasFocus
                              ? AppColors.primaryAccent
                              : AppColors.textSecondary,
                          size: 24,
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanNotification(QuickScanState state) {
    final visible = state is! QuickScanIdle;

    return ScanNotification(
      visible: visible,
      isScanning: state is QuickScanScanning,
      newGamesCount: state is QuickScanComplete ? state.newGamesFound : null,
      gameNames: state is QuickScanComplete
          ? state.addedGames.map((g) => g.title).toList()
          : null,
      noDirectoriesConfigured:
          state is QuickScanNoNewGames ? state.noDirectoriesConfigured : false,
      errorMessage: state is QuickScanError ? state.message : null,
      onDismiss: () => _handleDismissNotification(context),
    );
  }

  /// Builds the time display widget.
  Widget _buildTimeDisplay() {
    final hour = _currentTime.hour.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');

    return Text(
      '$hour:$minute',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}

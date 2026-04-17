import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/add_game/add_game_bloc.dart';
import 'package:squirrel_play/presentation/blocs/steam_scanner/steam_scanner_bloc.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/manual_add_tab.dart';
import 'package:squirrel_play/presentation/widgets/scan_directory_tab.dart';
import 'package:squirrel_play/presentation/widgets/steam_games_tab.dart';

/// A dialog for adding games to the library.
///
/// Features:
/// - Three tabs: "Manual Add", "Scan Directory", and "Steam Games"
/// - Manual add: file picker for .exe, game name input
/// - Scan directory: directory picker, recursive scan, checkbox list
/// - Steam Games: auto-detect Steam, scan library, import games
/// - Gamepad-navigable tab switching (left/right arrows)
/// - Focus trapping while dialog is open
/// - Sound hooks on open/close
class AddGameDialog extends StatefulWidget {
  /// Creates the Add Game dialog.
  ///
  /// [initialTab] - Which tab to show initially (0 = Manual Add, 1 = Scan Directory)
  /// [isRescan] - Whether this is a rescan operation (pre-populates directories)
  const AddGameDialog({
    super.key,
    this.initialTab = 0,
    this.isRescan = false,
  });

  /// Shows the dialog with the given context.
  static Future<void> show(
    BuildContext context, {
    int initialTab = 0,
    bool isRescan = false,
  }) async {
    final focusNode = FocusManager.instance.primaryFocus;

    // Play open sound
    SoundService.instance.playFocusSelect();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider(
        create: (_) => getIt<AddGameBloc>()
          ..add(initialTab == 0
              ? const StartManualAdd()
              : StartScanFlow(isRescan: isRescan)),
        child: AddGameDialog(
          initialTab: initialTab,
          isRescan: isRescan,
        ),
      ),
    );

    // Restore focus when dialog closes
    if (focusNode != null) {
      focusNode.requestFocus();
    }
  }

  final int initialTab;
  final bool isRescan;

  @override
  State<AddGameDialog> createState() => _AddGameDialogState();
}

class _AddGameDialogState extends State<AddGameDialog>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  final List<FocusNode> _tabFocusNodes = [];
  final List<FocusNode> _dialogFocusNodes = [];
  FocusNode? _triggerNode;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _selectedTabIndex = widget.initialTab;

    // Initialize animation controller for open/close animations
    _animationController = AnimationController(
      vsync: this,
      duration: AppAnimationDurations.dialogOpen,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimationCurves.dialogOpen,
      ),
    );

    // Create focus nodes for tabs (3 tabs now)
    _tabFocusNodes.addAll([
      FocusNode(debugLabel: 'ManualAddTab'),
      FocusNode(debugLabel: 'ScanDirectoryTab'),
      FocusNode(debugLabel: 'SteamGamesTab'),
    ]);

    // Create focus nodes for dialog elements
    _dialogFocusNodes.addAll([
      FocusNode(debugLabel: 'CloseButton'),
    ]);

    // Store the trigger node (what opened the dialog)
    _triggerNode = FocusManager.instance.primaryFocus;

    // Enter dialog focus mode and start open animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusTraversalService.instance.enterDialogMode(
        'addGameDialog',
        [..._tabFocusNodes, ..._dialogFocusNodes],
        _triggerNode,
        onCancel: _closeDialog,
      );
      // Focus the first tab
      _tabFocusNodes[_selectedTabIndex].requestFocus();
      // Start open animation
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final node in _tabFocusNodes) {
      node.dispose();
    }
    for (final node in _dialogFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _switchTab(int index) {
    if (index != _selectedTabIndex && index >= 0 && index < _tabFocusNodes.length) {
      setState(() {
        _selectedTabIndex = index;
      });
      _tabFocusNodes[index].requestFocus();
      SoundService.instance.playFocusMove();

      // Notify BLoC of tab switch (only for first 2 tabs, Steam tab handles itself)
      if (index < 2) {
        context.read<AddGameBloc>().add(SwitchTab(index));
      }
    }
  }

  void _closeDialog() {
    SoundService.instance.playFocusBack();
    FocusTraversalService.instance.exitDialogMode();

    // Animate close (scale down) then pop
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AddGameBloc, AddGameState>(
      listener: (context, state) {
        // Close dialog when adding is complete (state returns to AddGameInitial after success)
        if (state is AddGameInitial) {
          _closeDialog();
        }
      },
      child: KeyboardListener(
        focusNode: FocusNode(debugLabel: 'DialogKeyboardListener'),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            switch (event.logicalKey) {
              case LogicalKeyboardKey.arrowLeft:
                if (_selectedTabIndex > 0) {
                  _switchTab(_selectedTabIndex - 1);
                }
                return;
              case LogicalKeyboardKey.arrowRight:
                if (_selectedTabIndex < _tabFocusNodes.length - 1) {
                  _switchTab(_selectedTabIndex + 1);
                }
                return;
              case LogicalKeyboardKey.escape:
                _closeDialog();
                return;
            }
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.large),
            ),
            title: Text(
              l10n?.dialogAddGameTitle ?? 'Add Game',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            content: SizedBox(
              width: 600,
              height: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadii.medium),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTab(
                            index: 0,
                            label: l10n?.dialogAddGameManualTab ?? 'Manual Add',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildTab(
                            index: 1,
                            label: l10n?.dialogAddGameScanTab ?? 'Scan Directory',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _buildTab(
                            index: 2,
                            label: l10n?.dialogAddGameSteamTab ?? 'Steam Games',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tab content
                  Expanded(
                    child: _buildTabContent(),
                  ),
                ],
              ),
            ),
            actions: [
              FocusableButton(
                focusNode: _dialogFocusNodes[0],
                label: l10n?.dialogClose ?? 'Close',
                onPressed: _closeDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({required int index, required String label}) {
    final isSelected = _selectedTabIndex == index;
    final isFocused = _tabFocusNodes[index].hasFocus;

    return Focus(
      focusNode: _tabFocusNodes[index],
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryAccent
                : (isFocused ? AppColors.surfaceElevated : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.lg,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected || isFocused
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: _buildTabContentForIndex(_selectedTabIndex),
    );
  }

  Widget _buildTabContentForIndex(int index) {
    switch (index) {
      case 0:
        return const ManualAddTab();
      case 1:
        return ScanDirectoryTab(isRescan: widget.isRescan);
      case 2:
        return BlocProvider(
          create: (_) => getIt<SteamScannerBloc>(),
          child: const SteamGamesTab(),
        );
      default:
        return const ManualAddTab();
    }
  }
}

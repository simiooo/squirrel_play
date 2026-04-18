import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// A confirmation dialog for deleting a game.
///
/// Features:
/// - Shows game title in confirmation message
/// - Delete and Cancel buttons (both gamepad-focusable)
/// - Focus trapping while dialog is open
/// - Sound hooks on open/close
class DeleteGameDialog extends StatefulWidget {
  /// Creates the delete game dialog.
  const DeleteGameDialog({
    super.key,
    required this.game,
  });

  /// The game to be deleted.
  final Game game;

  /// Shows the dialog and returns true if delete was confirmed.
  static Future<bool> show(BuildContext context, Game game) async {
    final focusNode = FocusManager.instance.primaryFocus;

    // Play open sound
    SoundService.instance.playFocusSelect();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteGameDialog(game: game),
    );

    // Restore focus when dialog closes
    if (focusNode != null) {
      focusNode.requestFocus();
    }

    return result ?? false;
  }

  @override
  State<DeleteGameDialog> createState() => _DeleteGameDialogState();
}

class _DeleteGameDialogState extends State<DeleteGameDialog>
    with SingleTickerProviderStateMixin {
  late final List<FocusNode> _buttonFocusNodes;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _buttonFocusNodes = [
      FocusNode(debugLabel: 'DeleteButton'),
      FocusNode(debugLabel: 'CancelButton'),
    ];

    // Initialize animation controller
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

    // Focus the cancel button by default (safer) after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buttonFocusNodes[1].requestFocus();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final node in _buttonFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _confirmDelete() {
    SoundService.instance.playFocusSelect();
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  void _cancel() {
    SoundService.instance.playFocusBack();
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return KeyboardListener(
      focusNode: FocusNode(debugLabel: 'DeleteDialogKeyboardListener'),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.escape:
              _cancel();
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
            l10n!.dialogDeleteGameTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            l10n.dialogDeleteGameMessage(widget.game.title),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            FocusableButton(
              focusNode: _buttonFocusNodes[0],
              label: l10n.dialogDeleteGameConfirm,
              onPressed: _confirmDelete,
            ),
            FocusableButton(
              focusNode: _buttonFocusNodes[1],
              label: l10n.buttonCancel,
              isPrimary: true,
              onPressed: _cancel,
            ),
          ],
        ),
      ),
    );
  }
}

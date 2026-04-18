import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/focusable_text_field.dart';
import 'package:squirrel_play/presentation/widgets/gamepad_file_browser.dart';

/// A dialog for editing a game's metadata.
///
/// Features:
/// - Focusable fields for title, executable path, and launch arguments
/// - File browser for selecting a new executable path
/// - Focus trapping via [FocusScope]
/// - Sound hooks on open/close
class EditGameDialog extends StatefulWidget {
  /// Creates the edit game dialog.
  const EditGameDialog({
    super.key,
    required this.game,
    required this.onSave,
  });

  /// The game to be edited.
  final Game game;

  /// Callback invoked when the user saves changes.
  final ValueChanged<Game> onSave;

  /// Shows the dialog and returns true if changes were saved.
  static Future<bool> show(
    BuildContext context,
    Game game,
    ValueChanged<Game> onSave,
  ) async {
    final focusNode = FocusManager.instance.primaryFocus;

    // Play open sound
    SoundService.instance.playFocusSelect();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditGameDialog(
        game: game,
        onSave: onSave,
      ),
    );

    // Restore focus when dialog closes
    if (focusNode != null) {
      focusNode.requestFocus();
    }

    return result ?? false;
  }

  @override
  State<EditGameDialog> createState() => _EditGameDialogState();
}

class _EditGameDialogState extends State<EditGameDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleController;
  late final TextEditingController _executablePathController;
  late final TextEditingController _launchArgumentsController;

  late final FocusNode _titleFocusNode;
  late final FocusNode _executablePathFocusNode;
  late final FocusNode _launchArgumentsFocusNode;
  late final FocusNode _saveButtonFocusNode;
  late final FocusNode _cancelButtonFocusNode;
  late final FocusNode _browseButtonFocusNode;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing values
    _titleController = TextEditingController(text: widget.game.title);
    _executablePathController = TextEditingController(
      text: widget.game.executablePath,
    );
    _launchArgumentsController = TextEditingController(
      text: widget.game.launchArguments ?? '',
    );

    // Initialize focus nodes
    _titleFocusNode = FocusNode(debugLabel: 'EditTitle');
    _executablePathFocusNode = FocusNode(debugLabel: 'EditExecutablePath');
    _launchArgumentsFocusNode = FocusNode(debugLabel: 'EditLaunchArguments');
    _saveButtonFocusNode = FocusNode(debugLabel: 'EditSaveButton');
    _cancelButtonFocusNode = FocusNode(debugLabel: 'EditCancelButton');
    _browseButtonFocusNode = FocusNode(debugLabel: 'EditBrowseButton');

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

    // Focus the title field by default after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _executablePathController.dispose();
    _launchArgumentsController.dispose();
    _titleFocusNode.dispose();
    _executablePathFocusNode.dispose();
    _launchArgumentsFocusNode.dispose();
    _saveButtonFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    _browseButtonFocusNode.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final executablePath = _executablePathController.text.trim();
    final launchArguments = _launchArgumentsController.text.trim();

    if (title.isEmpty || executablePath.isEmpty) {
      return;
    }

    final updatedGame = widget.game.copyWith(
      title: title,
      executablePath: executablePath,
      launchArguments: launchArguments.isEmpty ? null : launchArguments,
    );

    SoundService.instance.playFocusSelect();
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSave(updatedGame);
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

  void _browseForExecutable() {
    GamepadFileBrowser.show(
      context,
      mode: FileBrowserMode.file,
      allowedExtensions: const ['exe', 'sh', 'bin', 'appimage'],
      onSelected: (paths) {
        if (paths.isNotEmpty) {
          setState(() {
            _executablePathController.text = paths.first;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return KeyboardListener(
      focusNode: FocusNode(debugLabel: 'EditDialogKeyboardListener'),
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
            l10n!.dialogEditGameTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: FocusScope(
            autofocus: true,
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title field
                  FocusableTextField(
                    focusNode: _titleFocusNode,
                    controller: _titleController,
                    labelText: l10n.dialogEditGameTitleLabel,
                    hintText: l10n.dialogEditGameTitleHint,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Executable path field with browse button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FocusableTextField(
                          focusNode: _executablePathFocusNode,
                          controller: _executablePathController,
                          labelText: l10n.dialogEditGameExecutableLabel,
                          hintText: l10n.dialogEditGameExecutableHint,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FocusableButton(
                        focusNode: _browseButtonFocusNode,
                        label: l10n.dialogEditGameBrowse,
                        icon: Icons.folder_open,
                        onPressed: _browseForExecutable,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Launch arguments field
                  FocusableTextField(
                    focusNode: _launchArgumentsFocusNode,
                    controller: _launchArgumentsController,
                    labelText: l10n.dialogEditGameArgumentsLabel,
                    hintText: l10n.dialogEditGameArgumentsHint,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FocusableButton(
              focusNode: _saveButtonFocusNode,
              label: l10n.buttonSave,
              isPrimary: true,
              onPressed: _save,
            ),
            FocusableButton(
              focusNode: _cancelButtonFocusNode,
              label: l10n.buttonCancel,
              onPressed: _cancel,
            ),
          ],
        ),
      ),
    );
  }
}

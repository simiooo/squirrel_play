import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/validators/executable_path_input.dart';
import 'package:squirrel_play/domain/validators/game_name_input.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/add_game/add_game_bloc.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/focusable_text_field.dart';
import 'package:squirrel_play/presentation/widgets/gamepad_file_browser.dart';
import 'package:squirrel_play/presentation/widgets/picker_button.dart';

/// Tab content for manual game addition.
///
/// Features:
/// - File picker button for selecting .exe files
/// - Game name input with formz validation
/// - Selected file display
/// - Confirm button (disabled until valid)
class ManualAddTab extends StatefulWidget {
  /// Creates the manual add tab.
  const ManualAddTab({super.key});

  @override
  State<ManualAddTab> createState() => _ManualAddTabState();
}

class _ManualAddTabState extends State<ManualAddTab> {
  late final FocusNode _filePickerFocusNode;
  late final FocusNode _nameInputFocusNode;
  late final FocusNode _confirmFocusNode;

  final _nameController = TextEditingController();

  GameNameInput _nameInput = const GameNameInput.pure();
  ExecutablePathInput _pathInput = const ExecutablePathInput.pure();

  @override
  void initState() {
    super.initState();
    _filePickerFocusNode = FocusNode(debugLabel: 'FilePickerButton');
    _nameInputFocusNode = FocusNode(debugLabel: 'NameInput');
    _confirmFocusNode = FocusNode(debugLabel: 'ConfirmButton');
  }

  @override
  void dispose() {
    _filePickerFocusNode.dispose();
    _nameInputFocusNode.dispose();
    _confirmFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    SoundService.instance.playFocusSelect();

    await GamepadFileBrowser.show(
      context,
      mode: FileBrowserMode.file,
      allowedExtensions: ['exe'],
      onSelected: (paths) {
        if (paths.isEmpty) return;
        final path = paths.first;
        final fileName = path.split('/').last;

        if (mounted) {
          context.read<AddGameBloc>().add(FileSelected(
            path: path,
            fileName: fileName,
          ));

          setState(() {
            _pathInput = ExecutablePathInput.dirty(path);
          });

          // Auto-populate name if empty
          if (_nameController.text.isEmpty) {
            final suggestedName = fileName
                .replaceAll('.exe', '')
                .replaceAll('_', ' ')
                .replaceAll('-', ' ');
            _nameController.text = suggestedName;
            _nameInput = GameNameInput.dirty(suggestedName);
            context.read<AddGameBloc>().add(NameChanged(suggestedName));
          }
        }
      },
    );
  }

  void _onNameChanged(String value) {
    setState(() {
      _nameInput = GameNameInput.dirty(value);
    });
    context.read<AddGameBloc>().add(NameChanged(value));
  }

  void _confirmAdd() {
    if (_nameInput.isValid && _pathInput.isValid) {
      SoundService.instance.playFocusSelect();
      context.read<AddGameBloc>().add(const ConfirmManualAdd());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<AddGameBloc, AddGameState>(
      listener: (context, state) {
        if (state is ManualAddForm) {
          if (state.name != _nameController.text) {
            _nameController.text = state.name;
          }
          if (state.executablePath.isNotEmpty) {
            _pathInput = ExecutablePathInput.dirty(state.executablePath);
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File picker section
          Text(
            l10n?.manualAddExecutableLabel ?? 'Executable File',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.small),
                    border: Border.all(
                      color: _pathInput.isNotValid && !_pathInput.isPure
                          ? AppColors.error
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    _pathInput.value.isEmpty
                        ? (l10n?.manualAddNoFileSelected ?? 'No file selected')
                        : _pathInput.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _pathInput.value.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PickerButton(
                focusNode: _filePickerFocusNode,
                label: l10n?.manualAddBrowseButton ?? 'Browse...',
                icon: Icons.file_open,
                onPressed: _pickFile,
              ),
            ],
          ),
          if (_pathInput.isNotValid && !_pathInput.isPure)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _pathInput.errorMessage ?? (l10n?.manualAddInvalidFileError ?? 'Invalid file'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Game name input section
          Text(
            l10n?.manualAddGameNameLabel ?? 'Game Name',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FocusableTextField(
            focusNode: _nameInputFocusNode,
            controller: _nameController,
            hintText: l10n?.manualAddGameNameHint ?? 'Enter game name',
            errorText: _nameInput.isNotValid && !_nameInput.isPure
                ? (_nameInput.errorMessage ?? (l10n?.manualAddInvalidNameError ?? 'Invalid name'))
                : null,
            onChanged: _onNameChanged,
            onSubmitted: (_) => _confirmAdd(),
          ),

          const Spacer(),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FocusableButton(
              focusNode: _confirmFocusNode,
              label: l10n?.manualAddConfirmButton ?? 'Add Game',
              isPrimary: (_nameInput.isValid && _pathInput.isValid),
              onPressed: (_nameInput.isValid && _pathInput.isValid)
                  ? _confirmAdd
                  : () {}, // No-op when disabled
            ),
          ),
        ],
      ),
    );
  }
}
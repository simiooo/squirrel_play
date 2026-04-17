import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/validators/game_name_input.dart';
import 'package:squirrel_play/domain/validators/executable_path_input.dart';
import 'package:squirrel_play/presentation/blocs/add_game/add_game_bloc.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
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

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
      dialogTitle: 'Select Game Executable',
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      final path = result.files.single.path!;
      final fileName = result.files.single.name;

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
    } else {
      // File picker cancelled
      if (mounted) {
        context.read<AddGameBloc>().add(const FilePickerCancelled());
      }
    }
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
            'Executable File',
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
                        ? 'No file selected'
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
                label: 'Browse...',
                icon: Icons.file_open,
                onPressed: _pickFile,
              ),
            ],
          ),
          if (_pathInput.isNotValid && !_pathInput.isPure)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _pathInput.errorMessage ?? 'Invalid file',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Game name input section
          Text(
            'Game Name',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Focus(
            focusNode: _nameInputFocusNode,
            child: TextField(
              controller: _nameController,
              onChanged: _onNameChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  borderSide: const BorderSide(
                    color: AppColors.primaryAccent,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
                errorText: _nameInput.isNotValid && !_nameInput.isPure
                    ? (_nameInput.errorMessage ?? 'Invalid name')
                    : null,
                hintText: 'Enter game name',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FocusableButton(
              focusNode: _confirmFocusNode,
              label: 'Add Game',
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

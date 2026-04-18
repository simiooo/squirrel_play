import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/models/discovered_executable_model.dart';
import 'package:squirrel_play/data/services/file_scanner_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/scan_directory_repository.dart';
import 'package:squirrel_play/presentation/blocs/add_game/add_game_bloc.dart';
import 'package:squirrel_play/presentation/widgets/executable_checkbox_list.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/gamepad_file_browser.dart';
import 'package:squirrel_play/presentation/widgets/manage_directories_section.dart';
import 'package:squirrel_play/presentation/widgets/picker_button.dart';
import 'package:squirrel_play/presentation/widgets/scan_progress_indicator.dart';

/// Tab content for scan directory game addition.
///
/// Features:
/// - Directory picker for selecting multiple directories
/// - Manage saved directories section
/// - Start scan button
/// - Progress indicator during scan
/// - Checkbox list of discovered executables
/// - Select All / Select None buttons
/// - Confirm button to add selected games
class ScanDirectoryTab extends StatefulWidget {
  /// Creates the scan directory tab.
  ///
  /// [isRescan] - Whether this is a rescan operation (auto-starts scanning)
  const ScanDirectoryTab({
    super.key,
    this.isRescan = false,
  });

  final bool isRescan;

  @override
  State<ScanDirectoryTab> createState() => _ScanDirectoryTabState();
}

class _ScanDirectoryTabState extends State<ScanDirectoryTab> {
  late final FocusNode _addDirectoryFocusNode;
  late final FocusNode _startScanFocusNode;
  late final FocusNode _cancelScanFocusNode;
  late final FocusNode _selectAllFocusNode;
  late final FocusNode _selectNoneFocusNode;
  late final FocusNode _confirmFocusNode;

  final _fileScannerService = FileScannerService();
  StreamSubscription<ScanProgress>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _addDirectoryFocusNode = FocusNode(debugLabel: 'AddDirectoryButton');
    _startScanFocusNode = FocusNode(debugLabel: 'StartScanButton');
    _cancelScanFocusNode = FocusNode(debugLabel: 'CancelScanButton');
    _selectAllFocusNode = FocusNode(debugLabel: 'SelectAllButton');
    _selectNoneFocusNode = FocusNode(debugLabel: 'SelectNoneButton');
    _confirmFocusNode = FocusNode(debugLabel: 'ConfirmScanButton');

    // Load saved directories on init
    _loadSavedDirectories();
  }

  @override
  void dispose() {
    _addDirectoryFocusNode.dispose();
    _startScanFocusNode.dispose();
    _cancelScanFocusNode.dispose();
    _selectAllFocusNode.dispose();
    _selectNoneFocusNode.dispose();
    _confirmFocusNode.dispose();
    _scanSubscription?.cancel();
    _fileScannerService.cancelScan();
    super.dispose();
  }

  Future<void> _loadSavedDirectories() async {
    try {
      final repository = getIt<ScanDirectoryRepository>();
      final directories = await repository.getAllDirectories();

      if (mounted) {
        // Add loaded directories to BLoC
        for (final dir in directories) {
          context.read<AddGameBloc>().add(DirectorySelected(
            path: dir.path,
            directoryId: dir.id,
          ));
        }

        // If rescan and we have directories, auto-start scanning
        if (widget.isRescan && directories.isNotEmpty) {
          _startScan();
        }
      }
    } catch (e) {
      // Error loading directories - will show empty state
    }
  }

  Future<void> _addDirectory() async {
    SoundService.instance.playFocusSelect();

    await GamepadFileBrowser.show(
      context,
      mode: FileBrowserMode.directory,
      onSelected: (paths) async {
        if (paths.isEmpty) return;
        final result = paths.first;

        if (!mounted) return;

        // Check if directory already exists
        final repository = getIt<ScanDirectoryRepository>();
        final exists = await repository.directoryExists(result);

        if (!exists) {
          // Save to database
          final newDir = await repository.addDirectory(result);

          if (mounted) {
            context.read<AddGameBloc>().add(DirectorySelected(
              path: newDir.path,
              directoryId: newDir.id,
            ));
          }
        } else {
          // Directory already exists - just add to current list if not there
          final allDirs = await repository.getAllDirectories();
          final existing = allDirs.firstWhere((d) => d.path == result);

          if (mounted) {
            context.read<AddGameBloc>().add(DirectorySelected(
              path: existing.path,
              directoryId: existing.id,
            ));
          }
        }
      },
    );
  }

  void _removeDirectory(String directoryId) async {
    try {
      final repository = getIt<ScanDirectoryRepository>();
      await repository.deleteDirectory(directoryId);

      if (mounted) {
        context.read<AddGameBloc>().add(RemoveDirectory(directoryId));
      }
    } catch (e) {
      // Error removing directory
    }
  }

  void _startScan() {
    SoundService.instance.playFocusSelect();

    final state = context.read<AddGameBloc>().state;
    if (state is ScanDirectoryForm) {
      context.read<AddGameBloc>().add(const StartScan());

      // Get directory paths and IDs
      final directoryPaths = state.directories.map((d) => d.path).toList();
      final directoryIds = <String, String>{};
      for (final dir in state.directories) {
        directoryIds[dir.path] = dir.id;
      }

      // Start the actual file scan
      _scanSubscription?.cancel();
      _scanSubscription = _fileScannerService
          .scanDirectories(directoryPaths, directoryIds: directoryIds)
          .listen(
        (progress) {
          if (mounted) {
            context.read<AddGameBloc>().add(ScanProgressUpdated(
              directoriesScanned: progress.directoriesScanned,
              filesFound: progress.filesFound,
              currentPath: progress.currentPath,
              executables: progress.executables,
            ));

            if (progress.isComplete) {
              _onScanComplete(progress.executables);
            }
          }
        },
        onError: (error) {
          if (mounted) {
            context.read<AddGameBloc>().add(ScanError(error.toString()));
          }
        },
      );
    }
  }

  Future<void> _onScanComplete(List<DiscoveredExecutableModel> executables) async {
    // Check which executables are already in the library
    final gameRepository = getIt<GameRepository>();
    final checkedExecutables = <DiscoveredExecutableModel>[];

    for (final exe in executables) {
      final exists = await gameRepository.gameExists(exe.path);
      checkedExecutables.add(exe.copyWith(isAlreadyAdded: exists));
    }

    if (mounted) {
      context.read<AddGameBloc>().add(ScanCompleted(
        executables: checkedExecutables,
      ));

      // Update last scanned date for directories
      final scanRepo = getIt<ScanDirectoryRepository>();
      final state = context.read<AddGameBloc>().state;
      if (state is Scanning || state is ScanResults || state is EmptyScanResults) {
        final directories = state is Scanning
            ? state.directories
            : (state is ScanResults
                ? state.directories
                : (state as EmptyScanResults).directories);

        for (final dir in directories) {
          await scanRepo.updateLastScanned(dir.id, DateTime.now());
        }
      }
    }
  }

  void _cancelScan() {
    _fileScannerService.cancelScan();
    _scanSubscription?.cancel();
    context.read<AddGameBloc>().add(const CancelScan());
  }

  void _toggleExecutable(String path) {
    context.read<AddGameBloc>().add(ToggleExecutable(path));
  }

  void _selectAll() {
    context.read<AddGameBloc>().add(const SelectAllExecutables());
  }

  void _selectNone() {
    context.read<AddGameBloc>().add(const SelectNoneExecutables());
  }

  void _confirmSelection() {
    SoundService.instance.playFocusSelect();
    context.read<AddGameBloc>().add(const ConfirmScanSelection());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddGameBloc, AddGameState>(
      builder: (context, state) {
        if (state is ScanDirectoryForm) {
          return _buildScanForm(state);
        } else if (state is Scanning) {
          return _buildScanning(state);
        } else if (state is ScanResults) {
          return _buildScanResults(state);
        } else if (state is EmptyScanResults) {
          return _buildEmptyResults(state);
        } else if (state is Adding) {
          return _buildAdding();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildScanForm(ScanDirectoryForm state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add directory button
        PickerButton(
          focusNode: _addDirectoryFocusNode,
          label: AppLocalizations.of(context)?.scanDirectoryAddDirectoryButton ?? 'Add Directory',
          icon: Icons.folder_open,
          onPressed: _addDirectory,
        ),

        const SizedBox(height: AppSpacing.md),

        // Manage directories section
        Expanded(
          child: ManageDirectoriesSection(
            directories: state.directories,
            onRemove: _removeDirectory,
          ),
        ),

        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              state.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),

        // Start scan button
        SizedBox(
          width: double.infinity,
          child: FocusableButton(
            focusNode: _startScanFocusNode,
            label: AppLocalizations.of(context)?.scanDirectoryStartScanButton ?? 'Start Scan',
            isPrimary: state.canStartScan,
            onPressed: state.canStartScan ? _startScan : () {},
          ),
        ),
      ],
    );
  }

  Widget _buildScanning(Scanning state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScanProgressIndicator(
          directoriesScanned: state.directoriesScanned,
          filesFound: state.filesFound,
          currentPath: state.currentPath,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FocusableButton(
            focusNode: _cancelScanFocusNode,
            label: AppLocalizations.of(context)?.buttonCancel ?? 'Cancel',
            onPressed: _cancelScan,
          ),
        ),
      ],
    );
  }

  Widget _buildScanResults(ScanResults state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.scanDirectoryFoundExecutables(state.totalCount, state.selectedCount) ?? 'Found ${state.totalCount} executables (${state.selectedCount} selected)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Select all/none buttons
        Row(
          children: [
            Expanded(
              child: FocusableButton(
                focusNode: _selectAllFocusNode,
                label: AppLocalizations.of(context)?.scanDirectorySelectAllButton ?? 'Select All',
                onPressed: _selectAll,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FocusableButton(
                focusNode: _selectNoneFocusNode,
                label: AppLocalizations.of(context)?.scanDirectorySelectNoneButton ?? 'Select None',
                onPressed: _selectNone,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Checkbox list
        Expanded(
          child: ExecutableCheckboxList(
            executables: state.executables,
            onToggle: _toggleExecutable,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Confirm button
        SizedBox(
          width: double.infinity,
          child: FocusableButton(
            focusNode: _confirmFocusNode,
            label: AppLocalizations.of(context)?.scanDirectoryAddGamesButton(state.selectedCount) ?? 'Add ${state.selectedCount} Games',
            isPrimary: state.selectedCount > 0,
            onPressed: state.selectedCount > 0 ? _confirmSelection : () {},
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyResults(EmptyScanResults state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)?.scanDirectoryNoExecutablesTitle ?? 'No executables found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)?.scanDirectoryNoExecutablesSubtitle ?? 'Try selecting a different directory or check that .exe files exist.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FocusableButton(
            focusNode: _addDirectoryFocusNode,
            label: AppLocalizations.of(context)?.scanDirectorySelectDifferentDirectories ?? 'Select Different Directories',
            onPressed: () {
              context.read<AddGameBloc>().add(const StartScanFlow());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdding() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)?.scanDirectoryAddingGames ?? 'Adding games...',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
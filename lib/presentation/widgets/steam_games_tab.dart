import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/services/platform_info.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/steam_scanner/steam_scanner_bloc.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/gamepad_file_browser.dart';
import 'package:squirrel_play/presentation/widgets/picker_button.dart';

/// Tab widget for scanning and importing Steam games.
///
/// Features:
/// - Auto-detection of Steam installation
/// - Manual Steam path override
/// - List of installed Steam games with checkboxes
/// - Duplicate detection (shows "Already Added" for existing games)
/// - Gamepad-navigable checkboxes and buttons
class SteamGamesTab extends StatefulWidget {
  const SteamGamesTab({super.key});

  @override
  State<SteamGamesTab> createState() => _SteamGamesTabState();
}

class _SteamGamesTabState extends State<SteamGamesTab> {
  final FocusNode _browseFocusNode = FocusNode(debugLabel: 'SteamBrowseButton');
  final FocusNode _closeFocusNode = FocusNode(debugLabel: 'SteamCloseButton');
  final List<FocusNode> _checkboxFocusNodes = [];
  final List<FocusNode> _buttonFocusNodes = [];

  @override
  void initState() {
    super.initState();
    // Start Steam detection when tab is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SteamScannerBloc>().add(const DetectSteam());
    });
  }

  @override
  void dispose() {
    _browseFocusNode.dispose();
    _closeFocusNode.dispose();
    for (final node in _checkboxFocusNodes) {
      node.dispose();
    }
    for (final node in _buttonFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<SteamScannerBloc, SteamScannerState>(
      listener: (context, state) {
        // No listener needed - path selection is handled by GamepadFileBrowser
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: _buildContent(context, state, l10n),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, SteamScannerState state, AppLocalizations? l10n) {
    if (state is SteamScannerInitial) {
      return _buildLoadingState(
        l10n?.steamGamesInitializing ?? 'Initializing...',
      );
    }

    if (state is SteamScannerLoading) {
      return _buildLoadingState(_getLoadingMessage(l10n, state.type));
    }

    if (state is SteamScannerError) {
      return _buildErrorState(context, state, l10n);
    }

    if (state is SteamScannerLoaded) {
      return _buildLoadedState(context, state, l10n);
    }

    if (state is SteamScannerImporting) {
      return _buildImportingState(state);
    }

    if (state is SteamScannerImportComplete) {
      return _buildImportCompleteState(context, state, l10n);
    }

    return const SizedBox.shrink();
  }

  String _getLoadingMessage(AppLocalizations? l10n, SteamScannerLoadingType type) {
    switch (type) {
      case SteamScannerLoadingType.detecting:
        return l10n?.steamScannerDetecting ?? 'Detecting Steam installation...';
      case SteamScannerLoadingType.validating:
        return l10n?.steamScannerValidating ?? 'Validating Steam path...';
      case SteamScannerLoadingType.scanning:
        return l10n?.steamScannerScanning ?? 'Scanning Steam libraries...';
    }
  }

  String _getErrorMessage(AppLocalizations? l10n, SteamScannerError state) {
    switch (state.type) {
      case SteamScannerErrorType.notFound:
        return l10n?.steamScannerNotFound ??
            'Steam installation not found. Please specify the path manually.';
      case SteamScannerErrorType.detectError:
        return l10n?.steamScannerDetectError(state.details ?? '') ??
            'Error detecting Steam: ${state.details}';
      case SteamScannerErrorType.invalidPath:
        return l10n?.steamScannerInvalidPath ??
            'Invalid Steam path. Please check the path and try again.';
      case SteamScannerErrorType.validateError:
        return l10n?.steamScannerValidateError(state.details ?? '') ??
            'Error validating path: ${state.details}';
      case SteamScannerErrorType.noPathSet:
        return l10n?.steamScannerNoPathSet ??
            'No Steam path set. Please detect or specify Steam path first.';
      case SteamScannerErrorType.scanError:
        return l10n?.steamScannerScanError(state.details ?? '') ??
            'Error scanning library: ${state.details}';
    }
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    SteamScannerError state,
    AppLocalizations? l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _getErrorMessage(l10n, state),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n?.steamGamesDefaultPath(_getDefaultSteamPath()) ??
                'Default: ${_getDefaultSteamPath()}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PickerButton(
            focusNode: _browseFocusNode,
            label: l10n?.steamGamesBrowseSteamFolder ?? 'Browse for Steam Folder',
            icon: Icons.folder_open,
            onPressed: () async {
              SoundService.instance.playFocusSelect();
              await GamepadFileBrowser.show(
                context,
                mode: FileBrowserMode.directory,
                onSelected: (paths) {
                  if (paths.isNotEmpty) {
                    final path = paths.first;
                    context
                        .read<SteamScannerBloc>()
                        .add(SetSteamPath(path));
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(
    BuildContext context,
    SteamScannerLoaded state,
    AppLocalizations? l10n,
  ) {
    // Ensure we have enough focus nodes for checkboxes
    while (_checkboxFocusNodes.length < state.games.length) {
      _checkboxFocusNodes.add(FocusNode(debugLabel: 'Checkbox${_checkboxFocusNodes.length}'));
    }

    // Ensure we have focus nodes for buttons
    while (_buttonFocusNodes.length < 4) {
      _buttonFocusNodes.add(FocusNode(debugLabel: 'Button${_buttonFocusNodes.length}'));
    }

    final availableGames = state.games.where((g) => !g.isAlreadyAdded).toList();
    final selectedCount = state.selectedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with Steam path and action buttons
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.steamGamesSteamPathLabel ?? 'Steam Path:',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.steamPath,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FocusableButton(
                focusNode: _buttonFocusNodes[0],
                label: l10n?.steamGamesSelectAllButton ?? 'Select All',
                onPressed: availableGames.isNotEmpty
                    ? () {
                        context.read<SteamScannerBloc>().add(const SelectAll());
                        SoundService.instance.playFocusSelect();
                      }
                    : () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              FocusableButton(
                focusNode: _buttonFocusNodes[1],
                label: l10n?.steamGamesSelectNoneButton ?? 'Select None',
                onPressed: selectedCount > 0
                    ? () {
                        context.read<SteamScannerBloc>().add(const SelectNone());
                        SoundService.instance.playFocusSelect();
                      }
                    : () {},
              ),
              const SizedBox(width: AppSpacing.sm),
              FocusableButton(
                focusNode: _buttonFocusNodes[2],
                label: l10n?.topBarRescan ?? 'Rescan',
                onPressed: () {
                  context.read<SteamScannerBloc>().add(const ScanLibrary());
                  SoundService.instance.playFocusSelect();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Games count info
        Text(
          l10n?.steamGamesFoundGames(
                state.games.length,
                state.games.where((g) => g.isAlreadyAdded).length,
              ) ??
              'Found ${state.games.length} games (${state.games.where((g) => g.isAlreadyAdded).length} already added)',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Games list
        Expanded(
          child: state.games.isEmpty
              ? Center(
                  child: Text(
                    l10n?.steamGamesNoGamesFound ?? 'No Steam games found',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: state.games.length,
                  itemBuilder: (context, index) {
                    final game = state.games[index];
                    return _buildGameItem(context, game, index);
                  },
                ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Import button
        FocusableButton(
          focusNode: _buttonFocusNodes[3],
          label: selectedCount > 0
              ? (l10n?.steamGamesImportCountButton(selectedCount) ??
                  'Import $selectedCount Games')
              : (l10n?.steamGamesImportButton ?? 'Import Selected Games'),
          onPressed: selectedCount > 0
              ? () {
                  context.read<SteamScannerBloc>().add(const ImportSelectedGames());
                  SoundService.instance.playFocusSelect();
                }
              : () {},
        ),
      ],
    );
  }

  Widget _buildGameItem(
    BuildContext context,
    SteamGameViewModel game,
    int index,
  ) {
    final focusNode = index < _checkboxFocusNodes.length
        ? _checkboxFocusNodes[index]
        : FocusNode();

    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: game.isAlreadyAdded
            ? null
            : () {
                context.read<SteamScannerBloc>().add(ToggleGame(game.data.appId));
                SoundService.instance.playFocusSelect();
              },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: focusNode.hasFocus
                ? AppColors.surfaceElevated
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.small),
            border: focusNode.hasFocus
                ? Border.all(color: AppColors.primaryAccent, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Checkbox(
                value: game.isSelected,
                onChanged: game.isAlreadyAdded
                    ? null
                    : (value) {
                        context.read<SteamScannerBloc>().add(ToggleGame(game.data.appId));
                        SoundService.instance.playFocusSelect();
                      },
                activeColor: AppColors.primaryAccent,
                checkColor: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.data.name,
                      style: TextStyle(
                        color: game.isAlreadyAdded
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: game.isAlreadyAdded
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)?.steamGamesAppId(game.data.appId) ??
                          'App ID: ${game.data.appId}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (game.isAlreadyAdded) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadii.small),
                  ),
                  child: Text(
                    AppLocalizations.of(context)?.steamGamesAlreadyAdded ??
                        'Already Added',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Refresh metadata button for already-added games
                Focus(
                  debugLabel: 'RefreshMetadata-${game.data.appId}',
                  child: Builder(
                    builder: (context) {
                      final hasFocus = Focus.of(context).hasFocus;
                      return GestureDetector(
                        onTap: () {
                          context.read<SteamScannerBloc>().add(
                            RefreshAddedGameMetadata(game.data.appId),
                          );
                          SoundService.instance.playFocusSelect();
                        },
                        child: Tooltip(
                          message: AppLocalizations.of(context)
                                  ?.steamGamesRefreshMetadata ??
                              'Refresh Metadata',
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: hasFocus
                                  ? AppColors.primaryAccent
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.small),
                            ),
                            child: Icon(
                              Icons.refresh,
                              color: hasFocus
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportingState(SteamScannerImporting state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: state.progress > 0 ? state.progress : null,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)?.steamGamesImporting ??
                'Importing games...',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)
                    ?.steamGamesImportProgress(state.completed, state.total) ??
                '${state.completed} of ${state.total}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (state.currentGame != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.currentGame!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImportCompleteState(
    BuildContext context,
    SteamScannerImportComplete state,
    AppLocalizations? l10n,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            state.errors.isEmpty ? Icons.check_circle : Icons.warning,
            color: state.errors.isEmpty ? AppColors.success : AppColors.warning,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n?.steamGamesImportComplete ?? 'Import Complete!',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n?.steamGamesImportedCount(state.importedCount) ??
                '${state.importedCount} games imported',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (state.skippedCount > 0)
            Text(
              l10n?.steamGamesSkippedCount(state.skippedCount) ??
                  '${state.skippedCount} skipped',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          if (state.errors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.steamGamesErrorsLabel ?? 'Errors:',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...state.errors.map((error) {
                    final message = error.noExecutable
                        ? (l10n?.steamScannerNoExecutable(error.gameName) ??
                            '${error.gameName}: No executable found')
                        : (l10n?.steamScannerImportError(
                                error.gameName,
                                error.error ?? '',
                              ) ??
                            '${error.gameName}: ${error.error}');
                    return Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FocusableButton(
            focusNode: _closeFocusNode,
            label: l10n?.dialogClose ?? 'Close',
            onPressed: () {
              // Reset and close
              context.read<SteamScannerBloc>().add(const ResetScanner());
              // The dialog will close via the parent dialog's close button
            },
          ),
        ],
      ),
    );
  }

  String _getDefaultSteamPath() {
    // Get PlatformInfo from DI for testable platform detection
    final platformInfo = getIt<PlatformInfo>();

    // Provide platform-specific hints
    if (platformInfo.isLinux) {
      return '~/.steam/steam';
    } else if (platformInfo.isWindows) {
      return r'C:\Program Files (x86)\Steam';
    } else if (platformInfo.isMacOS) {
      return '~/Library/Application Support/Steam';
    }
    return '';
  }
}

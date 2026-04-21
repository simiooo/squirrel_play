import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/network_status_service.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/data/services/system_volume_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/quick_scan/quick_scan_bloc.dart';
import 'package:squirrel_play/presentation/widgets/add_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/error_localizer.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/scan_notification.dart';

/// The top navigation bar for the application.
///
/// A fixed 64px height bar containing:
/// - Left: System time display (updates every minute)
/// - Center: App logo/title
/// - Right: Action buttons (Home, Add Game, Game Library, Refresh),
///   system volume icon (with quick mute), and network status icons.
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
  late final FocusNode _volumeFocusNode;
  late final Timer _timeTimer;
  late final Timer _networkTimer;
  DateTime _currentTime = DateTime.now();

  double _volume = 0.8;
  bool _isMuted = false;
  List<NetworkInterfaceInfo> _networkInterfaces = [];

  @override
  void initState() {
    super.initState();

    // Create focus nodes for the three navigation buttons (Home is index 0)
    _buttonFocusNodes = [
      FocusNode(debugLabel: 'HomeButton'),
      FocusNode(debugLabel: 'AddGameButton'),
      FocusNode(debugLabel: 'GameLibraryButton'),
    ];

    // Separate focus nodes for refresh and volume icons
    _refreshFocusNode = FocusNode(debugLabel: 'RefreshButton');
    _volumeFocusNode = FocusNode(debugLabel: 'VolumeButton');

    // Update time every minute
    _timeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _currentTime = DateTime.now()),
    );

    // Refresh network status every 5 seconds
    _networkTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshNetworkStatus(),
    );

    // Initial load of volume and network status
    _refreshVolumeStatus();
    _refreshNetworkStatus();
  }

  @override
  void dispose() {
    _timeTimer.cancel();
    _networkTimer.cancel();

    // Dispose focus nodes
    for (final node in _buttonFocusNodes) {
      node.dispose();
    }
    _refreshFocusNode.dispose();
    _volumeFocusNode.dispose();

    super.dispose();
  }

  Future<void> _refreshVolumeStatus() async {
    try {
      final volumeService = getIt<SystemVolumeService>();
      final volume = await volumeService.getVolume();
      final muted = await volumeService.getMuted();
      if (mounted) {
        setState(() {
          _volume = volume;
          _isMuted = muted;
        });
      }
    } catch (e) {
      // Silently ignore volume read errors
    }
  }

  Future<void> _refreshNetworkStatus() async {
    try {
      final networkService = getIt<NetworkStatusService>();
      final interfaces = await networkService.getNetworkInterfaces();
      if (mounted) {
        setState(() {
          _networkInterfaces = interfaces;
        });
      }
    } catch (e) {
      // Silently ignore network read errors
    }
  }

  Future<void> _handleVolumeToggle() async {
    SoundService.instance.playFocusSelect();
    try {
      final volumeService = getIt<SystemVolumeService>();
      final newMuted = !_isMuted;
      await volumeService.setMuted(newMuted);
      if (mounted) {
        setState(() => _isMuted = newMuted);
      }
    } catch (e) {
      // Silently ignore
    }
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

  void _handleDismissNotification(BuildContext context) {
    context.read<QuickScanBloc>().add(const QuickScanCancelled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentPath = GoRouterState.of(context).uri.path;

    return BlocBuilder<QuickScanBloc, QuickScanState>(
      builder: (context, scanState) {
        final isScanning = scanState is QuickScanScanning;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main TopBar (drag-to-move enabled for custom title bar)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: Container(
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
                    // Left: System time + app icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimeDisplay(),
                        const SizedBox(width: AppSpacing.sm),
                        _buildAppIcon(),
                      ],
                    ),

                    // Spacer to push action buttons to the right
                    const Spacer(),

                    // Right: Action buttons + system indicators
                    Row(
                      children: [
                        // Home button (index 0)
                        FocusableButton(
                          focusNode: _buttonFocusNodes[0],
                          label: l10n?.topBarHome ?? 'Home',
                          hint: l10n?.focusHomeHint ?? 'Return to home page',
                          isActive: currentPath == '/',
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
                          isActive: currentPath.startsWith('/library'),
                          onPressed: () => _handleGameLibrary(context),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Refresh icon button
                        _buildRefreshButton(context, isScanning),
                        const SizedBox(width: AppSpacing.sm),
                        // Scan status indicator
                        _buildScanStatusIndicator(isScanning, l10n),
                        const SizedBox(width: AppSpacing.sm),
                        // Network status icons
                        _buildNetworkStatusIndicator(),
                        const SizedBox(width: AppSpacing.sm),
                        // Volume icon button
                        _buildVolumeButton(),
                      ],
                    ),
                  ],
                ),
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
    final l10n = AppLocalizations.of(context);

    return ScanNotification(
      visible: visible,
      isScanning: state is QuickScanScanning,
      newGamesCount: state is QuickScanComplete ? state.newGamesFound : null,
      gameNames: state is QuickScanComplete
          ? state.addedGames.map((g) => g.title).toList()
          : null,
      noDirectoriesConfigured:
          state is QuickScanNoNewGames ? state.noDirectoriesConfigured : false,
      errorMessage: state is QuickScanError
          ? localizeError(
              l10n,
              state.localizationKey ?? '',
              details: state.details,
            )
          : null,
      onDismiss: () => _handleDismissNotification(context),
    );
  }

  /// Builds a compact scan status indicator shown on the right side of the top bar.
  /// Only visible when a scan is in progress.
  Widget _buildScanStatusIndicator(bool isScanning, AppLocalizations? l10n) {
    if (!isScanning) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.small),
        border: Border.all(
          color: AppColors.success.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n?.topBarScanning ?? 'Scanning',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTypography.captionSize,
              fontWeight: AppTypography.regular,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the volume icon button with quick mute toggle.
  Widget _buildVolumeButton() {
    IconData iconData;
    if (_isMuted) {
      iconData = Icons.volume_off;
    } else if (_volume < 0.3) {
      iconData = Icons.volume_mute;
    } else if (_volume < 0.7) {
      iconData = Icons.volume_down;
    } else {
      iconData = Icons.volume_up;
    }

    return FocusableActionDetector(
      focusNode: _volumeFocusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          SoundService.instance.playFocusMove();
        }
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            _handleVolumeToggle();
            return null;
          },
        ),
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;

          return GestureDetector(
            onTap: _handleVolumeToggle,
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
                message: _isMuted ? 'Unmute' : 'Mute',
                child: Icon(
                  iconData,
                  color: _isMuted
                      ? AppColors.error
                      : (hasFocus
                          ? AppColors.primaryAccent
                          : AppColors.textSecondary),
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the network status indicator showing connected interfaces.
  Widget _buildNetworkStatusIndicator() {
    final connectedInterfaces = _networkInterfaces
        .where((i) => i.isConnected)
        .toList();

    if (connectedInterfaces.isEmpty) {
      return Icon(
        Icons.signal_wifi_off,
        color: AppColors.textMuted,
        size: 20,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: connectedInterfaces.map((iface) {
        final IconData iconData;
        switch (iface.type) {
          case NetworkInterfaceType.wireless:
            iconData = Icons.wifi;
          case NetworkInterfaceType.wired:
            iconData = Icons.settings_ethernet;
          case NetworkInterfaceType.loopback:
            iconData = Icons.loop;
          case NetworkInterfaceType.other:
            iconData = Icons.network_check;
        }

        return Tooltip(
          message: iface.name,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              iconData,
              color: AppColors.secondaryAccent,
              size: 18,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the app icon widget.
  ///
  /// A small, subtle icon that replaces the large centered title text.
  Widget _buildAppIcon() {
    return Icon(
      Icons.sports_esports,
      color: AppColors.textSecondary,
      size: 20,
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

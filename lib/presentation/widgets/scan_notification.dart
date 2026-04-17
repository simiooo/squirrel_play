import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';

/// A lightweight sliding notification for scan status.
///
/// Shows scan progress and results below the TopBar.
/// Auto-dismisses after 5 seconds and can be dismissed with B button.
class ScanNotification extends StatefulWidget {
  /// Whether a scan is currently in progress.
  final bool isScanning;

  /// Number of new games found (null if not applicable).
  final int? newGamesCount;

  /// List of game names to display (up to 5).
  final List<String>? gameNames;

  /// Whether no directories are configured.
  final bool noDirectoriesConfigured;

  /// Error message to display.
  final String? errorMessage;

  /// Callback when notification is dismissed.
  final VoidCallback onDismiss;

  /// Whether the notification is currently visible.
  /// Controls the slide in/out animation.
  final bool visible;

  /// Creates a scan notification.
  const ScanNotification({
    super.key,
    this.isScanning = false,
    this.newGamesCount,
    this.gameNames,
    this.noDirectoriesConfigured = false,
    this.errorMessage,
    required this.onDismiss,
    this.visible = true,
  });

  @override
  State<ScanNotification> createState() => _ScanNotificationState();
}

class _ScanNotificationState extends State<ScanNotification>
    with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  final FocusNode _focusNode = FocusNode();
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _heightFactorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimationDurations.dialogOpen,
      value: widget.visible ? 1.0 : 0.0,
    );

    final animation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimationCurves.dialogOpen,
      reverseCurve: AppAnimationCurves.dialogClose,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(animation);

    _heightFactorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(animation);

    if (widget.visible) {
      _startDismissTimer();
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant ScanNotification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      if (widget.visible) {
        _controller.duration = AppAnimationDurations.dialogOpen;
        _controller.forward();
        _focusNode.requestFocus();
        _startDismissTimer();
      } else {
        _controller.duration = AppAnimationDurations.dialogClose;
        _controller.reverse();
      }
    } else if (widget.visible &&
        (oldWidget.isScanning != widget.isScanning ||
            oldWidget.newGamesCount != widget.newGamesCount ||
            oldWidget.errorMessage != widget.errorMessage)) {
      // Restart timer when content changes while visible
      _startDismissTimer();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    // Only auto-dismiss when not scanning
    if (!widget.isScanning) {
      _dismissTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          widget.onDismiss();
        }
      });
    }
  }

  void _handleDismiss() {
    _dismissTimer?.cancel();
    widget.onDismiss();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // B button dismisses the notification
      if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
          event.logicalKey == LogicalKeyboardKey.escape) {
        _handleDismiss();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            heightFactor: _heightFactorAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: child,
            ),
          ),
        );
      },
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: AnimatedContainer(
          duration: AppAnimationDurations.dialogOpen,
          curve: AppAnimationCurves.dialogOpen,
          margin: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            boxShadow: [
              BoxShadow(
                color: AppColors.backgroundDeep.withAlpha(128),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContent(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations? l10n) {
    if (widget.isScanning) {
      return _buildScanningContent(l10n);
    }

    if (widget.errorMessage != null) {
      return _buildErrorContent(l10n, widget.errorMessage!);
    }

    if (widget.noDirectoriesConfigured) {
      return _buildNoDirectoriesContent(l10n);
    }

    if (widget.newGamesCount != null && widget.newGamesCount! > 0) {
      return _buildNewGamesContent(l10n, widget.newGamesCount!, widget.gameNames);
    }

    // No new games found
    return _buildNoNewGamesContent(l10n);
  }

  Widget _buildScanningContent(AppLocalizations? l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n?.topBarScanning ?? 'Scanning...',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppTypography.bodySize,
                fontWeight: AppTypography.regular,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const LinearProgressIndicator(
          backgroundColor: AppColors.surfaceElevated,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
        ),
      ],
    );
  }

  Widget _buildNewGamesContent(
    AppLocalizations? l10n,
    int count,
    List<String>? gameNames,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n?.topBarScanNewGames(count) ??
                    '$count new games found!',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppTypography.bodySize,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
          ],
        ),
        if (gameNames != null && gameNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ..._buildGameNamesList(gameNames),
        ],
      ],
    );
  }

  List<Widget> _buildGameNamesList(List<String> gameNames) {
    final displayNames = gameNames.take(5).toList();
    final hasMore = gameNames.length > 5;

    return [
      ...displayNames.map((name) => Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg + 4, // Indent under the icon
              top: 2,
              bottom: 2,
            ),
            child: Text(
              '• $name',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppTypography.captionSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
      if (hasMore)
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg + 4,
            top: 2,
          ),
          child: Text(
            '+${gameNames.length - 5} more',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: AppTypography.captionSize,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
    ];
  }

  Widget _buildNoNewGamesContent(AppLocalizations? l10n) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          l10n?.topBarScanNoNewGames ?? 'No new games found',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppTypography.bodySize,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDirectoriesContent(AppLocalizations? l10n) {
    return Row(
      children: [
        const Icon(
          Icons.folder_off_outlined,
          color: AppColors.warning,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            l10n?.topBarScanNoDirectories ?? 'No directories configured',
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: AppTypography.bodySize,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(AppLocalizations? l10n, String message) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            '${l10n?.topBarScanError ?? 'Scan error'}: $message',
            style: const TextStyle(
              color: AppColors.error,
              fontSize: AppTypography.bodySize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

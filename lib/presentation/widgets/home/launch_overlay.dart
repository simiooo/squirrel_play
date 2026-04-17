import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';

/// Enhanced launch overlay widget showing "Launching [Game Name]..."
///
/// Features:
/// - Brief overlay when game launch is triggered
/// - Auto-dismisses after 2 seconds
/// - Semi-transparent background with spinner
/// - Cancel button (press B to cancel)
/// - Game cover image display
/// - Fade + scale animation for appearance
class LaunchOverlay extends StatefulWidget {
  /// The name of the game being launched.
  final String gameName;

  /// Optional cover image URL to display.
  final String? coverImageUrl;

  /// Whether the overlay is visible.
  final bool isVisible;

  /// Callback when launch is cancelled.
  final VoidCallback? onCancel;

  /// Creates a LaunchOverlay widget.
  const LaunchOverlay({
    super.key,
    required this.gameName,
    this.coverImageUrl,
    this.isVisible = false,
    this.onCancel,
  });

  @override
  State<LaunchOverlay> createState() => _LaunchOverlayState();
}

class _LaunchOverlayState extends State<LaunchOverlay> {
  Timer? _launchTimer;
  bool _isCancelling = false;

  @override
  void didUpdateWidget(LaunchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible && !oldWidget.isVisible) {
      // Overlay just became visible, start the 2-second timer
      _startLaunchTimer();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      // Overlay was hidden, cancel timer
      _cancelLaunchTimer();
    }
  }

  @override
  void dispose() {
    _cancelLaunchTimer();
    super.dispose();
  }

  void _startLaunchTimer() {
    _cancelLaunchTimer();
    _isCancelling = false;

    // Auto-dismiss after 2 seconds
    _launchTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isCancelling) {
        // Timer completed, launch proceeds
        debugPrint('[LaunchOverlay] Launch timer completed');
      }
    });
  }

  void _cancelLaunchTimer() {
    _launchTimer?.cancel();
    _launchTimer = null;
  }

  void _handleCancel() {
    if (_isCancelling) return;

    _isCancelling = true;
    _cancelLaunchTimer();

    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final message = l10n?.launchingGame(widget.gameName) ??
        'Launching ${widget.gameName}...';
    final cancelHint = l10n?.launchCancelHint ?? 'Press B to cancel';

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
              event.logicalKey == LogicalKeyboardKey.escape) {
            _handleCancel();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedOpacity(
        opacity: widget.isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          color: AppColors.overlay,
          child: Center(
            child: AnimatedScale(
              scale: widget.isVisible ? 1.0 : 0.95,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                margin: const EdgeInsets.all(AppSpacing.xl),
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.large),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(128),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Game cover image (if available)
                    if (widget.coverImageUrl != null)
                      Container(
                        width: 120,
                        height: 180,
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.medium),
                          image: DecorationImage(
                            image: NetworkImage(widget.coverImageUrl!),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                    // Loading spinner
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryAccent,
                        ),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Launch message
                    Text(
                      message,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Cancel hint
                    Text(
                      cancelHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

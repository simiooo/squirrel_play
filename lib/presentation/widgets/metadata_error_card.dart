import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/data/services/sound_service.dart';

/// Error card with retry button for failed metadata fetches.
///
/// Shows an error message and provides a retry action.
class MetadataErrorCard extends StatefulWidget {
  /// The error message to display.
  final String errorMessage;

  /// Callback when retry is pressed.
  final VoidCallback onRetry;

  /// Whether this card is currently focused.
  final FocusNode focusNode;

  const MetadataErrorCard({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.focusNode,
  });

  @override
  State<MetadataErrorCard> createState() => _MetadataErrorCardState();
}

class _MetadataErrorCardState extends State<MetadataErrorCard> {
  bool _wasFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(MetadataErrorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    final isFocused = widget.focusNode.hasFocus;

    if (isFocused && !_wasFocused) {
      SoundService.instance.playFocusMove();
    }

    setState(() {
      _wasFocused = isFocused;
    });
  }

  void _handleRetry() {
    SoundService.instance.playFocusSelect();
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final cardSize = CardDimensions.getSize(breakpoint);

    return Semantics(
      button: true,
      label: 'Error loading game metadata. Press to retry.',
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleRetry();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: widget.focusNode,
          child: AnimatedScale(
            scale: isFocused ? 1.08 : 1.0,
            duration: isFocused
                ? const Duration(milliseconds: 200)
                : const Duration(milliseconds: 150),
            curve: isFocused
                ? AppAnimationCurves.pageEnter
                : AppAnimationCurves.pageExit,
            child: GestureDetector(
              onTap: _handleRetry,
              child: Container(
                width: cardSize.width,
                height: cardSize.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  color: AppColors.surface,
                  border: isFocused
                      ? Border.all(
                          color: AppColors.error,
                          width: 2,
                        )
                      : null,
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.error.withAlpha(128),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(64),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'Failed to load',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Retry',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

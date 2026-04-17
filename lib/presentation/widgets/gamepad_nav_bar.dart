import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/presentation/models/gamepad_action_hint.dart';
import 'package:squirrel_play/presentation/navigation/gamepad_hint_provider.dart';
import 'package:squirrel_play/presentation/widgets/gamepad_button_icon.dart';

/// A persistent bottom navigation bar displaying contextual gamepad button hints.
///
/// Shows which gamepad buttons perform which actions in the current context,
/// updating dynamically based on the current route and dialog state.
///
/// The bar is not focusable and is excluded from focus traversal.
class GamepadNavBar extends StatelessWidget {
  /// Creates a gamepad navigation bar.
  const GamepadNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final hints = GamepadHintProvider.of(context);
    final width = MediaQuery.sizeOf(context).width;

    // Responsive breakpoints
    final isCompact = width < 640;
    final isExpanded = width >= 1024;
    // Medium (640-1024) uses the same labels but may truncate via layout

    return ExcludeFocus(
      child: SizedBox(
        height: AppSpacing.xxxl,
        child: Container(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.xl,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(
              (AppColors.surfaceOpacity * 255).round(),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.backgroundDeep.withAlpha(128),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _buildContent(context, hints, isCompact, isExpanded),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<GamepadActionHint> hints,
    bool isCompact,
    bool isExpanded,
  ) {
    if (hints.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <Widget>[];

    for (var i = 0; i < hints.length; i++) {
      final hint = hints[i];

      items.add(
        _HintItem(
          hint: hint,
          isCompact: isCompact,
          isExpanded: isExpanded,
        ),
      );

      if (i < hints.length - 1) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '·',
              style: TextStyle(
                color: AppColors.textMuted.withAlpha(128),
                fontSize: 12,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: items,
    );
  }
}

class _HintItem extends StatelessWidget {
  const _HintItem({
    required this.hint,
    required this.isCompact,
    required this.isExpanded,
  });

  final GamepadActionHint hint;
  final bool isCompact;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = hint.buttonLabel;
    final actionLabel = hint.actionLabel;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GamepadButtonIcon(label: buttonLabel),
        if (!isCompact) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            actionLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

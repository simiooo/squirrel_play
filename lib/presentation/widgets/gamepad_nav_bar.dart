import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/models/gamepad_action_hint.dart';
import 'package:squirrel_play/presentation/navigation/gamepad_hint_provider.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
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

    return SizedBox(
      height: AppSpacing.xxxl,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
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
        child: _buildContent(context, hints, isCompact, isExpanded),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<GamepadActionHint> hints,
    bool isCompact,
    bool isExpanded,
  ) {
    return Row(
      children: [
        // Left: Settings button (outside ExcludeFocus so it can receive focus)
        _SettingsNavButton(),
        const Spacer(),
        // Right: Gamepad hints (excluded from focus traversal)
        ExcludeFocus(
          child: _buildHints(context, hints, isCompact, isExpanded),
        ),
      ],
    );
  }

  Widget _buildHints(
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
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }
}

class _SettingsNavButton extends StatefulWidget {
  @override
  State<_SettingsNavButton> createState() => _SettingsNavButtonState();
}

class _SettingsNavButtonState extends State<_SettingsNavButton> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'SettingsNavButton');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePress() {
    SoundService.instance.playPageTransition();
    context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FocusableButton(
      focusNode: _focusNode,
      label: l10n?.topBarSettings ?? 'Settings',
      hint: l10n?.focusSettingsHint ?? 'Open application settings',
      onPressed: _handlePress,
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

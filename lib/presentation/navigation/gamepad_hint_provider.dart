import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/models/gamepad_action_hint.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';

/// Provides contextual gamepad action hints to descendant widgets.
///
/// Listens to GoRouter route changes and FocusTraversalService dialog
/// detection via `isDialogOpen` to dynamically update the displayed hints.
class GamepadHintProvider extends InheritedWidget {
  /// Creates a gamepad hint provider.
  const GamepadHintProvider({
    required this.hints,
    required super.child,
    super.key,
  });

  /// The current list of gamepad action hints.
  final List<GamepadActionHint> hints;

  /// Retrieves the current hints from the nearest ancestor provider.
  static List<GamepadActionHint> of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<GamepadHintProvider>()
            ?.hints ??
        [];
  }

  @override
  bool updateShouldNotify(covariant GamepadHintProvider oldWidget) {
    return !listEquals(hints, oldWidget.hints);
  }
}

/// Stateful wrapper that listens to route and focus changes and rebuilds
/// the [GamepadHintProvider] with updated hints.
class GamepadHintProviderWrapper extends StatefulWidget {
  /// Creates a wrapper that provides dynamic gamepad hints.
  const GamepadHintProviderWrapper({
    required this.child,
    super.key,
  });

  /// The child widget to wrap.
  final Widget child;

  @override
  State<GamepadHintProviderWrapper> createState() =>
      _GamepadHintProviderWrapperState();
}

class _GamepadHintProviderWrapperState
    extends State<GamepadHintProviderWrapper> {
  StreamSubscription<FocusNode?>? _focusSubscription;

  @override
  void initState() {
    super.initState();
    _focusSubscription =
        FocusTraversalService.instance.currentFocusStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _focusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hints = _resolveHints(context);
    return GamepadHintProvider(
      hints: hints,
      child: widget.child,
    );
  }

  List<GamepadActionHint> _resolveHints(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return [];

    final isDialog = FocusTraversalService.instance.isDialogOpen;

    if (isDialog) {
      return [
        GamepadActionHint(
          buttonLabel: 'A',
          actionLabel: l10n.gamepadNavConfirm,
        ),
        GamepadActionHint(
          buttonLabel: 'B',
          actionLabel: l10n.gamepadNavCancel,
        ),
      ];
    }

    final location = GoRouterState.of(context).uri.path;

    switch (location) {
      case '/':
      case '/library':
        // Only show A (Select) and B (Back) hints - minimal, clean UI
        return [
          GamepadActionHint(
            buttonLabel: 'A',
            actionLabel: l10n.gamepadNavSelect,
          ),
          GamepadActionHint(
            buttonLabel: 'B',
            actionLabel: l10n.gamepadNavBack,
          ),
        ];
      case '/settings':
      case '/settings/gamepad-test':
        // Only show A (Toggle) and B (Back) hints
        return [
          GamepadActionHint(
            buttonLabel: 'A',
            actionLabel: l10n.gamepadNavToggle,
          ),
          GamepadActionHint(
            buttonLabel: 'B',
            actionLabel: l10n.gamepadNavBack,
          ),
        ];
      default:
        // Game detail page fallback - minimal hints only
        if (location.startsWith('/game/')) {
          return [
            GamepadActionHint(
              buttonLabel: 'A',
              actionLabel: l10n.gamepadNavPlay,
            ),
            GamepadActionHint(
              buttonLabel: 'B',
              actionLabel: l10n.gamepadNavBack,
            ),
          ];
        }
        // Generic fallback - minimal hints only
        return [
          GamepadActionHint(
            buttonLabel: 'A',
            actionLabel: l10n.gamepadNavConfirm,
          ),
          GamepadActionHint(
            buttonLabel: 'B',
            actionLabel: l10n.gamepadNavBack,
          ),
        ];
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gamepads/gamepads.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/gamepad/gamepad_test_bloc.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// The gamepad test page.
///
/// Displays real-time gamepad input states including:
/// - Connection status with gamepad name
/// - Visual gamepad diagram with button states
/// - Analog stick position visualization
/// - Input event log
class GamepadTestPage extends StatelessWidget {
  /// Creates the gamepad test page.
  const GamepadTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GamepadTestBloc>(),
      child: const _GamepadTestPageContent(),
    );
  }
}

class _GamepadTestPageContent extends StatefulWidget {
  const _GamepadTestPageContent();

  @override
  State<_GamepadTestPageContent> createState() => _GamepadTestPageContentState();
}

class _GamepadTestPageContentState extends State<_GamepadTestPageContent> {
  late final FocusNode _backButtonFocusNode;

  @override
  void initState() {
    super.initState();
    _backButtonFocusNode = FocusNode(debugLabel: 'GamepadTestBackButton');
    // Suppress gamepad navigation actions while on the test page
    FocusTraversalService.suppressActions = true;
    debugPrint('[GamepadTestPage] Suppressed focus traversal actions');
  }

  @override
  void dispose() {
    // Re-enable gamepad navigation actions when leaving the test page
    FocusTraversalService.suppressActions = false;
    debugPrint('[GamepadTestPage] Restored focus traversal actions');
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    SoundService.instance.playFocusBack();
    context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Only B/Back button triggers navigation
            if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              _handleBack();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  FocusableButton(
                    focusNode: _backButtonFocusNode,
                    label: l10n?.buttonBack ?? 'Back',
                    icon: Icons.arrow_back,
                    onPressed: _handleBack,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    l10n?.gamepadTestTitle ?? 'Gamepad Test',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: BlocBuilder<GamepadTestBloc, GamepadTestState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Connection status card
                        _buildConnectionStatus(context, state, l10n),
                        const SizedBox(height: AppSpacing.xxl),

                        // Visual gamepad diagram
                        if (state.isConnected) ...[
                          _buildGamepadDiagram(context, state),
                          const SizedBox(height: AppSpacing.xxl),

                          // Stick values display
                          _buildStickValues(context, state),
                          const SizedBox(height: AppSpacing.xxl),

                          // Input log
                          _buildInputLog(context, state, l10n),
                        ] else ...[
                          // Empty state
                          _buildEmptyState(context, l10n),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(
    BuildContext context,
    GamepadTestState state,
    AppLocalizations? l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(
          color: state.isConnected ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Connection indicator dot
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isConnected ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isConnected
                      ? (l10n?.gamepadTestConnected ?? 'Connected')
                      : (l10n?.gamepadTestDisconnected ?? 'No gamepad detected'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: state.isConnected
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.isConnected && state.gamepadName != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.gamepadName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (!state.isConnected) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n?.gamepadTestConnectHelp ??
                        'Connect a gamepad and press any button',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamepadDiagram(BuildContext context, GamepadTestState state) {
    return Center(
      child: Container(
        width: 600,
        height: 350,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(77),
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
        child: Stack(
          children: [
            // Left stick (positioned bottom-left)
            Positioned(
              left: 60,
              bottom: 40,
              child: _buildStickVisualization(
                context,
                'L',
                state.leftStickPosition,
                state.buttonStates[GamepadButton.leftStick] ?? false,
              ),
            ),

            // Right stick (positioned bottom-right)
            Positioned(
              right: 60,
              bottom: 40,
              child: _buildStickVisualization(
                context,
                'R',
                state.rightStickPosition,
                state.buttonStates[GamepadButton.rightStick] ?? false,
              ),
            ),

            // D-pad (positioned left-center)
            Positioned(
              left: 60,
              top: 80,
              child: _buildDpad(
                context,
                state.buttonStates,
              ),
            ),

            // Face buttons (positioned right-center) - Xbox layout
            // A=bottom (green), B=right (red), X=left (blue), Y=top (yellow)
            Positioned(
              right: 60,
              top: 80,
              child: _buildFaceButtons(
                context,
                state.buttonStates,
              ),
            ),

            // Shoulder buttons (positioned at top)
            Positioned(
              left: 60,
              top: 20,
              child: _buildShoulderButtons(
                context,
                state.buttonStates,
              ),
            ),

            // Center buttons (Start, Back, Guide)
            Positioned(
              left: 250,
              top: 60,
              child: _buildCenterButtons(
                context,
                state.buttonStates,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickVisualization(
    BuildContext context,
    String label,
    Offset position,
    bool isPressed,
  ) {
    const size = 80.0;
    const deadzone = 0.1;

    // Clamp position to -1..1 range
    final clampedX = position.dx.clamp(-1.0, 1.0);
    final clampedY = position.dy.clamp(-1.0, 1.0);

    // Calculate dot position (centered, with 30px max offset)
    final dotX = (size / 2) + (clampedX * 30);
    final dotY = (size / 2) + (clampedY * 30);

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: isPressed ? AppColors.primaryAccent : AppColors.textMuted,
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Crosshair lines
              Center(
                child: Container(
                  width: size - 20,
                  height: 1,
                  color: AppColors.textMuted.withAlpha(77),
                ),
              ),
              Center(
                child: Container(
                  width: 1,
                  height: size - 20,
                  color: AppColors.textMuted.withAlpha(77),
                ),
              ),

              // Stick position dot (only show if outside deadzone)
              if (position.distance > deadzone)
                Positioned(
                  left: dotX - 6,
                  top: dotY - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryAccent,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withAlpha(128),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDpad(BuildContext context, Map<GamepadButton, bool> buttonStates) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          // Up
          Positioned(
            top: 0,
            left: 35,
            child: _buildDpadButton(
              context,
              Icons.arrow_drop_up,
              buttonStates[GamepadButton.dpadUp] ?? false,
            ),
          ),

          // Down
          Positioned(
            bottom: 0,
            left: 35,
            child: _buildDpadButton(
              context,
              Icons.arrow_drop_down,
              buttonStates[GamepadButton.dpadDown] ?? false,
            ),
          ),

          // Left
          Positioned(
            left: 0,
            top: 35,
            child: _buildDpadButton(
              context,
              Icons.arrow_left,
              buttonStates[GamepadButton.dpadLeft] ?? false,
            ),
          ),

          // Right
          Positioned(
            right: 0,
            top: 35,
            child: _buildDpadButton(
              context,
              Icons.arrow_right,
              buttonStates[GamepadButton.dpadRight] ?? false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadButton(BuildContext context, IconData icon, bool isPressed) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isPressed ? AppColors.primaryAccent : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPressed ? AppColors.primaryAccent : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: isPressed ? Colors.white : AppColors.textMuted,
      ),
    );
  }

  Widget _buildFaceButtons(BuildContext context, Map<GamepadButton, bool> buttonStates) {
    // Xbox layout: A=bottom (green), B=right (red), X=left (blue), Y=top (yellow)
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          // A button (bottom, green)
          Positioned(
            bottom: 0,
            left: 35,
            child: _buildFaceButton(
              context,
              'A',
              const Color(0xFF00C851), // Green
              buttonStates[GamepadButton.a] ?? false,
            ),
          ),

          // B button (right, red)
          Positioned(
            right: 0,
            top: 35,
            child: _buildFaceButton(
              context,
              'B',
              const Color(0xFFFF4757), // Red
              buttonStates[GamepadButton.b] ?? false,
            ),
          ),

          // X button (left, blue)
          Positioned(
            left: 0,
            top: 35,
            child: _buildFaceButton(
              context,
              'X',
              const Color(0xFF33B5E5), // Blue
              buttonStates[GamepadButton.x] ?? false,
            ),
          ),

          // Y button (top, yellow)
          Positioned(
            top: 0,
            left: 35,
            child: _buildFaceButton(
              context,
              'Y',
              const Color(0xFFFFBB33), // Yellow
              buttonStates[GamepadButton.y] ?? false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceButton(
    BuildContext context,
    String label,
    Color color,
    bool isPressed,
  ) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPressed ? color : AppColors.surface,
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: color.withAlpha(179),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isPressed ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildShoulderButtons(BuildContext context, Map<GamepadButton, bool> buttonStates) {
    return SizedBox(
      width: 480,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LB
          _buildShoulderButton(
            context,
            'LB',
            buttonStates[GamepadButton.leftBumper] ?? false,
          ),

          // RB
          _buildShoulderButton(
            context,
            'RB',
            buttonStates[GamepadButton.rightBumper] ?? false,
          ),
        ],
      ),
    );
  }

  Widget _buildShoulderButton(BuildContext context, String label, bool isPressed) {
    return Container(
      width: 60,
      height: 30,
      decoration: BoxDecoration(
        color: isPressed ? AppColors.primaryAccent : AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPressed ? AppColors.primaryAccent : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isPressed ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButtons(BuildContext context, Map<GamepadButton, bool> buttonStates) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back button
        _buildCenterButton(
          context,
          'BACK',
          buttonStates[GamepadButton.back] ?? false,
        ),
        const SizedBox(width: AppSpacing.md),

        // Guide/Home button (Xbox logo)
        _buildCenterButton(
          context,
          'GUIDE',
          buttonStates[GamepadButton.home] ?? false,
          isGuide: true,
        ),
        const SizedBox(width: AppSpacing.md),

        // Start button
        _buildCenterButton(
          context,
          'START',
          buttonStates[GamepadButton.start] ?? false,
        ),
      ],
    );
  }

  Widget _buildCenterButton(
    BuildContext context,
    String label,
    bool isPressed, {
    bool isGuide = false,
  }) {
    return Container(
      width: isGuide ? 50 : 45,
      height: 25,
      decoration: BoxDecoration(
        color: isPressed ? AppColors.primaryAccent : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPressed ? AppColors.primaryAccent : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isPressed ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  Widget _buildStickValues(BuildContext context, GamepadTestState state) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(77),
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left stick values
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Left Stick',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'X: ${state.leftStickPosition.dx.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Y: ${state.leftStickPosition.dy.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xxl),

            // Right stick values
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Right Stick',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'X: ${state.rightStickPosition.dx.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Y: ${state.rightStickPosition.dy.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedLogType(AppLocalizations? l10n, String type) {
    switch (type) {
      case 'BUTTON':
        return l10n?.gamepadTestButton ?? 'BUTTON';
      case 'AXIS':
        return l10n?.gamepadTestAxis ?? 'AXIS';
      case 'CONNECT':
        return l10n?.gamepadTestConnect ?? 'CONNECT';
      case 'DISCONNECT':
        return l10n?.gamepadTestDisconnect ?? 'DISCONNECT';
      default:
        return type;
    }
  }

  String _getLocalizedLogDescription(
    AppLocalizations? l10n,
    InputLogEntry entry,
  ) {
    final params = entry.params;
    switch (entry.type) {
      case 'BUTTON':
        final buttonName = params?['buttonName'] as String? ?? '';
        final pressed = params?['pressed'] as bool? ?? false;
        final action = pressed
            ? (l10n?.gamepadTestPressed ?? 'pressed')
            : (l10n?.gamepadTestReleased ?? 'released');
        return '$buttonName $action';
      case 'AXIS':
        final axisName = params?['axisName'] as String? ?? '';
        final axisValue = (params?['axisValue'] as double?)?.toStringAsFixed(2) ?? '0.00';
        return '$axisName: $axisValue';
      case 'CONNECT':
        final name = params?['gamepadName'] as String? ??
            (l10n?.gamepadTestUnknown ?? 'Unknown');
        return l10n?.gamepadTestGamepadConnected(name) ??
            'Gamepad connected: $name';
      case 'DISCONNECT':
        return l10n?.gamepadTestGamepadDisconnected ?? 'Gamepad disconnected';
      default:
        return entry.description ?? '';
    }
  }

  Widget _buildInputLog(
    BuildContext context,
    GamepadTestState state,
    AppLocalizations? l10n,
  ) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(77),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.gamepadTestInputLog ?? 'Input Log',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: state.inputLog.length,
              itemBuilder: (context, index) {
                final entry = state.inputLog[state.inputLog.length - 1 - index];
                final timeStr =
                    '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';

                final localizedType = _getLocalizedLogType(l10n, entry.type);
                final localizedDesc = _getLocalizedLogDescription(l10n, entry);

                Color typeColor;
                switch (entry.type) {
                  case 'BUTTON':
                    typeColor = AppColors.primaryAccent;
                    break;
                  case 'AXIS':
                    typeColor = AppColors.secondaryAccent;
                    break;
                  case 'CONNECT':
                    typeColor = AppColors.success;
                    break;
                  case 'DISCONNECT':
                    typeColor = AppColors.error;
                    break;
                  default:
                    typeColor = AppColors.textMuted;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '[$timeStr]',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          localizedType,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          localizedDesc,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videogame_asset_off,
            size: 64,
            color: AppColors.textMuted.withAlpha(128),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n?.gamepadTestNoGamepad ?? 'No gamepad detected',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n?.gamepadTestConnectInstructions ??
                'Connect a gamepad and press any button to start testing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

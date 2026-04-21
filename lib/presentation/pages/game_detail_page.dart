import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/game_detail/game_detail_bloc.dart';
import 'package:squirrel_play/presentation/widgets/delete_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/edit_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';
import 'package:squirrel_play/presentation/widgets/home/dynamic_background.dart';

/// The game detail page showing rich game information and action buttons.
///
/// Features:
/// - Full-width hero image background (top 60%)
/// - Left-aligned game info overlay with title, description, stats
/// - Horizontal row of focusable action buttons (bottom 40%)
/// - FocusScope for action button containment
/// - Automatic focus to first action button on page load
/// - Mutual exclusion: Launch/Delete hidden when game is running
class GameDetailPage extends StatefulWidget {
  /// Creates the game detail page.
  const GameDetailPage({super.key});

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  late final FocusNode _backButtonFocusNode;
  late final FocusNode _launchStopFocusNode;
  late final FocusNode _settingsFocusNode;
  late final FocusNode _deleteFocusNode;
  late final FocusNode _refreshMetadataFocusNode;
  late final FocusScopeNode _actionScopeNode;
  bool _wasRunning = false;
  bool _apiErrorDialogShown = false;
  bool _launchErrorDialogShown = false;

  @override
  void initState() {
    super.initState();
    _backButtonFocusNode = FocusNode(debugLabel: 'DetailBackButton');
    _launchStopFocusNode = FocusNode(debugLabel: 'LaunchStopButton');
    _settingsFocusNode = FocusNode(debugLabel: 'SettingsButton');
    _deleteFocusNode = FocusNode(debugLabel: 'DeleteButton');
    _refreshMetadataFocusNode = FocusNode(debugLabel: 'RefreshMetadataButton');
    _actionScopeNode = FocusScopeNode(debugLabel: 'DetailActionScope');

    // Request focus on first action button after frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _launchStopFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _backButtonFocusNode.dispose();
    _launchStopFocusNode.dispose();
    _settingsFocusNode.dispose();
    _deleteFocusNode.dispose();
    _refreshMetadataFocusNode.dispose();
    _actionScopeNode.dispose();
    super.dispose();
  }

  void _handleBack() {
    SoundService.instance.playFocusBack();
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _handleDeleted() {
    if (mounted) {
      context.go('/');
    }
  }

  void _handleLaunchGame() {
    context.read<GameDetailBloc>().add(const GameDetailLaunchRequested());
  }

  void _handleStopGame() {
    context.read<GameDetailBloc>().add(const GameDetailStopRequested());
  }

  void _handleSettings() async {
    final bloc = context.read<GameDetailBloc>();
    final state = bloc.state;
    if (state is! GameDetailLoaded) return;

    final game = state.game;
    await EditGameDialog.show(
      context,
      game,
      (updatedGame) {
        bloc.add(GameDetailEditSaved(updatedGame));
      },
    );
  }

  void _handleDelete() async {
    final bloc = context.read<GameDetailBloc>();
    final state = bloc.state;
    if (state is! GameDetailLoaded) return;

    final confirmed = await DeleteGameDialog.show(context, state.game);

    if (confirmed == true && mounted) {
      bloc.add(const GameDetailDeleteRequested());
    }
  }

  void _handleRefetchMetadata() {
    final bloc = context.read<GameDetailBloc>();
    bloc.add(const GameDetailRefetchMetadataRequested());
  }

  void _showApiConfigDialog(String message) {
    if (!mounted || _apiErrorDialogShown) return;
    _apiErrorDialogShown = true;

    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n?.settingsApiKey ?? 'API Key Required',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n?.errorApiNotConfigured ??
              'RAWG API key is not configured. Please go to Settings to add your API key.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          FocusableButton(
            focusNode: FocusNode(debugLabel: 'ApiConfigDialogCancel'),
            label: l10n?.buttonCancel ?? 'Cancel',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FocusableButton(
            focusNode: FocusNode(debugLabel: 'ApiConfigDialogSettings'),
            label: l10n?.pageSettings ?? 'Settings',
            isPrimary: true,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/settings');
            },
          ),
        ],
      ),
    ).then((_) {
      _apiErrorDialogShown = false;
    });
  }

  void _showLaunchErrorDialog(String message) {
    if (!mounted || _launchErrorDialogShown) return;
    _launchErrorDialogShown = true;

    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l10n?.errorLaunchFailed ?? 'Launch Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          FocusableButton(
            focusNode: FocusNode(debugLabel: 'LaunchErrorDialogOk'),
            label: l10n?.buttonConfirm ?? 'OK',
            isPrimary: true,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    ).then((_) {
      _launchErrorDialogShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameDetailBloc, GameDetailState>(
      listener: (context, state) {
        if (state is GameDetailDeleted) {
          _handleDeleted();
        }
      },
      child: BlocBuilder<GameDetailBloc, GameDetailState>(
        builder: (context, state) {
          return Focus(
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.gameButtonB ||
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _handleBack();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: _buildContent(context, state),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, GameDetailState state) {
    if (state is GameDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is GameDetailError) {
      final l10n = AppLocalizations.of(context)!;
      final String message;
      switch (state.type) {
        case GameDetailErrorType.gameNotFound:
          message = l10n.errorGameNotFound;
        case GameDetailErrorType.loadFailed:
          message = l10n.errorLoadFailed;
        case GameDetailErrorType.launchFailed:
          message = l10n.errorLaunchFailed;
        case GameDetailErrorType.stopFailed:
          message = l10n.errorStopFailed;
        case GameDetailErrorType.deleteFailed:
          message = l10n.errorDeleteFailed;
        case GameDetailErrorType.updateFailed:
          message = l10n.errorUpdateFailed;
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (state is GameDetailLoaded) {
      // Show launch error dialog if needed
      if (state.launchError != null && !_launchErrorDialogShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLaunchErrorDialog(state.launchError!);
        });
      }
      return _buildLoadedContent(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadedContent(BuildContext context, GameDetailLoaded state) {
    final game = state.game;
    final metadata = state.metadata;

    // Show API configuration dialog if needed
    if (state.apiConfigError != null && !_apiErrorDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showApiConfigDialog(state.apiConfigError!);
      });
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: Full-screen dynamic background
        Positioned.fill(
          child: DynamicBackground(
            game: game,
            metadata: metadata,
            crossfadeDuration: const Duration(milliseconds: 500),
            crossfadeCurve: Curves.easeInOut,
          ),
        ),

        // Layer 1: Left-to-right gradient for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background.withAlpha(242),
                  AppColors.background.withAlpha(180),
                  AppColors.background.withAlpha(80),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Layer 2: Bottom-to-top gradient for bottom area readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.background,
                  AppColors.background.withAlpha(230),
                  AppColors.background.withAlpha(120),
                  Colors.transparent,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
              ),
            ),
          ),
        ),

        // Layer 3: Back button (top-left, above everything)
        Positioned(
          top: AppSpacing.xl,
          left: AppSpacing.xl,
          child: FocusableButton(
            focusNode: _backButtonFocusNode,
            label: AppLocalizations.of(context)?.buttonBack ?? 'Back',
            icon: Icons.arrow_back,
            onPressed: _handleBack,
          ),
        ),

        // Layer 4: Content layout
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top 60%: Game info section
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildGameInfo(context, game, metadata),
                  ),
                ),
              ),
            ),

            // Bottom 40%: Action buttons
            Expanded(
              flex: 4,
              child: Container(
                color: AppColors.background.withAlpha(204),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FocusScope(
                    node: _actionScopeNode,
                    child: _buildActionButtons(context, state),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGameInfo(
    BuildContext context,
    Game game,
    GameMetadata? metadata,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Game title
        Text(
          game.title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 48,
            height: 1.05,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Developer info
        if (metadata?.developer != null)
          Text(
            metadata!.developer!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary.withAlpha(204),
              fontSize: 15,
            ),
          ),

        if (metadata?.developer != null)
          const SizedBox(height: AppSpacing.sm),

        // Description
        _buildDescription(context, metadata),

        const SizedBox(height: AppSpacing.md),

        // Stats row: play count, last played, favorite
        _buildStatsRow(context, game),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, GameMetadata? metadata) {
    final l10n = AppLocalizations.of(context);
    final description = metadata?.description ?? '';

    final text = description.isNotEmpty
        ? _stripHtml(description)
        : l10n!.noDescriptionAvailable;

    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondary.withAlpha(220),
        fontSize: 18,
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _stripHtml(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  Widget _buildStatsRow(BuildContext context, Game game) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.sm,
      children: [
        // Play count
        _buildStatItem(
          context,
          icon: Icons.play_circle_outline,
          label: game.playCount == 0
              ? l10n!.gameInfoPlayCountNever
              : l10n!.gameInfoPlayCount(game.playCount),
        ),

        // Last played
        if (game.lastPlayedDate != null)
          _buildStatItem(
            context,
            icon: Icons.access_time,
            label: l10n.gameInfoLastPlayed(
              _formatDate(context, game.lastPlayedDate!),
            ),
          ),

        // Favorite status
        if (game.isFavorite)
          _buildStatItem(
            context,
            icon: Icons.favorite,
            label: l10n.gameInfoFavoriteButton,
            iconColor: AppColors.primaryAccent,
          ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor ?? AppColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  Widget _buildActionButtons(BuildContext context, GameDetailLoaded state) {
    final l10n = AppLocalizations.of(context);
    final isRunning = state.isRunning;
    final wasRunning = _wasRunning;
    _wasRunning = isRunning;

    // Manage focus when buttons appear/disappear
    // If the game is running, Launch and Delete buttons are hidden
    // If the previously focused button is removed, move focus to first available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // When transitioning from not-running to running, move focus to the
      // first visible button (LaunchStopButton becomes the Stop button).
      // This handles the case where DeleteButton had focus and was removed.
      if (isRunning && !wasRunning) {
        _launchStopFocusNode.requestFocus();
      }
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Launch / Stop button (mutually exclusive)
          FocusableButton(
            focusNode: _launchStopFocusNode,
            label: isRunning
                ? l10n!.gameInfoStopButton
                : l10n!.gameInfoLaunchButton,
            icon: isRunning ? Icons.stop : Icons.play_arrow,
            isPrimary: true,
            onPressed: isRunning ? _handleStopGame : _handleLaunchGame,
          ),
          const SizedBox(width: AppSpacing.md),

          // Settings button (always visible)
          FocusableButton(
            focusNode: _settingsFocusNode,
            label: l10n.gameInfoSettingsButton,
            icon: Icons.settings,
            onPressed: _handleSettings,
          ),

          // Refresh metadata button
          const SizedBox(width: AppSpacing.md),
          FocusableButton(
            focusNode: _refreshMetadataFocusNode,
            label: l10n.gameInfoRefreshMetadataButton,
            icon: Icons.refresh,
            onPressed: _handleRefetchMetadata,
          ),

          // Delete button (hidden when running)
          if (!isRunning) ...[
            const SizedBox(width: AppSpacing.md),
            FocusableButton(
              focusNode: _deleteFocusNode,
              label: l10n.gameInfoDeleteButton,
              icon: Icons.delete_outline,
              onPressed: _handleDelete,
            ),
          ],
        ],
      ),
    );
  }
}

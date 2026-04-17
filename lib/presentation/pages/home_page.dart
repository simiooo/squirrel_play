import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/presentation/blocs/home/home_bloc.dart';
import 'package:squirrel_play/presentation/widgets/add_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/home/dynamic_background.dart';
import 'package:squirrel_play/presentation/widgets/home/empty_home_state.dart';
import 'package:squirrel_play/presentation/widgets/home/error_home_state.dart';
import 'package:squirrel_play/presentation/widgets/home/game_card_row.dart';
import 'package:squirrel_play/presentation/widgets/home/game_info_overlay.dart';
import 'package:squirrel_play/presentation/widgets/home/launch_overlay.dart';
import 'package:squirrel_play/presentation/widgets/home/loading_home_state.dart';

/// The home page of the application.
///
/// Features a Netflix-style layout with:
/// - Full-viewport dynamic background
/// - Game info overlay showing focused game details
/// - Horizontal scrolling card rows
/// - Gamepad navigation support
/// - Sound effects on focus/selection
class HomePage extends StatefulWidget {
  /// Creates the home page.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
  }

  void _handleAddGame() {
    SoundService.instance.playFocusSelect();
    showDialog(
      context: context,
      builder: (context) => const AddGameDialog(),
    );
  }

  void _handleScanDirectory() {
    SoundService.instance.playFocusSelect();
    // Open Add Game dialog on Scan Directory tab
    showDialog(
      context: context,
      builder: (context) => const AddGameDialog(initialTab: 1),
    );
  }

  void _handleNavigateToLibrary() {
    SoundService.instance.playPageTransition();
    context.go('/library');
  }

  void _handleGameLaunched(Game game) {
    _homeBloc.add(HomeGameLaunched(game: game));
  }

  void _handleRetry() {
    _homeBloc.add(const HomeRetryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      bloc: _homeBloc,
      builder: (context, state) {
        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    // Handle different states
    if (state is HomeInitial) {
      return const LoadingHomeState();
    }

    if (state is HomeLoading) {
      return const LoadingHomeState();
    }

    if (state is HomeEmpty) {
      return EmptyHomeState(
        onAddGame: _handleAddGame,
        onScanDirectory: _handleScanDirectory,
        hasScanDirectories: state.hasScanDirectories,
      );
    }

    if (state is HomeError) {
      return ErrorHomeState(
        message: state.message,
        onRetry: _handleRetry,
      );
    }

    if (state is HomeLoaded) {
      return _buildLoadedContent(context, state);
    }

    // Fallback
    return const LoadingHomeState();
  }

  Widget _buildLoadedContent(BuildContext context, HomeLoaded state) {
    final focusedGame = state.focusedGame;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: Dynamic background (fills entire screen)
        Positioned.fill(
          child: DynamicBackground(
            game: focusedGame,
            crossfadeDuration: const Duration(milliseconds: 500),
            crossfadeCurve: Curves.easeInOut,
          ),
        ),

        // Layer 1: Gradient overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withAlpha(77),
                  Colors.transparent,
                  AppColors.background.withAlpha(204),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
        ),

        // Layer 2: Game info overlay (positioned at bottom-left)
        Positioned(
          left: 0,
          right: 0,
          bottom: 320, // Space for card rows
          child: GameInfoOverlay(
            game: focusedGame,
            metadata: state.focusedGameMetadata,
            isVisible: focusedGame != null,
          ),
        ),

        // Layer 3: Horizontal card rows
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 320,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.background,
                  AppColors.background.withAlpha(230),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
            child: _buildCardRows(state),
          ),
        ),

        // Layer 4: Launch overlay (when launching)
        LaunchOverlay(
          gameName: focusedGame?.title ?? 'Game',
          isVisible: state.isLaunching,
        ),
      ],
    );
  }

  Widget _buildCardRows(HomeLoaded state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Card rows (show all non-empty rows)
        for (int i = 0; i < state.rows.length; i++) ...[
          GameCardRow(
            row: state.rows[i],
            rowIndex: i,
            focusedCardIndex: state.focusedRowIndex == i ? state.focusedCardIndex : null,
            isRowFocused: state.focusedRowIndex == i,
            onCardFocused: (int cardIndex) {
              _homeBloc.add(HomeGameFocused(
                game: state.rows[i].games[cardIndex],
                rowIndex: i,
                cardIndex: cardIndex,
              ));
            },
            onCardSelected: (int cardIndex) {
              _handleGameLaunched(state.rows[i].games[cardIndex]);
            },
            onHeaderFocused: () {
              _homeBloc.add(HomeRowHeaderFocused(row: state.rows[i]));
            },
            onHeaderActivated: () {
              _homeBloc.add(HomeRowHeaderActivated(row: state.rows[i]));
              if (state.rows[i].isNavigable && state.rows[i].type == HomeRowType.allGames) {
                _handleNavigateToLibrary();
              }
            },
          ),
          if (i < state.rows.length - 1)
            const SizedBox(height: AppSpacing.lg),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

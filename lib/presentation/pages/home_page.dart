import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/presentation/blocs/home/home_bloc.dart';
import 'package:squirrel_play/presentation/widgets/add_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/home/dynamic_background.dart';
import 'package:squirrel_play/presentation/widgets/home/empty_home_state.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/error_localizer.dart';
import 'package:squirrel_play/presentation/widgets/home/error_home_state.dart';
import 'package:squirrel_play/presentation/widgets/home/game_card_row.dart';
import 'package:squirrel_play/presentation/widgets/home/game_info_overlay.dart';
import 'package:squirrel_play/presentation/widgets/home/launch_overlay.dart';
import 'package:squirrel_play/presentation/widgets/home/loading_home_state.dart';

/// The home page of the application with Netflix-style layout.
///
/// Features a full-viewport dynamic background with:
/// - Hero image background for focused game
/// - Left-aligned game info overlay (title, description, genres)
/// - Single horizontal scrolling card row with "View All" button
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
    AddGameDialog.show(context);
  }

  void _handleScanDirectory() {
    SoundService.instance.playFocusSelect();
    AddGameDialog.show(context, initialTab: 1);
  }

  void _handleNavigateToLibrary() {
    SoundService.instance.playPageTransition();
    context.go('/library');
  }

  void _handleGameSelected(Game game) {
    context.go('/game/${game.id}');
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
        message: localizeError(
          AppLocalizations.of(context),
          state.localizationKey ?? '',
          details: state.details,
        ),
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
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: Full-screen dynamic background
        Positioned.fill(
          child: DynamicBackground(
            game: focusedGame,
            metadata: state.focusedGameMetadata,
            crossfadeDuration: const Duration(milliseconds: 800),
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

        // Layer 2: Bottom-to-top gradient for card row readability
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

        // Layer 3: Content layout
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top padding for status bar + top bar
            SizedBox(height: topPadding + 80),

            // Game info section (left-aligned, bottom of upper area)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: GameInfoOverlay(
                      game: focusedGame,
                      metadata: state.focusedGameMetadata,
                      isVisible: focusedGame != null,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Card row area
            SizedBox(
              height: _getCardHeight(context),
              child: _buildCardRow(context, state),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),

        // Layer 4: Launch overlay
        LaunchOverlay(
          gameName: focusedGame?.title ?? 'Game',
          isVisible: state.isLaunching,
        ),
      ],
    );
  }

  Widget _buildCardRow(BuildContext context, HomeLoaded state) {
    if (state.rows.isEmpty) return const SizedBox.shrink();

    final row = state.rows.first;
    final maxVisibleGames = _getMaxVisibleGames(context);

    return GameCardRow(
      key: const ValueKey('featured_row'),
      row: row,
      rowIndex: 0,
      maxVisibleGames: maxVisibleGames,
      focusedCardIndex: state.focusedRowIndex == 0 ? state.focusedCardIndex : null,
      isRowFocused: state.focusedRowIndex == 0,
      onCardFocused: (int cardIndex) {
        _homeBloc.add(HomeGameFocused(
          game: row.games[cardIndex],
          rowIndex: 0,
          cardIndex: cardIndex,
        ));
      },
      onCardSelected: (int cardIndex) {
        _handleGameSelected(row.games[cardIndex]);
      },
      onHeaderFocused: () {
        _homeBloc.add(HomeRowHeaderFocused(row: row));
      },
      onHeaderActivated: () {
        _homeBloc.add(HomeRowHeaderActivated(row: row));
        if (row.isNavigable && row.type == HomeRowType.allGames) {
          _handleNavigateToLibrary();
        }
      },
      onViewAllPressed: _handleNavigateToLibrary,
    );
  }

  /// Gets the maximum number of visible game cards based on screen size.
  int _getMaxVisibleGames(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    switch (breakpoint) {
      case ResponsiveLayout.compact:
        return 3;
      case ResponsiveLayout.medium:
        return 4;
      case ResponsiveLayout.expanded:
        return 5;
      case ResponsiveLayout.large:
        return 6;
    }
  }

  /// Gets the card height for the current breakpoint.
  double _getCardHeight(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    return CardDimensions.getHeight(breakpoint);
  }
}

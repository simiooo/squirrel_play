import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:squirrel_play/app/di.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/game_library/game_library_bloc.dart';
import 'package:squirrel_play/presentation/widgets/add_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/delete_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/empty_state_widget.dart';
import 'package:squirrel_play/presentation/widgets/error_localizer.dart';
import 'package:squirrel_play/presentation/widgets/error_state_widget.dart';
import 'package:squirrel_play/presentation/widgets/game_grid.dart';

/// The library page of the application.
///
/// Displays a responsive grid of all games in the library.
/// Supports gamepad navigation and game deletion.
class LibraryPage extends StatefulWidget {
  /// Creates the library page.
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GameLibraryBloc>()..add(const LoadGames()),
      child: const _LibraryPageContent(),
    );
  }
}

class _LibraryPageContent extends StatefulWidget {
  const _LibraryPageContent();

  @override
  State<_LibraryPageContent> createState() => _LibraryPageContentState();
}

class _LibraryPageContentState extends State<_LibraryPageContent> {
  Future<void> _deleteGame(Game game) async {
    final confirmed = await DeleteGameDialog.show(context, game);

    if (confirmed && mounted) {
      context.read<GameLibraryBloc>().add(DeleteGame(game.id));
    }
  }

  void _handleGameSelected(Game game) {
    context.go('/game/${game.id}');
  }

  void _showAddGameDialog() {
    AddGameDialog.show(context).then((_) {
      // Reload games after dialog closes
      if (mounted) {
        context.read<GameLibraryBloc>().add(const GameAdded());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n?.pageLibrary ?? 'Library',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<GameLibraryBloc, GameLibraryState>(
              builder: (context, state) {
                if (state is LibraryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is LibraryError) {
                  return ErrorStateWidget(
                    message: localizeError(
                      l10n,
                      state.localizationKey ?? '',
                      details: state.details,
                    ),
                    onRetry: () {
                      context.read<GameLibraryBloc>().add(const RetryLoad());
                    },
                  );
                } else if (state is LibraryEmpty) {
                  return EmptyStateWidget(
                    title: l10n?.libraryEmptyState ?? 'Your game library is empty.',
                    message: 'Add games to your library to see them here.',
                    buttonLabel: l10n?.emptyStateAddGame ?? 'Add your first game',
                    onButtonPressed: _showAddGameDialog,
                    icon: Icons.library_books_outlined,
                  );
                } else if (state is LibraryLoaded) {
                  return GameGrid(
                    games: state.games,
                    focusedIndex: state.focusedIndex,
                    onGameSelected: _handleGameSelected,
                    onGameDeleted: _deleteGame,
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

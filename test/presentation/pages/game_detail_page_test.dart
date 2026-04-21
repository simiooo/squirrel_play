import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/blocs/game_detail/game_detail_bloc.dart';
import 'package:squirrel_play/presentation/navigation/focus_traversal.dart';
import 'package:squirrel_play/presentation/pages/game_detail_page.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

class MockGameDetailBloc
    extends MockBloc<GameDetailEvent, GameDetailState>
    implements GameDetailBloc {}

void main() {
  group('GameDetailPage', () {
    late MockGameDetailBloc mockBloc;

    final testGame = Game(
      id: 'test-game-1',
      title: 'Test Game Title',
      executablePath: '/games/test.exe',
      addedDate: DateTime(2024, 1, 1),
      playCount: 5,
      lastPlayedDate: DateTime(2024, 6, 15),
      isFavorite: true,
    );

    final testMetadata = GameMetadata(
      gameId: 'test-game-1',
      description: 'A test game description',
      developer: 'Test Developer',
      lastFetched: DateTime.now(),
    );

    setUp(() {
      mockBloc = MockGameDetailBloc();
      FocusTraversalService.instance.initialize();
    });

    tearDown(() {
      mockBloc.close();
      FocusTraversalService.instance.dispose();
    });

    Widget buildTestWidget(GameDetailState state) {
      when(() => mockBloc.state).thenReturn(state);
      whenListen(
        mockBloc,
        Stream.fromIterable([state]),
      );
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
        ],
        home: BlocProvider<GameDetailBloc>(
          create: (_) => mockBloc,
          child: const GameDetailPage(),
        ),
      );
    }

    testWidgets('renders loading state with CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const GameDetailLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders loaded state with game title', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Test Game Title'), findsOneWidget);
    });

    testWidgets('renders loaded state with description', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('A test game description'), findsOneWidget);
    });

    testWidgets('renders loaded state with developer', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Test Developer'), findsOneWidget);
    });

    testWidgets('renders play count stat', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Played 5 times'), findsOneWidget);
    });

    testWidgets('renders last played stat', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.textContaining('Last played'), findsOneWidget);
    });

    testWidgets('renders favorite stat when game is favorite', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Add to Favorites'), findsOneWidget);
    });

    testWidgets('renders error state with localized message', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        const GameDetailError(type: GameDetailErrorType.gameNotFound),
      ));

      expect(find.text('Game not found'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays all three action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Launch Game'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('action buttons are FocusableButton widgets', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.byType(FocusableButton), findsNWidgets(5));
    });

    testWidgets('focus is on first action button after settle', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      final focusManager = tester.binding.focusManager;
      final primaryFocus = focusManager.primaryFocus;

      expect(primaryFocus, isNotNull);
      expect(primaryFocus!.debugLabel, 'LaunchStopButton');
    });

    testWidgets('navigates focus between action buttons with arrow keys',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      // Initial focus should be on launch/stop button
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'LaunchStopButton',
      );

      // Press right arrow to move to settings button
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'SettingsButton',
      );

      // Press right arrow to move to refresh metadata button
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'RefreshMetadataButton',
      );

      // Press right arrow to move to delete button
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'DeleteButton',
      );

      // Press left arrow to move back to refresh metadata button
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'RefreshMetadataButton',
      );
    });

    testWidgets('renders description fallback when metadata is null',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: null,
      )));

      await tester.pumpAndSettle();

      expect(find.text('No description available'), findsOneWidget);
    });

    testWidgets('does not show favorite stat when game is not favorite',
        (tester) async {
      final nonFavoriteGame = testGame.copyWith(isFavorite: false);

      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: nonFavoriteGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Add to Favorites'), findsNothing);
    });

    testWidgets('renders singular play count correctly', (tester) async {
      final onePlayGame = testGame.copyWith(playCount: 1);

      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: onePlayGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Played 1 times'), findsOneWidget);
    });

    testWidgets('when isRunning true, shows only Stop and Settings buttons',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
        isRunning: true,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
      expect(find.byType(FocusableButton), findsNWidgets(4));
    });

    testWidgets('when isRunning false, shows Launch, Settings, Delete buttons',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
        isRunning: false,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Launch Game'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byType(FocusableButton), findsNWidgets(5));
    });

    testWidgets('tapping Settings button opens EditGameDialog',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
        isRunning: false,
      )));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Dialog should be open with localized title
      expect(find.text('Edit Game'), findsOneWidget);
    });

    testWidgets('tapping Delete button opens DeleteGameDialog',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
        isRunning: false,
      )));

      await tester.pumpAndSettle();

      // Ensure Delete button is visible before tapping (it may be off-screen
      // in the scrollable action button row).
      await tester.ensureVisible(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Dialog should be open with localized title
      expect(find.text('Delete Game?'), findsOneWidget);
    });

    testWidgets('renders play count as never played when count is zero',
        (tester) async {
      final neverPlayedGame = testGame.copyWith(playCount: 0);

      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: neverPlayedGame,
        metadata: testMetadata,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Never played'), findsOneWidget);
    });

    testWidgets('renders with null metadata gracefully', (tester) async {
      await tester.pumpWidget(buildTestWidget(GameDetailLoaded(
        game: testGame,
        metadata: null,
      )));

      await tester.pumpAndSettle();

      expect(find.text('Test Game Title'), findsOneWidget);
      expect(find.text('No description available'), findsOneWidget);
    });

    testWidgets(
        'focus moves from Delete to Stop when isRunning becomes true',
        (tester) async {
      final initialState = GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
        isRunning: false,
      );
      final runningState = GameDetailLoaded(
        game: testGame,
        metadata: testMetadata,
        isRunning: true,
      );

      final controller = StreamController<GameDetailState>();

      when(() => mockBloc.state).thenReturn(initialState);
      whenListen(mockBloc, controller.stream);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('zh'),
          ],
          home: BlocProvider<GameDetailBloc>(
            create: (_) => mockBloc,
            child: const GameDetailPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state shows Launch button
      expect(find.text('Launch Game'), findsOneWidget);

      // Focus should be on LaunchStopButton initially
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'LaunchStopButton',
      );

      // Move focus to Delete button (right, right, right)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'DeleteButton',
      );

      // Emit running state and verify widget rebuilds
      controller.add(runningState);
      await tester.pumpAndSettle();

      // The button text should have changed to Stop
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);

      // Focus should have moved to LaunchStopButton (Stop button)
      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'LaunchStopButton',
      );

      await controller.close();
    });
  });
}

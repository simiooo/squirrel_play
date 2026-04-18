import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/l10n/app_localizations.dart';
import 'package:squirrel_play/presentation/widgets/edit_game_dialog.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

void main() {
  group('EditGameDialog', () {
    final testGame = Game(
      id: 'test-game-1',
      title: 'Test Game Title',
      executablePath: '/games/test.exe',
      addedDate: DateTime(2024, 1, 1),
      playCount: 5,
      launchArguments: '-windowed',
    );

    Future<void> showDialogInTest(
      WidgetTester tester,
      Game game,
      void Function(Game) onSave,
    ) async {
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
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => EditGameDialog.show(context, game, onSave),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders with pre-populated fields', (tester) async {
      await showDialogInTest(tester, testGame, (_) {});

      expect(find.text('Test Game Title'), findsOneWidget);
      expect(find.text('/games/test.exe'), findsOneWidget);
      expect(find.text('-windowed'), findsOneWidget);
    });

    testWidgets('has Save and Cancel buttons', (tester) async {
      await showDialogInTest(tester, testGame, (_) {});

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(FocusableButton), findsNWidgets(3)); // Save, Cancel, Browse
    });

    testWidgets('calls onSave with updated game when Save pressed',
        (tester) async {
      Game? savedGame;

      await showDialogInTest(tester, testGame, (game) {
        savedGame = game;
      });

      // Clear title field and enter new title
      final titleField = find.byType(TextField).first;
      await tester.tap(titleField);
      await tester.pump();
      await tester.enterText(titleField, 'New Title');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedGame, isNotNull);
      expect(savedGame!.title, 'New Title');
      expect(savedGame!.executablePath, '/games/test.exe');
      expect(savedGame!.launchArguments, '-windowed');
    });

    testWidgets('updates launch arguments when field is changed',
        (tester) async {
      Game? savedGame;

      await showDialogInTest(tester, testGame, (game) {
        savedGame = game;
      });

      // Update launch arguments field
      final argsField = find.byType(TextField).last;
      await tester.tap(argsField);
      await tester.pump();
      await tester.enterText(argsField, '--fullscreen');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedGame, isNotNull);
      expect(savedGame!.launchArguments, '--fullscreen');
    });

    testWidgets('does not call onSave when Cancel pressed', (tester) async {
      var saveCalled = false;

      await showDialogInTest(tester, testGame, (_) {
        saveCalled = true;
      });

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(saveCalled, isFalse);
    });

    testWidgets('has Browse button for executable path', (tester) async {
      await showDialogInTest(tester, testGame, (_) {});

      expect(find.text('Browse'), findsOneWidget);
    });

    testWidgets('escape key dismisses dialog without saving', (tester) async {
      var saveCalled = false;

      await showDialogInTest(tester, testGame, (_) {
        saveCalled = true;
      });

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing);
      expect(saveCalled, isFalse);
    });

    testWidgets('focus is on title field initially', (tester) async {
      await showDialogInTest(tester, testGame, (_) {});

      final primaryFocus = tester.binding.focusManager.primaryFocus;
      expect(primaryFocus, isNotNull);
      expect(primaryFocus!.debugLabel, 'EditTitle');
    });
  });
}

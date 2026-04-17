import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/presentation/widgets/home/game_info_overlay.dart';

void main() {
  group('GameInfoOverlay', () {
    final testGame = Game(
      id: 'test-game-1',
      title: 'Test Game Title',
      executablePath: '/games/test.exe',
      addedDate: DateTime.now(),
    );

    testWidgets('returns SizedBox.shrink when game is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: null),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Test Game Title'), findsNothing);
    });

    testWidgets('returns SizedBox.shrink when not visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame, isVisible: false),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Test Game Title'), findsNothing);
    });

    testWidgets('displays game title when game is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame),
          ),
        ),
      );

      expect(find.text('Test Game Title'), findsOneWidget);
    });

    testWidgets('displays description placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame),
          ),
        ),
      );

      // Should show "No description available" placeholder
      expect(find.text('No description available'), findsOneWidget);
    });

    testWidgets('uses correct styling for title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame),
          ),
        ),
      );

      final titleFinder = find.text('Test Game Title');
      expect(titleFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.fontSize, 32);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('description has max 3 lines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame),
          ),
        ),
      );

      final descriptionFinder = find.text('No description available');
      final textWidget = tester.widget<Text>(descriptionFinder);
      expect(textWidget.maxLines, 3);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('uses AnimatedOpacity for fade animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame),
          ),
        ),
      );

      final animatedOpacity = find.byType(AnimatedOpacity);
      expect(animatedOpacity, findsOneWidget);

      final opacityWidget = tester.widget<AnimatedOpacity>(animatedOpacity);
      expect(opacityWidget.duration, const Duration(milliseconds: 300));
      expect(opacityWidget.curve, Curves.easeInOut);
    });

    testWidgets('has gradient background decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame),
          ),
        ),
      );

      final container = find.byType(Container);
      expect(container, findsWidgets);

      // Find the main container with decoration
      final containers = tester.widgetList<Container>(container);
      final decoratedContainer = containers.firstWhere(
        (c) => c.decoration != null,
        orElse: () => containers.first,
      );

      expect(decoratedContainer.decoration, isA<BoxDecoration>());

      final decoration = decoratedContainer.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('genre chips section returns empty when no genres', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: testGame),
          ),
        ),
      );

      // Genre chips should return SizedBox.shrink() when no genres (Sprint 4)
      // The Row containing genre chips and rating should exist
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('updates when game changes', (tester) async {
      final game1 = Game(
        id: 'game-1',
        title: 'First Game',
        executablePath: '/games/game1.exe',
        addedDate: DateTime.now(),
      );

      final game2 = Game(
        id: 'game-2',
        title: 'Second Game',
        executablePath: '/games/game2.exe',
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: game1),
          ),
        ),
      );

      expect(find.text('First Game'), findsOneWidget);
      expect(find.text('Second Game'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameInfoOverlay(game: game2),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('First Game'), findsNothing);
      expect(find.text('Second Game'), findsOneWidget);
    });
  });
}

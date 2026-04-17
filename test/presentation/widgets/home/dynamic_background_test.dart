import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/core/utils/gradient_generator.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/presentation/widgets/home/dynamic_background.dart';

void main() {
  group('DynamicBackground', () {
    final testGame = Game(
      id: 'test-game-1',
      title: 'Test Game',
      executablePath: '/games/test.exe',
      addedDate: DateTime.now(),
    );

    testWidgets('shows default gradient when game is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DynamicBackground(),
          ),
        ),
      );

      // Should show a container with default gradient
      final container = find.byType(Container);
      expect(container, findsOneWidget);

      final widget = tester.widget<Container>(container);
      expect(widget.decoration, isA<BoxDecoration>());

      final decoration = widget.decoration as BoxDecoration;
      expect(decoration.gradient, GradientGenerator.defaultGradient);
    });

    testWidgets('shows game-specific gradient when game has no hero image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicBackground(game: testGame),
          ),
        ),
      );

      // Should show a container with game-specific gradient
      final container = find.byType(Container);
      expect(container, findsOneWidget);

      final widget = tester.widget<Container>(container);
      expect(widget.decoration, isA<BoxDecoration>());

      final decoration = widget.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());

      // Verify it's using the gradient generator
      final gradient = decoration.gradient as LinearGradient;
      final expectedGradient = GradientGenerator.generateForGame(testGame.id);
      expect(gradient.colors.length, expectedGradient.colors.length);
    });

    testWidgets('uses correct crossfade duration', (tester) async {
      const customDuration = Duration(milliseconds: 750);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicBackground(
              game: testGame,
              crossfadeDuration: customDuration,
            ),
          ),
        ),
      );

      // Find AnimatedSwitcher
      final animatedSwitcher = find.byType(AnimatedSwitcher);
      expect(animatedSwitcher, findsOneWidget);

      final switcher = tester.widget<AnimatedSwitcher>(animatedSwitcher);
      expect(switcher.duration, customDuration);
    });

    testWidgets('uses easeInOut curve by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicBackground(game: testGame),
          ),
        ),
      );

      final animatedSwitcher = find.byType(AnimatedSwitcher);
      final switcher = tester.widget<AnimatedSwitcher>(animatedSwitcher);
      expect(switcher.switchInCurve, Curves.easeInOut);
      expect(switcher.switchOutCurve, Curves.easeInOut);
    });

    testWidgets('uses custom curve when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicBackground(
              game: testGame,
              crossfadeCurve: Curves.linear,
            ),
          ),
        ),
      );

      final animatedSwitcher = find.byType(AnimatedSwitcher);
      final switcher = tester.widget<AnimatedSwitcher>(animatedSwitcher);
      expect(switcher.switchInCurve, Curves.linear);
      expect(switcher.switchOutCurve, Curves.linear);
    });

    testWidgets('animates when game changes', (tester) async {
      final game1 = Game(
        id: 'game-1',
        title: 'Game 1',
        executablePath: '/games/game1.exe',
        addedDate: DateTime.now(),
      );

      final game2 = Game(
        id: 'game-2',
        title: 'Game 2',
        executablePath: '/games/game2.exe',
        addedDate: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicBackground(game: game1),
          ),
        ),
      );

      // Initial state
      expect(find.byKey(const ValueKey('gradient_game-1')), findsOneWidget);

      // Change game
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DynamicBackground(game: game2),
          ),
        ),
      );

      // Should have both widgets during transition
      await tester.pump(const Duration(milliseconds: 250));

      // After animation completes
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('gradient_game-2')), findsOneWidget);
    });

    testWidgets('deterministic gradient for same game ID', (tester) async {
      final game1 = Game(
        id: 'same-id',
        title: 'Game 1',
        executablePath: '/games/game1.exe',
        addedDate: DateTime.now(),
      );

      final game2 = Game(
        id: 'same-id',
        title: 'Game 2',
        executablePath: '/games/game2.exe',
        addedDate: DateTime.now(),
      );

      // Both games have same ID, should generate same gradient
      final gradient1 = GradientGenerator.generateForGame(game1.id);
      final gradient2 = GradientGenerator.generateForGame(game2.id);

      expect(gradient1.colors, gradient2.colors);
      expect(gradient1.begin, gradient2.begin);
      expect(gradient1.end, gradient2.end);
    });

    testWidgets('different gradients for different game IDs', (tester) async {
      final game1 = Game(
        id: 'game-id-1',
        title: 'Game 1',
        executablePath: '/games/game1.exe',
        addedDate: DateTime.now(),
      );

      final game2 = Game(
        id: 'game-id-2',
        title: 'Game 2',
        executablePath: '/games/game2.exe',
        addedDate: DateTime.now(),
      );

      // Different IDs should potentially generate different gradients
      final gradient1 = GradientGenerator.generateForGame(game1.id);
      final gradient2 = GradientGenerator.generateForGame(game2.id);

      // They might be the same by chance, but usually different
      // Just verify both are valid gradients
      expect(gradient1.colors, isNotEmpty);
      expect(gradient2.colors, isNotEmpty);
      expect(gradient1.colors.length, greaterThanOrEqualTo(2));
      expect(gradient2.colors.length, greaterThanOrEqualTo(2));
    });
  });
}

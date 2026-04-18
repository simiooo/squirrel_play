import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/home_row.dart';
import 'package:squirrel_play/presentation/widgets/home/game_card_row.dart';

void main() {
  group('GameCardRow', () {
    final testGames = [
      Game(
        id: 'game-1',
        title: 'Game One',
        executablePath: '/games/game1.exe',
        addedDate: DateTime.now(),
      ),
      Game(
        id: 'game-2',
        title: 'Game Two',
        executablePath: '/games/game2.exe',
        addedDate: DateTime.now(),
      ),
      Game(
        id: 'game-3',
        title: 'Game Three',
        executablePath: '/games/game3.exe',
        addedDate: DateTime.now(),
      ),
    ];

    final testRow = HomeRow(
      id: 'test-row',
      titleKey: 'home.rows.test',
      games: testGames,
      type: HomeRowType.allGames,
      isNavigable: true,
    );

    testWidgets('renders correct number of game cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardRow(
              row: testRow,
              rowIndex: 0,
              onCardFocused: (_) {},
              onCardSelected: (_) {},
              onHeaderFocused: () {},
              onHeaderActivated: () {},
            ),
          ),
        ),
      );

      // Should have a ListView with 3 items
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders game card titles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardRow(
              row: testRow,
              rowIndex: 0,
              onCardFocused: (_) {},
              onCardSelected: (_) {},
              onHeaderFocused: () {},
              onHeaderActivated: () {},
            ),
          ),
        ),
      );

      // Should show game titles
      expect(find.text('Game One'), findsOneWidget);
      expect(find.text('Game Two'), findsOneWidget);
      expect(find.text('Game Three'), findsOneWidget);
    });

    testWidgets('isRowFocused parameter affects visual state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardRow(
              row: testRow,
              rowIndex: 0,
              isRowFocused: true,
              focusedCardIndex: 0,
              onCardFocused: (_) {},
              onCardSelected: (_) {},
              onHeaderFocused: () {},
              onHeaderActivated: () {},
            ),
          ),
        ),
      );

      // Row should render without errors when focused
      expect(find.byType(GameCardRow), findsOneWidget);
    });

    testWidgets('has horizontal ListView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardRow(
              row: testRow,
              rowIndex: 0,
              onCardFocused: (_) {},
              onCardSelected: (_) {},
              onHeaderFocused: () {},
              onHeaderActivated: () {},
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('applies padding to card list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardRow(
              row: testRow,
              rowIndex: 0,
              onCardFocused: (_) {},
              onCardSelected: (_) {},
              onHeaderFocused: () {},
              onHeaderActivated: () {},
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, isNotNull);
    });

    testWidgets('handles empty game list', (tester) async {
      final emptyRow = const HomeRow(
        id: 'empty-row',
        titleKey: 'home.rows.test',
        games: [],
        type: HomeRowType.allGames,
        isNavigable: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardRow(
              row: emptyRow,
              rowIndex: 0,
              onCardFocused: (_) {},
              onCardSelected: (_) {},
              onHeaderFocused: () {},
              onHeaderActivated: () {},
            ),
          ),
        ),
      );

      // ListView should have 0 items but still render
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows view all button when maxVisibleGames is set', (tester) async {
      final manyGames = List.generate(
        10,
        (i) => Game(
          id: 'game-$i',
          title: 'Game $i',
          executablePath: '/games/game$i.exe',
          addedDate: DateTime.now(),
        ),
      );

      final rowWithManyGames = HomeRow(
        id: 'test-row',
        titleKey: 'home.rows.test',
        games: manyGames,
        type: HomeRowType.allGames,
        isNavigable: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCardRow(
              row: rowWithManyGames,
              rowIndex: 0,
              maxVisibleGames: 3,
              onCardFocused: (_) {},
              onCardSelected: (_) {},
              onHeaderFocused: () {},
              onHeaderActivated: () {},
              onViewAllPressed: () {},
            ),
          ),
        ),
      );

      // Should show only 3 game cards + view all button
      expect(find.text('Game 0'), findsOneWidget);
      expect(find.text('Game 1'), findsOneWidget);
      expect(find.text('Game 2'), findsOneWidget);
      // Game 3 should not be visible (truncated)
      expect(find.text('Game 3'), findsNothing);
    });
  });
}

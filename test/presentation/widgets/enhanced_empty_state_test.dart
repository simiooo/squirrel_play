import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/presentation/widgets/enhanced_empty_state.dart';

void main() {
  group('EnhancedEmptyState', () {
    testWidgets('renders no games state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedEmptyState.noGames(),
        ),
      );

      expect(find.text('No Games Yet'), findsOneWidget);
      expect(find.text('Add your first game to get started'), findsOneWidget);
      expect(find.byIcon(Icons.videogame_asset_outlined), findsOneWidget);
    });

    testWidgets('renders no search results state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedEmptyState.noSearchResults(),
        ),
      );

      expect(find.text('No Results'), findsOneWidget);
      expect(find.text('Try a different search term'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
    });

    testWidgets('renders API unreachable state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedEmptyState.apiUnreachable(),
        ),
      );

      expect(find.text("Can't Connect"), findsOneWidget);
      expect(
        find.text('Game info unavailable. You can still play your games.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('calls onPrimaryAction when primary button pressed',
        (WidgetTester tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedEmptyState.noGames(
            onPrimaryAction: () => actionCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Add your first game'));
      await tester.pump();

      expect(actionCalled, true);
    });

    testWidgets('calls onSecondaryAction when secondary button pressed',
        (WidgetTester tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedEmptyState.noGames(
            onPrimaryAction: () {},
            onSecondaryAction: () => actionCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Scan Directory'));
      await tester.pump();

      expect(actionCalled, true);
    });

    testWidgets('no games state shows both buttons when callbacks provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedEmptyState.noGames(
            onPrimaryAction: () {},
            onSecondaryAction: () {},
          ),
        ),
      );

      expect(find.text('Add your first game'), findsOneWidget);
      expect(find.text('Scan Directory'), findsOneWidget);
    });

    testWidgets('API unreachable state shows retry button',
        (WidgetTester tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedEmptyState.apiUnreachable(
            onPrimaryAction: () => retryCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCalled, true);
    });
  });
}

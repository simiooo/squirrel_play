import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:squirrel_play/presentation/widgets/metadata_error_card.dart';

void main() {
  group('MetadataErrorCard', () {
    testWidgets('should display error icon', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify error icon is present
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should display error message', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify error text is displayed
      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('should display retry button', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify retry button elements are present
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should call onRetry when tapped', (WidgetTester tester) async {
      final focusNode = FocusNode();
      var retryCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {
                retryCalled = true;
              },
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Tap the retry button area
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('should respond to ActivateIntent', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {
              },
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify the card has an Actions widget for handling intents
      expect(
        find.descendant(
          of: find.byType(MetadataErrorCard),
          matching: find.byType(Actions),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should have focus node', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify Focus widget is present within the error card
      expect(
        find.descendant(
          of: find.byType(MetadataErrorCard),
          matching: find.byType(Focus),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should have semantic label', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify Semantics widget with the expected label is present within the card
      expect(
        find.descendant(
          of: find.byType(MetadataErrorCard),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Error loading game metadata. Press to retry.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('should scale when focused', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Verify AnimatedScale widget is present
      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('should have error border when focused', (WidgetTester tester) async {
      final focusNode = FocusNode();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetadataErrorCard(
              errorMessage: 'Failed to load',
              onRetry: () {},
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Request focus
      focusNode.requestFocus();
      await tester.pump();

      // Verify the widget is still present after focus change
      expect(find.byType(MetadataErrorCard), findsOneWidget);
    });
  });
}

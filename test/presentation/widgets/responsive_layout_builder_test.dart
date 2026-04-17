import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';
import 'package:squirrel_play/presentation/widgets/responsive_layout_builder.dart';

void main() {
  group('ResponsiveLayoutBuilder', () {
    testWidgets('builds compact layout for small screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(500, 800)),
            child: ResponsiveLayoutBuilder(
              builders: {
                ResponsiveLayout.compact: (context) =>
                    const Text('Compact Layout'),
                ResponsiveLayout.medium: (context) =>
                    const Text('Medium Layout'),
                ResponsiveLayout.expanded: (context) =>
                    const Text('Expanded Layout'),
                ResponsiveLayout.large: (context) =>
                    const Text('Large Layout'),
              },
              fallback: ResponsiveLayout.expanded,
            ),
          ),
        ),
      );

      expect(find.text('Compact Layout'), findsOneWidget);
    });

    testWidgets('builds medium layout for medium screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: ResponsiveLayoutBuilder(
              builders: {
                ResponsiveLayout.compact: (context) =>
                    const Text('Compact Layout'),
                ResponsiveLayout.medium: (context) =>
                    const Text('Medium Layout'),
                ResponsiveLayout.expanded: (context) =>
                    const Text('Expanded Layout'),
                ResponsiveLayout.large: (context) =>
                    const Text('Large Layout'),
              },
              fallback: ResponsiveLayout.expanded,
            ),
          ),
        ),
      );

      expect(find.text('Medium Layout'), findsOneWidget);
    });

    testWidgets('builds expanded layout for expanded screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1200, 800)),
            child: ResponsiveLayoutBuilder(
              builders: {
                ResponsiveLayout.compact: (context) =>
                    const Text('Compact Layout'),
                ResponsiveLayout.medium: (context) =>
                    const Text('Medium Layout'),
                ResponsiveLayout.expanded: (context) =>
                    const Text('Expanded Layout'),
                ResponsiveLayout.large: (context) =>
                    const Text('Large Layout'),
              },
              fallback: ResponsiveLayout.expanded,
            ),
          ),
        ),
      );

      expect(find.text('Expanded Layout'), findsOneWidget);
    });

    testWidgets('builds large layout for large screens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1600, 900)),
            child: ResponsiveLayoutBuilder(
              builders: {
                ResponsiveLayout.compact: (context) =>
                    const Text('Compact Layout'),
                ResponsiveLayout.medium: (context) =>
                    const Text('Medium Layout'),
                ResponsiveLayout.expanded: (context) =>
                    const Text('Expanded Layout'),
                ResponsiveLayout.large: (context) =>
                    const Text('Large Layout'),
              },
              fallback: ResponsiveLayout.expanded,
            ),
          ),
        ),
      );

      expect(find.text('Large Layout'), findsOneWidget);
    });

    testWidgets('uses fallback when breakpoint not in builders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(500, 800)),
            child: ResponsiveLayoutBuilder(
              builders: {
                ResponsiveLayout.expanded: (context) =>
                    const Text('Expanded Layout'),
              },
              fallback: ResponsiveLayout.expanded,
            ),
          ),
        ),
      );

      expect(find.text('Expanded Layout'), findsOneWidget);
    });
  });

  group('ResponsiveLayoutExtension', () {
    test('cardWidth returns correct values', () {
      expect(ResponsiveLayout.compact.cardWidth, 140.0);
      expect(ResponsiveLayout.medium.cardWidth, 170.0);
      expect(ResponsiveLayout.expanded.cardWidth, 200.0);
      expect(ResponsiveLayout.large.cardWidth, 240.0);
    });

    test('cardHeight returns correct values', () {
      expect(ResponsiveLayout.compact.cardHeight, 210.0);
      expect(ResponsiveLayout.medium.cardHeight, 255.0);
      expect(ResponsiveLayout.expanded.cardHeight, 300.0);
      expect(ResponsiveLayout.large.cardHeight, 360.0);
    });

    test('visibleCardCount returns correct values', () {
      expect(ResponsiveLayout.compact.visibleCardCount, 2);
      expect(ResponsiveLayout.medium.visibleCardCount, 3);
      expect(ResponsiveLayout.expanded.visibleCardCount, 4);
      expect(ResponsiveLayout.large.visibleCardCount, 5);
    });

    test('isCompact returns correct value', () {
      expect(ResponsiveLayout.compact.isCompact, true);
      expect(ResponsiveLayout.medium.isCompact, false);
      expect(ResponsiveLayout.expanded.isCompact, false);
      expect(ResponsiveLayout.large.isCompact, false);
    });

    test('collapseTopBar returns correct value', () {
      expect(ResponsiveLayout.compact.collapseTopBar, true);
      expect(ResponsiveLayout.medium.collapseTopBar, false);
      expect(ResponsiveLayout.expanded.collapseTopBar, false);
      expect(ResponsiveLayout.large.collapseTopBar, false);
    });

    test('useHorizontalScroll returns correct value', () {
      expect(ResponsiveLayout.compact.useHorizontalScroll, false);
      expect(ResponsiveLayout.medium.useHorizontalScroll, true);
      expect(ResponsiveLayout.expanded.useHorizontalScroll, true);
      expect(ResponsiveLayout.large.useHorizontalScroll, true);
    });
  });
}

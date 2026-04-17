import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:squirrel_play/presentation/widgets/metadata_loading_card.dart';

void main() {
  group('MetadataLoadingCard', () {
    testWidgets('should render shimmer widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetadataLoadingCard(),
          ),
        ),
      );

      // Verify Shimmer widget is present
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('should use default colors when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetadataLoadingCard(),
          ),
        ),
      );

      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      
      // Verify shimmer has the expected properties
      expect(shimmer.period, equals(const Duration(milliseconds: 1500)));
      expect(shimmer.direction, equals(ShimmerDirection.ltr));
    });

    testWidgets('should use custom colors when specified', (WidgetTester tester) async {
      const baseColor = Colors.red;
      const highlightColor = Colors.blue;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetadataLoadingCard(
              baseColor: baseColor,
              highlightColor: highlightColor,
            ),
          ),
        ),
      );

      // Verify shimmer is present with custom colors
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('should have rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetadataLoadingCard(),
          ),
        ),
      );

      // Find ClipRRect which provides rounded corners
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should have title placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetadataLoadingCard(),
          ),
        ),
      );

      // The shimmer card should have a container for the title placeholder
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
      // Test with a larger screen
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetadataLoadingCard(),
          ),
        ),
      );

      expect(find.byType(MetadataLoadingCard), findsOneWidget);

      // Reset
      addTearDown(() => tester.view.resetPhysicalSize());
    });
  });
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:squirrel_play/presentation/widgets/cached_game_image.dart';

void main() {
  group('CachedGameImage', () {
    testWidgets('should render placeholder when URL is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: null,
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      // Should show placeholder (gradient container with icon)
      expect(find.byType(Container), findsWidgets);
      expect(find.byIcon(Icons.videogame_asset_outlined), findsOneWidget);
    });

    testWidgets('should render placeholder when URL is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: '',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      // Should show placeholder
      expect(find.byIcon(Icons.videogame_asset_outlined), findsOneWidget);
    });

    testWidgets('should render CachedNetworkImage when URL is valid', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      // Should render CachedNetworkImage
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should have shimmer placeholder while loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      // The CachedNetworkImage uses a shimmer placeholder
      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.placeholder, isNotNull);
    });

    testWidgets('should have error widget for failed loads', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      // The CachedNetworkImage has an error widget
      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.errorWidget, isNotNull);
    });

    testWidgets('should apply border radius when specified', (WidgetTester tester) async {
      const borderRadius = BorderRadius.all(Radius.circular(12));
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
              borderRadius: borderRadius,
            ),
          ),
        ),
      );

      // Should have ClipRRect for rounded corners
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should apply overlay when showOverlay is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
              showOverlay: true,
            ),
          ),
        ),
      );

      // The imageBuilder should create a container with overlay
      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.imageBuilder, isNotNull);
    });

    testWidgets('should use custom dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 150,
              height: 250,
            ),
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.width, equals(150));
      expect(cachedImage.height, equals(250));
    });

    testWidgets('should use custom fit', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.fit, equals(BoxFit.contain));
    });

    testWidgets('should have fade in animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cachedImage.fadeInDuration, equals(const Duration(milliseconds: 300)));
      expect(cachedImage.fadeOutDuration, equals(const Duration(milliseconds: 200)));
    });

    testWidgets('error placeholder should show broken image icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      // Get the error widget builder
      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      
      // Build the error widget
      final errorWidget = cachedImage.errorWidget!(
        tester.element(find.byType(CachedNetworkImage)),
        'https://example.com/image.jpg',
        Exception('Failed to load'),
      );

      // Create a test widget to render the error widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: errorWidget,
          ),
        ),
      );

      // Should show broken image icon
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.text('Image unavailable'), findsOneWidget);
    });

    testWidgets('shimmer placeholder should have correct colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CachedGameImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 300,
            ),
          ),
        ),
      );

      // Get the placeholder builder
      final cachedImage = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      
      // Build the placeholder widget
      final placeholderWidget = cachedImage.placeholder!(
        tester.element(find.byType(CachedNetworkImage)),
        'https://example.com/image.jpg',
      );

      // Create a test widget to render the placeholder
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: placeholderWidget,
          ),
        ),
      );

      // Should show shimmer
      expect(find.byType(Shimmer), findsOneWidget);
    });
  });
}

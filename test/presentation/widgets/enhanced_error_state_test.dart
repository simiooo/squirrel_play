import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/presentation/widgets/enhanced_error_state.dart';

void main() {
  group('EnhancedErrorState', () {
    testWidgets('renders database error type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedErrorState.database(
            message: 'Database connection failed',
          ),
        ),
      );

      expect(find.text('Database Error'), findsOneWidget);
      expect(find.text('Database connection failed'), findsOneWidget);
      expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
    });

    testWidgets('renders API error type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedErrorState.api(
            message: 'API connection failed',
          ),
        ),
      );

      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('API connection failed'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('renders missing executable error type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedErrorState.missingExecutable(
            message: 'Executable not found',
          ),
        ),
      );

      expect(find.text('Missing Executable'), findsOneWidget);
      expect(find.text('Executable not found'), findsOneWidget);
      expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    });

    testWidgets('renders generic error type', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedErrorState(
            errorType: ErrorType.generic,
            message: 'Something went wrong',
          ),
        ),
      );

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button pressed',
        (WidgetTester tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedErrorState(
            errorType: ErrorType.generic,
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCalled, true);
    });

    testWidgets('calls onBrowse when browse button pressed',
        (WidgetTester tester) async {
      var browseCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedErrorState.missingExecutable(
            onBrowse: () => browseCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Browse'));
      await tester.pump();

      expect(browseCalled, true);
    });

    testWidgets('calls onRemove when remove button pressed',
        (WidgetTester tester) async {
      var removeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedErrorState.missingExecutable(
            onRemove: () => removeCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Remove'));
      await tester.pump();

      expect(removeCalled, true);
    });

    testWidgets('uses default messages when message is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EnhancedErrorState.database(),
        ),
      );

      expect(
        find.text(
            'Failed to access the game database. Please restart the application.'),
        findsOneWidget,
      );
    });
  });
}

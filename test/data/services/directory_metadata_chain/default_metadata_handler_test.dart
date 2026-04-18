import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/core/utils/filename_cleaner.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/default_metadata_handler.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';

/// A concrete next handler that records invocations for verification.
class RecordingHandler extends GameMetadataHandler {
  int callCount = 0;
  DirectoryContext? lastContext;

  @override
  Future<void> handle(DirectoryContext context) async {
    callCount++;
    lastContext = context;
    await super.handle(context);
  }
}

void main() {
  group('DefaultMetadataHandler', () {
    late DefaultMetadataHandler handler;
    late RecordingHandler nextHandler;

    setUp(() {
      handler = DefaultMetadataHandler();
      nextHandler = RecordingHandler();
      handler.setNext(nextHandler);
    });

    test('sets context.title using FilenameCleaner.cleanForDisplay', () async {
      final context = DirectoryContext(
        executablePath: '/games/mygame/some_game-file.exe',
        fileName: 'some_game-file.exe',
        directoryPath: '/games/mygame',
      );

      await handler.handle(context);

      expect(context.title, equals(FilenameCleaner.cleanForDisplay('some_game-file.exe')));
    });

    test('removes .exe extension from title', () async {
      final context = DirectoryContext(
        executablePath: '/games/mygame/MyAwesomeGame.exe',
        fileName: 'MyAwesomeGame.exe',
        directoryPath: '/games/mygame',
      );

      await handler.handle(context);

      expect(context.title, equals('MyAwesomeGame'));
    });

    test('replaces underscores and hyphens with spaces', () async {
      final context = DirectoryContext(
        executablePath: '/games/mygame/my-awesome_game.exe',
        fileName: 'my-awesome_game.exe',
        directoryPath: '/games/mygame',
      );

      await handler.handle(context);

      expect(context.title, equals('my awesome game'));
    });

    test('does not call next handler', () async {
      final context = DirectoryContext(
        executablePath: '/games/mygame/game.exe',
        fileName: 'game.exe',
        directoryPath: '/games/mygame',
      );

      await handler.handle(context);

      expect(nextHandler.callCount, equals(0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';

void main() {
  group('DirectoryContext', () {
    test('should construct with required fields and null mutable fields', () {
      final context = DirectoryContext(
        executablePath: '/games/mygame/game.exe',
        fileName: 'game.exe',
        directoryPath: '/games/mygame',
      );

      expect(context.executablePath, equals('/games/mygame/game.exe'));
      expect(context.fileName, equals('game.exe'));
      expect(context.directoryPath, equals('/games/mygame'));
      expect(context.title, isNull);
      expect(context.steamAppId, isNull);
    });

    test('should allow setting title', () {
      final context = DirectoryContext(
        executablePath: '/games/mygame/game.exe',
        fileName: 'game.exe',
        directoryPath: '/games/mygame',
      );

      context.title = 'My Game';

      expect(context.title, equals('My Game'));
    });

    test('should allow setting steamAppId', () {
      final context = DirectoryContext(
        executablePath: '/games/mygame/game.exe',
        fileName: 'game.exe',
        directoryPath: '/games/mygame',
      );

      context.steamAppId = '12345';

      expect(context.steamAppId, equals('12345'));
    });

    test('toString should include all fields', () {
      final context = DirectoryContext(
        executablePath: '/games/mygame/game.exe',
        fileName: 'game.exe',
        directoryPath: '/games/mygame',
      );
      context.title = 'My Game';
      context.steamAppId = '12345';

      final str = context.toString();

      expect(str, contains('executablePath: /games/mygame/game.exe'));
      expect(str, contains('fileName: game.exe'));
      expect(str, contains('directoryPath: /games/mygame'));
      expect(str, contains('title: My Game'));
      expect(str, contains('steamAppId: 12345'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/steam_directory_handler.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';

class MockSteamManifestParser extends Mock implements SteamManifestParser {}

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
  group('SteamDirectoryHandler', () {
    late SteamDirectoryHandler handler;
    late MockSteamManifestParser mockParser;
    late RecordingHandler nextHandler;

    setUp(() {
      mockParser = MockSteamManifestParser();
      handler = SteamDirectoryHandler(manifestParser: mockParser);
      nextHandler = RecordingHandler();
      handler.setNext(nextHandler);
    });

    group('when path is in steamapps/common/ and manifest matches', () {
      test('sets title and appId, does NOT call next handler', () async {
        const executablePath = '/home/user/.steam/steamapps/common/MyGame/game.exe';
        const libraryPath = '/home/user/.steam';

        final context = DirectoryContext(
          executablePath: executablePath,
          fileName: 'game.exe',
          directoryPath: '/home/user/.steam/steamapps/common/MyGame',
        );

        final manifests = [
          const SteamManifestData(
            appId: '12345',
            name: 'My Official Game',
            installDir: 'MyGame',
            libraryPath: libraryPath,
            possibleExecutablePaths: [executablePath],
            pathSeparator: '/',
          ),
        ];

        when(() => mockParser.scanLibrary(libraryPath))
            .thenAnswer((_) async => manifests);

        await handler.handle(context);

        expect(context.title, equals('My Official Game'));
        expect(context.steamAppId, equals('12345'));
        expect(nextHandler.callCount, equals(0));
      });
    });

    group('when path is in steamapps/common/ but no manifest matches', () {
      test('calls next handler', () async {
        const executablePath = '/home/user/.steam/steamapps/common/UnknownGame/game.exe';
        const libraryPath = '/home/user/.steam';

        final context = DirectoryContext(
          executablePath: executablePath,
          fileName: 'game.exe',
          directoryPath: '/home/user/.steam/steamapps/common/UnknownGame',
        );

        when(() => mockParser.scanLibrary(libraryPath))
            .thenAnswer((_) async => []);

        await handler.handle(context);

        expect(context.title, isNull);
        expect(context.steamAppId, isNull);
        expect(nextHandler.callCount, equals(1));
        expect(nextHandler.lastContext, same(context));
      });
    });

    group('when path is NOT in steamapps/common/', () {
      test('calls next handler immediately', () async {
        final context = DirectoryContext(
          executablePath: '/home/user/games/standalone/game.exe',
          fileName: 'game.exe',
          directoryPath: '/home/user/games/standalone',
        );

        await handler.handle(context);

        expect(context.title, isNull);
        expect(context.steamAppId, isNull);
        expect(nextHandler.callCount, equals(1));
        expect(nextHandler.lastContext, same(context));
        verifyNever(() => mockParser.scanLibrary(any()));
      });
    });

    group('case insensitive matching', () {
      test('matches SteamApps/Common/ with different casing', () async {
        const executablePath = '/home/user/.steam/SteamApps/Common/MyGame/game.exe';
        const libraryPath = '/home/user/.steam';

        final context = DirectoryContext(
          executablePath: executablePath,
          fileName: 'game.exe',
          directoryPath: '/home/user/.steam/SteamApps/Common/MyGame',
        );

        final manifests = [
          const SteamManifestData(
            appId: '67890',
            name: 'Case Insensitive Game',
            installDir: 'MyGame',
            libraryPath: libraryPath,
            possibleExecutablePaths: [executablePath],
            pathSeparator: '/',
          ),
        ];

        when(() => mockParser.scanLibrary(libraryPath))
            .thenAnswer((_) async => manifests);

        await handler.handle(context);

        expect(context.title, equals('Case Insensitive Game'));
        expect(context.steamAppId, equals('67890'));
        expect(nextHandler.callCount, equals(0));
      });
    });

    group('Windows paths', () {
      test('matches steamapps\\common\\ with backslash separators', () async {
        const executablePath = r'C:\Program Files (x86)\Steam\steamapps\common\MyGame\game.exe';
        const libraryPath = 'c:/program files (x86)/steam';

        final context = DirectoryContext(
          executablePath: executablePath,
          fileName: 'game.exe',
          directoryPath: r'C:\Program Files (x86)\Steam\steamapps\common\MyGame',
        );

        final manifests = [
          const SteamManifestData(
            appId: '11111',
            name: 'Windows Game',
            installDir: 'MyGame',
            libraryPath: libraryPath,
            possibleExecutablePaths: [executablePath],
            pathSeparator: r'\',
          ),
        ];

        when(() => mockParser.scanLibrary(libraryPath))
            .thenAnswer((_) async => manifests);

        await handler.handle(context);

        expect(context.title, equals('Windows Game'));
        expect(context.steamAppId, equals('11111'));
        expect(nextHandler.callCount, equals(0));
      });
    });
  });
}

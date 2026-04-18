import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_metadata_chain.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/steam_directory_handler.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';

class MockSteamManifestParser extends Mock implements SteamManifestParser {}

void main() {
  group('DirectoryMetadataChain', () {
    late MockSteamManifestParser mockParser;

    setUp(() {
      mockParser = MockSteamManifestParser();
    });

    test('build returns a GameMetadataHandler', () {
      final chain = DirectoryMetadataChain.build(manifestParser: mockParser);

      expect(chain, isA<GameMetadataHandler>());
    });

    test('build returns SteamDirectoryHandler as head', () {
      final chain = DirectoryMetadataChain.build(manifestParser: mockParser);

      expect(chain, isA<SteamDirectoryHandler>());
    });

    group('end-to-end: Steam path with matching manifest', () {
      test('returns Steam title and appId', () async {
        const executablePath = '/home/user/.steam/steamapps/common/MyGame/game.exe';
        const libraryPath = '/home/user/.steam';

        final manifests = [
          const SteamManifestData(
            appId: '54321',
            name: 'Steam Official Title',
            installDir: 'MyGame',
            libraryPath: libraryPath,
            possibleExecutablePaths: [executablePath],
            pathSeparator: '/',
          ),
        ];

        when(() => mockParser.scanLibrary(libraryPath))
            .thenAnswer((_) async => manifests);

        final chain = DirectoryMetadataChain.build(manifestParser: mockParser);
        final context = DirectoryContext(
          executablePath: executablePath,
          fileName: 'game.exe',
          directoryPath: '/home/user/.steam/steamapps/common/MyGame',
        );

        await chain.handle(context);

        expect(context.title, equals('Steam Official Title'));
        expect(context.steamAppId, equals('54321'));
      });
    });

    group('end-to-end: non-Steam path', () {
      test('falls back to cleaned filename title', () async {
        final chain = DirectoryMetadataChain.build(manifestParser: mockParser);
        final context = DirectoryContext(
          executablePath: '/home/user/games/standalone/my-awesome_game.exe',
          fileName: 'my-awesome_game.exe',
          directoryPath: '/home/user/games/standalone',
        );

        await chain.handle(context);

        expect(context.title, equals('my awesome game'));
        expect(context.steamAppId, isNull);
        verifyNever(() => mockParser.scanLibrary(any()));
      });
    });

    group('end-to-end: Steam path with no matching manifest', () {
      test('falls back to cleaned filename title', () async {
        const executablePath = '/home/user/.steam/steamapps/common/UnknownGame/game.exe';
        const libraryPath = '/home/user/.steam';

        when(() => mockParser.scanLibrary(libraryPath))
            .thenAnswer((_) async => []);

        final chain = DirectoryMetadataChain.build(manifestParser: mockParser);
        final context = DirectoryContext(
          executablePath: executablePath,
          fileName: 'game.exe',
          directoryPath: '/home/user/.steam/steamapps/common/UnknownGame',
        );

        await chain.handle(context);

        expect(context.title, equals('game'));
        expect(context.steamAppId, isNull);
        verify(() => mockParser.scanLibrary(libraryPath)).called(1);
      });
    });
  });
}

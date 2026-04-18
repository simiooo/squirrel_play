import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/metadata/steam_local_source.dart';
import 'package:squirrel_play/data/services/steam_manifest_parser.dart';
import 'package:squirrel_play/domain/entities/game.dart';

class MockSteamManifestParser extends Mock implements SteamManifestParser {}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
  });

  group('SteamLocalSource', () {
    late SteamLocalSource source;
    late MockSteamManifestParser mockManifestParser;

    setUp(() {
      mockManifestParser = MockSteamManifestParser();
      source = SteamLocalSource(
        manifestParser: mockManifestParser,
      );
    });

    group('sourceType', () {
      test('should return steamLocal', () {
        expect(source.sourceType, equals(MetadataSourceType.steamLocal));
      });
    });

    group('displayName', () {
      test('should return Steam Local', () {
        expect(source.displayName, equals('Steam Local'));
      });
    });

    group('canProvide', () {
      test('should return true for Steam path games', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.canProvide(game);

        expect(result, isTrue);
      });

      test('should return true when externalId has steam: prefix', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/some/other/path/game.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.canProvide(game, externalId: 'steam:730');

        expect(result, isTrue);
      });

      test('should return false for non-Steam path games without steam: externalId', () async {
        final game = Game(
          id: 'game1',
          title: 'Non-Steam Game',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.canProvide(game);

        expect(result, isFalse);
      });

      test('should return false when externalId is rawg: prefix', () async {
        final game = Game(
          id: 'game1',
          title: 'RAWG Game',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.canProvide(game, externalId: 'rawg:12345');

        expect(result, isFalse);
      });
    });

    group('fetch', () {
      test('should return null for non-Steam games', () async {
        final game = Game(
          id: 'game1',
          title: 'Non-Steam Game',
          executablePath: '/home/user/games/game.exe',
          addedDate: DateTime.now(),
        );

        final result = await source.fetch(game);

        expect(result, isNull);
      });

      test('should return metadata with CDN URLs for Steam games', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );
        const externalId = 'steam:730';

        final manifests = [
          const SteamManifestData(
            appId: '730',
            name: 'Steam Game',
            installDir: 'Game',
            libraryPath: '/home/user/.steam',
            pathSeparator: '/',
          ),
        ];

        when(() => mockManifestParser.scanLibrary('/home/user/.steam'))
            .thenAnswer((_) async => manifests);

        final result = await source.fetch(game, externalId: externalId);

        expect(result, isNotNull);
        expect(result!.gameId, equals('game1'));
        expect(result.externalId, equals('steam:730'));
        expect(result.coverImageUrl, contains('cdn.akamai.steamstatic.com'));
        expect(result.coverImageUrl, contains('730'));
        expect(result.heroImageUrl, contains('cdn.akamai.steamstatic.com'));
        expect(result.heroImageUrl, contains('730'));
        expect(result.description, isNull);
        expect(result.genres, isEmpty);
        expect(result.screenshots, isEmpty);
        expect(result.lastFetched, isNotNull);
      });

      test('should return metadata from externalId when manifest not found', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/UnknownGame/game.exe',
          addedDate: DateTime.now(),
        );

        when(() => mockManifestParser.scanLibrary('/home/user/.steam'))
            .thenAnswer((_) async => []);

        // When externalId is provided, it should be used even if manifest is not found
        final result = await source.fetch(game, externalId: 'steam:999999');

        // Should return metadata with CDN URLs constructed from externalId
        expect(result, isNotNull);
        expect(result!.externalId, equals('steam:999999'));
        expect(result.coverImageUrl, contains('999999'));
        expect(result.heroImageUrl, contains('999999'));
      });

      test('should return null when manifest not found and no externalId provided', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/UnknownGame/game.exe',
          addedDate: DateTime.now(),
        );

        when(() => mockManifestParser.scanLibrary('/home/user/.steam'))
            .thenAnswer((_) async => []);

        // Without externalId, should return null when manifest not found
        final result = await source.fetch(game);

        expect(result, isNull);
      });

      test('should handle Flatpak Steam paths', () async {
        final game = Game(
          id: 'game1',
          title: 'Flatpak Steam Game',
          executablePath:
              '/home/user/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );
        const externalId = 'steam:440';

        final manifests = [
          const SteamManifestData(
            appId: '440',
            name: 'Team Fortress 2',
            installDir: 'Game',
            libraryPath: '/home/user/.var/app/com.valvesoftware.Steam/.local/share/Steam',
            pathSeparator: '/',
          ),
        ];

        when(() => mockManifestParser.scanLibrary(
                '/home/user/.var/app/com.valvesoftware.Steam/.local/share/Steam'))
            .thenAnswer((_) async => manifests);

        final result = await source.fetch(game, externalId: externalId);

        expect(result, isNotNull);
        expect(result!.externalId, equals('steam:440'));
      });
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/metadata/steam_store_source.dart';
import 'package:squirrel_play/domain/entities/game.dart';

class MockDio extends Mock implements Dio {}

class FakeGame extends Fake implements Game {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeGame());
    registerFallbackValue(RequestOptions(path: '/'));
  });

  group('SteamStoreSource', () {
    late SteamStoreSource source;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      source = SteamStoreSource(
        dio: mockDio,
      );
    });

    group('sourceType', () {
      test('should return steamStore', () {
        expect(source.sourceType, equals(MetadataSourceType.steamStore));
      });
    });

    group('displayName', () {
      test('should return Steam Store', () {
        expect(source.displayName, equals('Steam Store'));
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

      test('should fetch metadata from Steam Store API', () async {
        final game = Game(
          id: 'game1',
          title: 'Counter-Strike 2',
          executablePath: '/home/user/.steam/steamapps/common/Counter-Strike 2/game.exe',
          addedDate: DateTime.now(),
        );
        const externalId = 'steam:730';

        final responseData = {
          '730': {
            'success': true,
            'data': {
              'name': 'Counter-Strike 2',
              'short_description': 'A tactical first-person shooter',
              'header_image': 'https://cdn.akamai.steamstatic.com/steam/apps/730/header.jpg',
              'background_raw': 'https://cdn.akamai.steamstatic.com/steam/apps/730/page_bg_raw.jpg',
              'screenshots': [
                {'path_full': 'https://cdn.akamai.steamstatic.com/steam/apps/730/ss_123.jpg'},
              ],
              'developers': ['Valve'],
              'publishers': ['Valve'],
              'genres': [
                {'description': 'Action'},
                {'description': 'FPS'},
              ],
              'release_date': {
                'date': '22 Aug, 2012',
              },
            },
          },
        };

        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: 'appdetails'),
            ));

        final result = await source.fetch(game, externalId: externalId);

        expect(result, isNotNull);
        expect(result!.gameId, equals('game1'));
        expect(result.externalId, equals('steam:730'));
        expect(result.title, equals('Counter-Strike 2'));
        expect(result.description, equals('A tactical first-person shooter'));
        expect(result.coverImageUrl, contains('730'));
        expect(result.heroImageUrl, contains('730'));
        expect(result.developer, equals('Valve'));
        expect(result.publisher, equals('Valve'));
        expect(result.genres, contains('Action'));
        expect(result.genres, contains('FPS'));
        expect(result.screenshots, isNotEmpty);
        expect(result.releaseDate, isNotNull);
      });

      test('should return null when API returns unsuccessful', () async {
        final game = Game(
          id: 'game1',
          title: 'Unknown Game',
          executablePath: '/home/user/.steam/steamapps/common/Unknown/game.exe',
          addedDate: DateTime.now(),
        );
        const externalId = 'steam:999999';

        final responseData = {
          '999999': {
            'success': false,
            'data': null,
          },
        };

        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: 'appdetails'),
            ));

        final result = await source.fetch(game, externalId: externalId);

        expect(result, isNull);
      });

      test('should return null when API returns null data', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );
        const externalId = 'steam:12345';

        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: null,
              statusCode: 200,
              requestOptions: RequestOptions(path: 'appdetails'),
            ));

        final result = await source.fetch(game, externalId: externalId);

        expect(result, isNull);
      });

      test('should handle DioException gracefully', () async {
        final game = Game(
          id: 'game1',
          title: 'Steam Game',
          executablePath: '/home/user/.steam/steamapps/common/Game/game.exe',
          addedDate: DateTime.now(),
        );
        const externalId = 'steam:12345';

        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
              requestOptions: RequestOptions(path: 'appdetails'),
              error: 'Network error',
            ));

        final result = await source.fetch(game, externalId: externalId);

        expect(result, isNull);
      });

      test('should use background as fallback when background_raw is missing', () async {
        final game = Game(
          id: 'game1',
          title: 'Test Game',
          executablePath: '/home/user/.steam/steamapps/common/TestGame/game.exe',
          addedDate: DateTime.now(),
        );
        const externalId = 'steam:12345';

        final responseData = {
          '12345': {
            'success': true,
            'data': {
              'name': 'Test Game',
              'short_description': 'A test game',
              'header_image': 'https://cdn.akamai.steamstatic.com/steam/apps/12345/header.jpg',
              'background': 'https://cdn.akamai.steamstatic.com/steam/apps/12345/page_bg.jpg',
              'screenshots': [],
              'developers': ['Test Dev'],
              'publishers': ['Test Pub'],
              'genres': [],
              'release_date': {
                'date': '1 Jan, 2020',
              },
            },
          },
        };

        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(path: 'appdetails'),
            ));

        final result = await source.fetch(game, externalId: externalId);

        expect(result, isNotNull);
        expect(result!.heroImageUrl, equals('https://cdn.akamai.steamstatic.com/steam/apps/12345/page_bg.jpg'));
      });
    });
  });
}

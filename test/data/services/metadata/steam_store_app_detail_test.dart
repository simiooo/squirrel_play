import 'package:flutter_test/flutter_test.dart';
import 'package:squirrel_play/data/services/metadata/models/steam_store_app_detail.dart';

void main() {
  group('SteamStoreAppDetail', () {
    test('should parse successful response', () {
      final json = {
        'success': true,
        'data': {
          'name': 'Test Game',
          'short_description': 'A test game description',
          'header_image': 'https://example.com/header.jpg',
          'background_raw': 'https://example.com/background.jpg',
          'screenshots': [
            {'path_full': 'https://example.com/screenshot1.jpg'},
            {'path_full': 'https://example.com/screenshot2.jpg'},
          ],
          'developers': ['Test Developer'],
          'publishers': ['Test Publisher'],
          'genres': [
            {'description': 'Action'},
            {'description': 'Adventure'},
          ],
          'release_date': {
            'date': '10 Nov, 2020',
          },
        },
      };

      final detail = SteamStoreAppDetail.fromJson(json);

      expect(detail.success, isTrue);
      expect(detail.data, isNotNull);
      expect(detail.data!.name, equals('Test Game'));
      expect(detail.data!.shortDescription, equals('A test game description'));
      expect(detail.data!.headerImage, equals('https://example.com/header.jpg'));
      expect(detail.data!.backgroundRaw, equals('https://example.com/background.jpg'));
      expect(detail.data!.screenshots, hasLength(2));
      expect(detail.data!.screenshots![0].pathFull, equals('https://example.com/screenshot1.jpg'));
      expect(detail.data!.developers, equals(['Test Developer']));
      expect(detail.data!.publishers, equals(['Test Publisher']));
      expect(detail.data!.genres, hasLength(2));
      expect(detail.data!.genres![0].description, equals('Action'));
      expect(detail.data!.releaseDate!.date, equals('10 Nov, 2020'));
    });

    test('should parse unsuccessful response', () {
      final json = {
        'success': false,
        'data': null,
      };

      final detail = SteamStoreAppDetail.fromJson(json);

      expect(detail.success, isFalse);
      expect(detail.data, isNull);
    });

    test('should serialize to JSON', () {
      final detail = const SteamStoreAppDetail(
        success: true,
        data: SteamStoreAppData(
          name: 'Test Game',
          shortDescription: 'Description',
          headerImage: 'https://example.com/header.jpg',
        ),
      );

      final json = detail.toJson();

      expect(json['success'], isTrue);
      final dataJson = json['data'] as Map<String, dynamic>;
      expect(dataJson['name'], equals('Test Game'));
      expect(dataJson['short_description'], equals('Description'));
      expect(dataJson['header_image'], equals('https://example.com/header.jpg'));
    });
  });

  group('SteamStoreAppData', () {
    test('should handle missing optional fields', () {
      final json = {
        'name': 'Minimal Game',
        'short_description': 'Minimal description',
        'header_image': 'https://example.com/header.jpg',
      };

      final data = SteamStoreAppData.fromJson(json);

      expect(data.name, equals('Minimal Game'));
      expect(data.shortDescription, equals('Minimal description'));
      expect(data.headerImage, equals('https://example.com/header.jpg'));
      expect(data.backgroundRaw, isNull);
      expect(data.background, isNull);
      expect(data.screenshots, isNull);
      expect(data.developers, isNull);
      expect(data.publishers, isNull);
      expect(data.genres, isNull);
      expect(data.releaseDate, isNull);
    });

    test('should use background as fallback when background_raw is missing', () {
      final json = {
        'name': 'Test Game',
        'short_description': 'Description',
        'header_image': 'https://example.com/header.jpg',
        'background': 'https://example.com/background.jpg',
      };

      final data = SteamStoreAppData.fromJson(json);

      expect(data.backgroundRaw, isNull);
      expect(data.background, equals('https://example.com/background.jpg'));
    });
  });

  group('SteamStoreScreenshot', () {
    test('should parse screenshot data', () {
      final json = {
        'path_full': 'https://example.com/screenshot.jpg',
      };

      final screenshot = SteamStoreScreenshot.fromJson(json);

      expect(screenshot.pathFull, equals('https://example.com/screenshot.jpg'));
    });

    test('should serialize to JSON', () {
      final screenshot = const SteamStoreScreenshot(pathFull: 'https://example.com/screenshot.jpg');

      final json = screenshot.toJson();

      expect(json['path_full'], equals('https://example.com/screenshot.jpg'));
    });
  });

  group('SteamStoreGenre', () {
    test('should parse genre data', () {
      final json = {
        'description': 'Action',
      };

      final genre = SteamStoreGenre.fromJson(json);

      expect(genre.description, equals('Action'));
    });

    test('should serialize to JSON', () {
      final genre = const SteamStoreGenre(description: 'RPG');

      final json = genre.toJson();

      expect(json['description'], equals('RPG'));
    });
  });

  group('SteamStoreReleaseDate', () {
    test('should parse release date', () {
      final json = {
        'date': '10 Nov, 2020',
      };

      final releaseDate = SteamStoreReleaseDate.fromJson(json);

      expect(releaseDate.date, equals('10 Nov, 2020'));
    });

    test('should serialize to JSON', () {
      final releaseDate = const SteamStoreReleaseDate(date: '1 Jan, 2021');

      final json = releaseDate.toJson();

      expect(json['date'], equals('1 Jan, 2021'));
    });
  });
}

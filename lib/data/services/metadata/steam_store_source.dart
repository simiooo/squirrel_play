import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source.dart';
import 'package:squirrel_play/data/services/metadata/metadata_source_type.dart';
import 'package:squirrel_play/data/services/metadata/models/steam_store_app_detail.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/entities/game_metadata.dart';

/// Metadata source for Steam Store API.
///
/// Provides rich metadata including descriptions, screenshots,
/// developers, publishers, and genres from the Steam Store Web API.
class SteamStoreSource implements MetadataSource {
  final Dio _dio;

  SteamStoreSource({
    required Dio dio,
  }) : _dio = dio;

  @override
  MetadataSourceType get sourceType => MetadataSourceType.steamStore;

  @override
  String get displayName => 'Steam Store';

  @override
  Future<bool> canProvide(Game game, {String? externalId}) async {
    // Check if game has existing metadata with steam: prefix
    if (externalId != null && externalId.startsWith('steam:')) {
      return true;
    }
    // Fall back to checking the executable path pattern
    return _isSteamGame(game);
  }

  /// Determines if a game is a Steam game based on executable path.
  bool _isSteamGame(Game game) {
    final normalizedPath = game.executablePath.replaceAll('\\', '/');
    return normalizedPath.contains('/steamapps/common/');
  }

  @override
  Future<GameMetadata?> fetch(Game game, {String? externalId}) async {
    final appId = _extractAppId(game, externalId: externalId);
    if (appId == null) {
      developer.log(
        'SteamStoreSource: Could not extract appId for ${game.title}',
        name: 'SteamStoreSource',
      );
      return null;
    }

    try {
      // Apply rate limiting (200ms delay)
      await Future.delayed(const Duration(milliseconds: 200));

      final response = await _dio.get<Map<String, dynamic>>(
        'appdetails',
        queryParameters: {'appids': appId},
      );

      final data = response.data;
      if (data == null) {
        return null;
      }

      // The response uses the app ID as a dynamic key
      final appData = data[appId];
      if (appData == null) {
        return null;
      }

      final detail = SteamStoreAppDetail.fromJson(
        appData as Map<String, dynamic>,
      );

      if (!detail.success || detail.data == null) {
        developer.log(
          'SteamStoreSource: API returned unsuccessful for appId $appId',
          name: 'SteamStoreSource',
        );
        return null;
      }

      final storeData = detail.data!;

      developer.log(
        'SteamStoreSource: Fetched metadata for ${game.title} (appId: $appId)',
        name: 'SteamStoreSource',
      );

      return _convertToGameMetadata(
        gameId: game.id,
        appId: appId,
        data: storeData,
      );
    } on DioException catch (e) {
      developer.log(
        'SteamStoreSource: DioException for ${game.title}: ${e.message}',
        name: 'SteamStoreSource',
      );
      return null;
    } catch (e) {
      developer.log(
        'SteamStoreSource: Error fetching metadata for ${game.title}: $e',
        name: 'SteamStoreSource',
      );
      return null;
    }
  }

  /// Extracts the Steam app ID from the game.
  ///
  /// First checks if the game has existing metadata with steam: prefix,
  /// then falls back to extracting from the executable path.
  String? _extractAppId(Game game, {String? externalId}) {
    // First check if externalId has steam: prefix
    if (externalId != null && externalId.startsWith('steam:')) {
      return externalId.substring('steam:'.length);
    }

    // Try to extract from executable path
    final path = game.executablePath.replaceAll('\\', '/');

    // Parse the path to find the steamapps directory
    final steamappsIndex = path.indexOf('/steamapps/common/');
    if (steamappsIndex == -1) {
      return null;
    }

    final libraryPath = path.substring(0, steamappsIndex);

    // Try to find the appmanifest file by looking at the install directory
    final pathAfterCommon = path.substring(steamappsIndex + '/steamapps/common/'.length);
    final installDir = pathAfterCommon.split('/').first;

    // The appId is in the manifest filename: appmanifest_{appId}.acf
    // We need to find which appId corresponds to this installDir
    // Try to extract from the path pattern if possible

    // Look for appId pattern in any parent directory name
    final appIdPattern = RegExp(r'appmanifest_(\d+)\.acf');
    final appIdMatch = appIdPattern.firstMatch(path);
    if (appIdMatch != null) {
      return appIdMatch.group(1);
    }

    // Try to find the manifest file in the steamapps directory
    final manifestFile = File('$libraryPath/steamapps/appmanifest_$installDir.acf');
    if (manifestFile.existsSync()) {
      // Extract appId from filename
      final fileName = manifestFile.path.split('/').last;
      final match = appIdPattern.firstMatch(fileName);
      if (match != null) {
        return match.group(1);
      }
    }

    // If we can't extract from path or file, return null
    // The MetadataAggregator should handle this by using SteamLocalSource first
    return null;
  }

  /// Converts Steam Store API data to GameMetadata.
  GameMetadata _convertToGameMetadata({
    required String gameId,
    required String appId,
    required SteamStoreAppData data,
  }) {
    // Parse release date
    DateTime? releaseDate;
    if (data.releaseDate?.date != null && data.releaseDate!.date.isNotEmpty) {
      // Try various date formats
      releaseDate = _parseReleaseDate(data.releaseDate!.date);
    }

    // Build description (plain short description, no name prefix)
    final description = data.shortDescription;

    // Extract screenshots
    final screenshots = data.screenshots
            ?.map((s) => s.pathFull)
            .where((url) => url.isNotEmpty)
            .toList() ??
        [];

    // Extract genres
    final genres = data.genres
            ?.map((g) => g.description)
            .where((name) => name.isNotEmpty)
            .toList() ??
        [];

    // Determine hero image URL (prefer background_raw, fallback to background)
    final heroImageUrl = data.backgroundRaw ?? data.background;

    return GameMetadata(
      gameId: gameId,
      externalId: 'steam:$appId',
      title: data.name,
      description: description,
      coverImageUrl: data.headerImage,
      heroImageUrl: heroImageUrl,
      genres: genres,
      screenshots: screenshots,
      releaseDate: releaseDate,
      developer: data.developers?.firstOrNull,
      publisher: data.publishers?.firstOrNull,
      lastFetched: DateTime.now(),
    );
  }

  /// Parses release date from various formats.
  DateTime? _parseReleaseDate(String dateStr) {
    // Try ISO format first
    final isoDate = DateTime.tryParse(dateStr);
    if (isoDate != null) {
      return isoDate;
    }

    // Manual parsing for common Steam formats
    final monthMap = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
      'january': 1, 'february': 2, 'march': 3, 'april': 4, 'june': 6,
      'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11,
      'december': 12,
    };

    // Try to extract date components
    final lowerDate = dateStr.toLowerCase();

    // Pattern: "10 Nov, 2020" or "Nov 10, 2020"
    final pattern1 = RegExp(r'(\d{1,2})\s+([a-z]+),?\s+(\d{4})');
    final pattern2 = RegExp(r'([a-z]+)\s+(\d{1,2}),?\s+(\d{4})');

    var match = pattern1.firstMatch(lowerDate);
    if (match != null) {
      final day = int.tryParse(match.group(1)!);
      final month = monthMap[match.group(2)];
      final year = int.tryParse(match.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    match = pattern2.firstMatch(lowerDate);
    if (match != null) {
      final month = monthMap[match.group(1)];
      final day = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }
}

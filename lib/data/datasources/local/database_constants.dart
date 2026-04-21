/// Database constants for the Squirrel Play application.
///
/// Contains table names, column names, and SQL statements for database schema.
class DatabaseConstants {
  DatabaseConstants._();

  // Database Info
  static const String databaseName = 'squirrel_play.db';
  static const int databaseVersion = 5;

  // Table Names
  static const String tableGames = 'games';
  static const String tableGameMetadata = 'game_metadata';
  static const String tableGameGenres = 'game_genres';
  static const String tableGameScreenshots = 'game_screenshots';
  static const String tableScanDirectories = 'scan_directories';

  // Column Names - Games Table
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colExecutablePath = 'executable_path';
  static const String colDirectoryId = 'directory_id';
  static const String colAddedDate = 'added_date';
  static const String colLastPlayedDate = 'last_played_date';
  static const String colIsFavorite = 'is_favorite';
  static const String colPlayCount = 'play_count';
  static const String colLaunchArguments = 'launch_arguments';
  static const String colPlatform = 'platform';
  static const String colPlatformGameId = 'platform_game_id';

  // Column Names - Game Metadata Table
  static const String colGameId = 'game_id';
  static const String colExternalId = 'external_id';
  static const String colMetadataTitle = 'title';
  static const String colDescription = 'description';
  static const String colCoverImageUrl = 'cover_image_url';
  static const String colCardImageUrl = 'card_image_url';
  static const String colHeroImageUrl = 'hero_image_url';
  static const String colLogoImageUrl = 'logo_image_url';
  static const String colReleaseDate = 'release_date';
  static const String colRating = 'rating';
  static const String colDeveloper = 'developer';
  static const String colPublisher = 'publisher';
  static const String colLastFetched = 'last_fetched';

  // Column Names - Game Genres Table
  static const String colGenre = 'genre';

  // Column Names - Game Screenshots Table
  static const String colScreenshotUrl = 'screenshot_url';
  static const String colSortOrder = 'sort_order';

  // Column Names - Scan Directories Table
  static const String colPath = 'path';
  static const String colLastScannedDate = 'last_scanned_date';

  // SQL Create Statements
  static const String createGamesTable = '''
    CREATE TABLE $tableGames (
      $colId TEXT PRIMARY KEY,
      $colTitle TEXT NOT NULL,
      $colExecutablePath TEXT NOT NULL UNIQUE,
      $colDirectoryId TEXT,
      $colAddedDate INTEGER NOT NULL,
      $colLastPlayedDate INTEGER,
      $colIsFavorite INTEGER NOT NULL DEFAULT 0,
      $colPlayCount INTEGER NOT NULL DEFAULT 0,
      $colLaunchArguments TEXT,
      $colPlatform TEXT,
      $colPlatformGameId TEXT,
      FOREIGN KEY ($colDirectoryId) REFERENCES $tableScanDirectories($colId) ON DELETE SET NULL
    )
  ''';

  static const String createGameMetadataTable = '''
    CREATE TABLE $tableGameMetadata (
      $colGameId TEXT PRIMARY KEY,
      $colExternalId TEXT,
      $colMetadataTitle TEXT,
      $colDescription TEXT,
      $colCoverImageUrl TEXT,
      $colCardImageUrl TEXT,
      $colHeroImageUrl TEXT,
      $colLogoImageUrl TEXT,
      $colReleaseDate INTEGER,
      $colRating REAL,
      $colDeveloper TEXT,
      $colPublisher TEXT,
      $colLastFetched INTEGER NOT NULL,
      FOREIGN KEY ($colGameId) REFERENCES $tableGames($colId) ON DELETE CASCADE
    )
  ''';

  static const String createGameGenresTable = '''
    CREATE TABLE $tableGameGenres (
      $colGameId TEXT REFERENCES $tableGames($colId) ON DELETE CASCADE,
      $colGenre TEXT,
      PRIMARY KEY ($colGameId, $colGenre)
    )
  ''';

  static const String createGameScreenshotsTable = '''
    CREATE TABLE $tableGameScreenshots (
      $colGameId TEXT REFERENCES $tableGames($colId) ON DELETE CASCADE,
      $colScreenshotUrl TEXT,
      $colSortOrder INTEGER,
      PRIMARY KEY ($colGameId, $colScreenshotUrl)
    )
  ''';

  static const String createScanDirectoriesTable = '''
    CREATE TABLE $tableScanDirectories (
      $colId TEXT PRIMARY KEY,
      $colPath TEXT NOT NULL UNIQUE,
      $colAddedDate INTEGER NOT NULL,
      $colLastScannedDate INTEGER
    )
  ''';

  // Index for faster queries
  static const String createGamesDirectoryIdIndex = '''
    CREATE INDEX idx_games_directory_id ON $tableGames($colDirectoryId)
  ''';

  static const String createGamesExecutablePathIndex = '''
    CREATE INDEX idx_games_executable_path ON $tableGames($colExecutablePath)
  ''';
}

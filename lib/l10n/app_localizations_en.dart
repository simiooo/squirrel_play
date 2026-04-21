// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Squirrel Play';

  @override
  String get topBarAddGame => 'Add Game';

  @override
  String get topBarGameLibrary => 'Game Library';

  @override
  String get topBarRescan => 'Rescan';

  @override
  String get topBarSettings => 'Settings';

  @override
  String get topBarHome => 'Home';

  @override
  String get pageHome => 'Home';

  @override
  String get pageLibrary => 'Library';

  @override
  String get pageSettings => 'Settings';

  @override
  String get homeEmptyState => 'No games yet. Add a game to get started.';

  @override
  String get libraryEmptyState => 'Your game library is empty.';

  @override
  String timeFormat(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get focusAddGameHint => 'Add a new game to your library';

  @override
  String get focusGameLibraryHint => 'View all games in your library';

  @override
  String get focusRescanHint => 'Rescan directories for new games';

  @override
  String get topBarRefresh => 'Refresh';

  @override
  String get topBarScanning => 'Scanning...';

  @override
  String topBarScanNewGames(int count) {
    return '$count new games found';
  }

  @override
  String get topBarScanNoNewGames => 'No new games found';

  @override
  String get topBarScanNoDirectories => 'No directories configured';

  @override
  String get topBarScanError => 'Scan error';

  @override
  String get topBarRefreshHint => 'Refresh game library';

  @override
  String get focusSettingsHint => 'Open application settings';

  @override
  String get focusHomeHint => 'Return to home page';

  @override
  String get dialogAddGameTitle => 'Add Game';

  @override
  String get dialogAddGameManualTab => 'Manual Add';

  @override
  String get dialogAddGameScanTab => 'Scan Directory';

  @override
  String get dialogAddGameSteamTab => 'Steam Games';

  @override
  String get dialogClose => 'Close';

  @override
  String get buttonBack => 'Back';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonConfirm => 'Confirm';

  @override
  String get focusCardHint => 'Game card - press A to select';

  @override
  String get snackbarRescanPlaceholder => 'Rescan feature coming soon';

  @override
  String get dialogPlaceholderText =>
      'This feature will be available in a future update';

  @override
  String get emptyStateAddGame => 'Add your first game';

  @override
  String get emptyStateSubtitle => 'Add your first game to get started';

  @override
  String get buttonScanDirectory => 'Scan Directory';

  @override
  String get noDescriptionAvailable => 'No description available';

  @override
  String get errorLoadGames => 'Failed to load games';

  @override
  String get homeRowRecentlyAdded => 'Recently Added';

  @override
  String get homeRowAllGames => 'All Games';

  @override
  String get homeRowFavorites => 'Favorites';

  @override
  String get homeRowRecentlyPlayed => 'Recently Played';

  @override
  String get homeRowFeatured => 'Featured';

  @override
  String get viewAllGames => 'View All';

  @override
  String launchingGame(String gameName) {
    return 'Launching $gameName...';
  }

  @override
  String get launchCancelHint => 'Press B to cancel';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChinese => 'Chinese (Simplified)';

  @override
  String get settingsApiKey => 'API Key';

  @override
  String get settingsApiKeyLabel => 'RAWG API Key';

  @override
  String get settingsApiKeyPlaceholder => 'Enter your RAWG API key';

  @override
  String get settingsApiKeyHelp => 'Get your free API key from rawg.io';

  @override
  String get settingsApiKeyDegraded => 'Degraded Mode';

  @override
  String get settingsApiKeyConnected => 'API Connected';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsSoundVolume => 'Master Volume';

  @override
  String get settingsSoundMute => 'Mute';

  @override
  String get settingsSoundTest => 'Test Sound';

  @override
  String get settingsSoundVolumeHint =>
      'Volume slider - use left and right to adjust';

  @override
  String get settingsSoundMuteHint =>
      'Mute toggle - press to toggle mute on or off';

  @override
  String get settingsLanguageEnglishLabel => 'English language option';

  @override
  String get settingsLanguageChineseLabel => 'Chinese language option';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutCredits => 'Powered by RAWG API';

  @override
  String get errorGenericTitle => 'Something Went Wrong';

  @override
  String get errorGenericMessage =>
      'An unexpected error occurred. Please try again.';

  @override
  String get errorDatabaseTitle => 'Database Error';

  @override
  String get errorDatabaseMessage =>
      'Failed to access the game database. Please restart the application.';

  @override
  String get errorApiTitle => 'Connection Error';

  @override
  String get errorApiMessage =>
      'Could not connect to game database. You can still play your games.';

  @override
  String get errorFileNotFoundTitle => 'Game Not Found';

  @override
  String get errorFileNotFoundMessage =>
      'The game executable could not be found. It may have been moved or deleted.';

  @override
  String get errorMissingExecutableTitle => 'Missing Executable';

  @override
  String get errorMissingExecutableMessage =>
      'The game executable is missing. Please browse for a new location.';

  @override
  String get emptyStateNoGamesTitle => 'No Games Yet';

  @override
  String get emptyStateNoGamesMessage => 'Add your first game to get started';

  @override
  String get emptyStateNoSearchResultsTitle => 'No Results';

  @override
  String get emptyStateNoSearchResultsMessage => 'Try a different search term';

  @override
  String get emptyStateApiUnreachableTitle => 'Can\'t Connect';

  @override
  String get emptyStateApiUnreachableMessage =>
      'Game info unavailable. You can still play your games.';

  @override
  String get favoritesAdded => 'Added to favorites';

  @override
  String get favoritesRemoved => 'Removed from favorites';

  @override
  String get favoritesEmptyState => 'No favorite games yet';

  @override
  String gameInfoPlayCount(int count) {
    return 'Played $count times';
  }

  @override
  String get gameInfoPlayCountNever => 'Never played';

  @override
  String gameInfoLastPlayed(String timeAgo) {
    return 'Last played: $timeAgo';
  }

  @override
  String get gameInfoLastPlayedNever => 'Never played';

  @override
  String get gameInfoFavoriteButton => 'Add to Favorites';

  @override
  String get gameInfoUnfavoriteButton => 'Remove from Favorites';

  @override
  String get gameInfoLaunchButton => 'Launch Game';

  @override
  String get gameInfoStopButton => 'Stop';

  @override
  String get gameInfoSettingsButton => 'Settings';

  @override
  String get gameInfoDeleteButton => 'Delete';

  @override
  String get gameInfoRefreshMetadataButton => 'Refresh Metadata';

  @override
  String get errorApiNotConfigured =>
      'RAWG API key is not configured. Please go to Settings to add your API key.';

  @override
  String get dialogEditGameTitle => 'Edit Game';

  @override
  String get dialogEditGameTitleLabel => 'Title';

  @override
  String get dialogEditGameTitleHint => 'Enter game title';

  @override
  String get dialogEditGameExecutableLabel => 'Executable Path';

  @override
  String get dialogEditGameExecutableHint => 'Path to game executable';

  @override
  String get dialogEditGameBrowse => 'Browse';

  @override
  String get dialogEditGameArgumentsLabel => 'Launch Arguments';

  @override
  String get dialogEditGameArgumentsHint => 'e.g. -windowed --fullscreen';

  @override
  String get dialogDeleteGameTitle => 'Delete Game?';

  @override
  String dialogDeleteGameMessage(String gameName) {
    return 'Are you sure you want to remove \"$gameName\" from your library?';
  }

  @override
  String get dialogDeleteGameConfirm => 'Delete';

  @override
  String get gamepadAButton => 'A: Select';

  @override
  String get gamepadBButton => 'B: Back';

  @override
  String get gamepadXButton => 'X: Details';

  @override
  String get gamepadYButton => 'Y: Favorite';

  @override
  String get gamepadStartButton => 'Start: Menu';

  @override
  String get gamepadBackButton => 'Back: Home';

  @override
  String get gamepadNavSelect => 'Select';

  @override
  String get gamepadNavBack => 'Back';

  @override
  String get gamepadNavDetails => 'Details';

  @override
  String get gamepadNavFavorite => 'Favorite';

  @override
  String get gamepadNavMenu => 'Menu';

  @override
  String get gamepadNavHome => 'Home';

  @override
  String get gamepadNavConfirm => 'Confirm';

  @override
  String get gamepadNavCancel => 'Cancel';

  @override
  String get gamepadNavPlay => 'Play';

  @override
  String get gamepadNavToggle => 'Toggle';

  @override
  String get gamepadNavScreenshots => 'Screenshots';

  @override
  String get settingsGamepad => 'Gamepad';

  @override
  String get settingsGamepadConnected => 'Gamepad: Connected';

  @override
  String get settingsGamepadDisconnected => 'Gamepad: Not connected';

  @override
  String get settingsGamepadTest => 'Test Gamepad';

  @override
  String get gamepadTestTitle => 'Gamepad Test';

  @override
  String get gamepadTestConnected => 'Connected';

  @override
  String get gamepadTestDisconnected => 'No gamepad detected';

  @override
  String get gamepadTestConnectHelp => 'Connect a gamepad and press any button';

  @override
  String get gamepadTestInputLog => 'Input Log';

  @override
  String get gamepadTestNoGamepad => 'No gamepad detected';

  @override
  String get gamepadTestConnectInstructions =>
      'Connect a gamepad and press any button to start testing';

  @override
  String get timeAgoJustNow => 'just now';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours hours ago';
  }

  @override
  String timeAgoDays(int days) {
    return '$days days ago';
  }

  @override
  String timeAgoWeeks(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String timeAgoMonths(int months) {
    return '$months months ago';
  }

  @override
  String timeAgoYears(int years) {
    return '$years years ago';
  }

  @override
  String get fileBrowserTitle => 'Select File';

  @override
  String get fileBrowserSelect => 'Select';

  @override
  String get fileBrowserCancel => 'Cancel';

  @override
  String get fileBrowserNoItems => 'No items';

  @override
  String get fileBrowserParentDirectory => 'Parent Directory';

  @override
  String fileBrowserSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get errorGameNotFound => 'Game not found';

  @override
  String get errorLoadFailed => 'Failed to load game';

  @override
  String get errorLaunchFailed => 'Failed to launch game';

  @override
  String get errorStopFailed => 'Failed to stop game';

  @override
  String get errorDeleteFailed => 'Failed to delete game';

  @override
  String get errorUpdateFailed => 'Failed to update game';

  @override
  String get manualAddExecutableLabel => 'Executable File';

  @override
  String get manualAddBrowseButton => 'Browse...';

  @override
  String get manualAddNoFileSelected => 'No file selected';

  @override
  String get manualAddInvalidFileError => 'Invalid file';

  @override
  String get manualAddGameNameLabel => 'Game Name';

  @override
  String get manualAddGameNameHint => 'Enter game name';

  @override
  String get manualAddInvalidNameError => 'Invalid name';

  @override
  String get manualAddConfirmButton => 'Add Game';

  @override
  String get scanDirectoryAddDirectoryButton => 'Add Directory';

  @override
  String get scanDirectoryStartScanButton => 'Start Scan';

  @override
  String scanDirectoryFoundExecutables(int totalCount, int selectedCount) {
    return 'Found $totalCount executables ($selectedCount selected)';
  }

  @override
  String get scanDirectorySelectAllButton => 'Select All';

  @override
  String get scanDirectorySelectNoneButton => 'Select None';

  @override
  String scanDirectoryAddGamesButton(int count) {
    return 'Add $count Games';
  }

  @override
  String get scanDirectoryNoExecutablesTitle => 'No executables found';

  @override
  String get scanDirectoryNoExecutablesSubtitle =>
      'Try selecting a different directory or check that .exe files exist.';

  @override
  String get scanDirectorySelectDifferentDirectories =>
      'Select Different Directories';

  @override
  String get scanDirectoryAddingGames => 'Adding games...';

  @override
  String get steamGamesInitializing => 'Initializing...';

  @override
  String steamGamesDefaultPath(String path) {
    return 'Default: $path';
  }

  @override
  String get steamGamesBrowseSteamFolder => 'Browse for Steam Folder';

  @override
  String get steamGamesSteamPathLabel => 'Steam Path:';

  @override
  String get steamGamesSelectAllButton => 'Select All';

  @override
  String get steamGamesSelectNoneButton => 'Select None';

  @override
  String steamGamesFoundGames(int count, int alreadyAddedCount) {
    return 'Found $count games ($alreadyAddedCount already added)';
  }

  @override
  String get steamGamesNoGamesFound => 'No Steam games found';

  @override
  String steamGamesAppId(String appId) {
    return 'App ID: $appId';
  }

  @override
  String get steamGamesAlreadyAdded => 'Already Added';

  @override
  String get steamGamesRefreshMetadata => 'Refresh Metadata';

  @override
  String get steamGamesImporting => 'Importing games...';

  @override
  String steamGamesImportProgress(int completed, int total) {
    return '$completed of $total';
  }

  @override
  String get steamGamesImportComplete => 'Import Complete!';

  @override
  String steamGamesImportedCount(int count) {
    return '$count games imported';
  }

  @override
  String steamGamesSkippedCount(int count) {
    return '$count skipped';
  }

  @override
  String get steamGamesErrorsLabel => 'Errors:';

  @override
  String get steamGamesImportButton => 'Import Selected Games';

  @override
  String steamGamesImportCountButton(int count) {
    return 'Import $count Games';
  }

  @override
  String get gamepadNavOpen => 'Open';

  @override
  String get gamepadNavSelectCurrent => 'Select Current';

  @override
  String get steamScannerDetecting => 'Detecting Steam installation...';

  @override
  String get steamScannerNotFound =>
      'Steam installation not found. Please specify the path manually.';

  @override
  String steamScannerDetectError(String error) {
    return 'Error detecting Steam: $error';
  }

  @override
  String get steamScannerValidating => 'Validating Steam path...';

  @override
  String get steamScannerInvalidPath =>
      'Invalid Steam path. Please check the path and try again.';

  @override
  String steamScannerValidateError(String error) {
    return 'Error validating path: $error';
  }

  @override
  String get steamScannerNoPathSet =>
      'No Steam path set. Please detect or specify Steam path first.';

  @override
  String get steamScannerScanning => 'Scanning Steam libraries...';

  @override
  String steamScannerScanError(String error) {
    return 'Error scanning library: $error';
  }

  @override
  String steamScannerNoExecutable(String gameName) {
    return '$gameName: No executable found';
  }

  @override
  String steamScannerImportError(String gameName, String error) {
    return '$gameName: $error';
  }

  @override
  String errorAddGameFailed(String error) {
    return 'Failed to add game: $error';
  }

  @override
  String errorAddGamesFailed(String error) {
    return 'Failed to add games: $error';
  }

  @override
  String errorScanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String errorLoadSettingsFailed(String error) {
    return 'Failed to load settings: $error';
  }

  @override
  String errorFetchMetadataFailed(String error) {
    return 'Failed to fetch metadata: $error';
  }

  @override
  String errorSearchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String errorUpdateMetadataFailed(String error) {
    return 'Failed to update metadata: $error';
  }

  @override
  String errorClearMetadataFailed(String error) {
    return 'Failed to clear metadata: $error';
  }

  @override
  String get gamepadTestButton => 'BUTTON';

  @override
  String get gamepadTestAxis => 'AXIS';

  @override
  String get gamepadTestConnect => 'CONNECT';

  @override
  String get gamepadTestDisconnect => 'DISCONNECT';

  @override
  String get gamepadTestPressed => 'pressed';

  @override
  String get gamepadTestReleased => 'released';

  @override
  String gamepadTestGamepadConnected(String name) {
    return 'Gamepad connected: $name';
  }

  @override
  String get gamepadTestUnknown => 'Unknown';

  @override
  String get gamepadTestGamepadDisconnected => 'Gamepad disconnected';

  @override
  String get settingsDisplay => 'Display';

  @override
  String get settingsFullscreen => 'Fullscreen';

  @override
  String get settingsFullscreenHint => 'Toggle fullscreen mode';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsLock => 'Lock';

  @override
  String get settingsSleep => 'Sleep';

  @override
  String get settingsReboot => 'Reboot';

  @override
  String get settingsShutdown => 'Shutdown';

  @override
  String get settingsSystemVolume => 'System Volume';

  @override
  String get settingsSystemMute => 'Mute';

  @override
  String get settingsSystemVolumeHint =>
      'System volume slider - use left and right to adjust';

  @override
  String get settingsSystemMuteHint =>
      'Mute toggle - press to toggle system mute on or off';

  @override
  String get settingsAboutDevice => 'About This Device';

  @override
  String get systemInfoTitle => 'About This Device';
}
